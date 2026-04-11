#!/usr/bin/env python3
"""
Match persons in caltech_curation to institutions from 3 sources:
  1. ROR (Research Organization Registry)
  2. OpenAlex
  3. Wikidata

For each source, runs two independent methods:
  Method A: Match two_institution field against org names
  Method B: Match two_street/city/state/post/country against org names

Writes per-source output to ror/, openalex/, wikidata/ subdirs,
plus a combined_summary.txt comparing all 3.

Requires: Python 3.7+, psql on PATH, network access.
"""

import csv
import difflib
import json
import os
import re
import ssl
import subprocess
import sys
import time
import urllib.request
import zipfile
from collections import defaultdict

# ============================================================
# Configuration
# ============================================================

WORK_DIR = '/usr/caltech_curation_files/claudecode/20260410_person_address_institution'
FUZZY_THRESHOLD = 0.85
TOP_N = 3

COUNTRY_ALIASES = {
    'united states of america': 'united states',
    'usa': 'united states',
    'u.s.a.': 'united states',
    'uk': 'united kingdom',
    'england': 'united kingdom',
    'scotland': 'united kingdom',
    'wales': 'united kingdom',
    'northern ireland': 'united kingdom',
    'south korea': 'korea, republic of',
    'republic of korea': 'korea, republic of',
    'czech republic': 'czechia',
    'russia': 'russian federation',
    'iran': 'iran, islamic republic of',
    'taiwan': 'taiwan, province of china',
    'republic of china': 'taiwan, province of china',
    'vietnam': 'viet nam',
    'the netherlands': 'netherlands',
    'holland': 'netherlands',
    'ivory coast': "cote d'ivoire",
}

# Populated by all source parsers: set of lowercase country names
_known_countries = set()
# Cache: input country string -> normalized country string
_country_cache = {}

# SSL context for older Python/container environments
_ssl_ctx = ssl.create_default_context()
_ssl_ctx.check_hostname = False
_ssl_ctx.verify_mode = ssl.CERT_NONE


def _url_fetch(url, headers=None):
    """Fetch a URL, return bytes. Handles SSL and wget fallback."""
    hdrs = headers or {}
    try:
        req = urllib.request.Request(url, headers=hdrs)
        with urllib.request.urlopen(req, timeout=120, context=_ssl_ctx) as resp:
            return resp.read()
    except Exception as e:
        print("    urllib failed ({}), trying wget...".format(e), flush=True)
        tmp = os.path.join(WORK_DIR, '_tmp_fetch')
        subprocess.run(['wget', '-q', '-O', tmp, url], check=True)
        with open(tmp, 'rb') as f:
            return f.read()


# ============================================================
# Database helpers
# ============================================================

def run_query(sql):
    """Run SQL via psql COPY CSV format to handle embedded tabs/commas."""
    import io
    env = dict(os.environ)
    env['PGPASSWORD'] = 'postgres'
    copy_sql = "COPY ({}) TO STDOUT WITH (FORMAT csv)".format(sql)
    cmd = [
        'psql', '-h', 'curation_db', '-U', 'postgres',
        '-d', 'caltech_curation', '-c', copy_sql
    ]
    result = subprocess.run(cmd, capture_output=True, text=True, env=env)
    if result.returncode != 0:
        print("SQL ERROR: {}".format(result.stderr), file=sys.stderr)
        return []
    rows = []
    reader = csv.reader(io.StringIO(result.stdout))
    for row in reader:
        if row:
            rows.append(row)
    return rows


def load_institutions():
    print("Loading institutions from DB...")
    rows = run_query(
        "SELECT two_institution, COUNT(DISTINCT joinkey) "
        "FROM two_institution GROUP BY two_institution"
    )
    result = [(r[0], int(r[1])) for r in rows if len(r) >= 2]
    print("  {} distinct institutions".format(len(result)))
    return result


def load_person_institutions():
    print("Loading person -> institution mapping...")
    rows = run_query(
        "SELECT DISTINCT ON (joinkey) joinkey, two_institution "
        "FROM two_institution ORDER BY joinkey, two_order DESC"
    )
    result = {r[0]: r[1] for r in rows if len(r) >= 2}
    print("  {} persons".format(len(result)))
    return result


def load_addresses():
    print("Loading addresses from DB...")
    addresses = defaultdict(lambda: {
        'street_lines': [], 'city': '', 'state': '', 'post': '', 'country': ''
    })
    print("  Street lines...")
    for r in run_query("SELECT joinkey, two_order, two_street FROM two_street ORDER BY joinkey, two_order"):
        if len(r) >= 3:
            addresses[r[0]]['street_lines'].append((int(r[1]), r[2]))
    print("  Cities...")
    for r in run_query("SELECT DISTINCT ON (joinkey) joinkey, two_city FROM two_city ORDER BY joinkey, two_order DESC"):
        if len(r) >= 2:
            addresses[r[0]]['city'] = r[1]
    print("  States...")
    for r in run_query("SELECT DISTINCT ON (joinkey) joinkey, two_state FROM two_state ORDER BY joinkey, two_order DESC"):
        if len(r) >= 2:
            addresses[r[0]]['state'] = r[1]
    print("  Postal codes...")
    for r in run_query("SELECT DISTINCT ON (joinkey) joinkey, two_post FROM two_post ORDER BY joinkey, two_order DESC"):
        if len(r) >= 2:
            addresses[r[0]]['post'] = r[1]
    print("  Countries...")
    for r in run_query("SELECT DISTINCT ON (joinkey) joinkey, two_country FROM two_country ORDER BY joinkey, two_order DESC"):
        if len(r) >= 2:
            addresses[r[0]]['country'] = r[1]
    print("  {} persons with address data".format(len(addresses)))
    return dict(addresses)


# ============================================================
# Source: ROR
# ============================================================

def download_ror():
    ror_json = os.path.join(WORK_DIR, 'ror_data.json')
    if os.path.exists(ror_json):
        print("ROR data already cached, skipping download.")
        return ror_json
    print("Fetching latest ROR record from Zenodo...")
    data = json.loads(_url_fetch(
        'https://zenodo.org/api/records/?communities=ror-data&sort=mostrecent&size=1',
        {'Accept': 'application/json'}
    ))
    hits = data.get('hits', {}).get('hits', [])
    if not hits:
        sys.exit("ERROR: No ROR records on Zenodo")
    record = hits[0]
    print("  Record: {}".format(record.get('metadata', {}).get('title', '?')))
    zip_info = next((f for f in record.get('files', []) if f['key'].endswith('.zip')), None)
    if not zip_info:
        sys.exit("ERROR: No zip in ROR record")
    zip_path = os.path.join(WORK_DIR, 'ror_data.zip')
    print("  Downloading {:.1f} MB...".format(zip_info.get('size', 0) / 1e6), flush=True)
    with open(zip_path, 'wb') as f:
        f.write(_url_fetch(zip_info['links']['self']))
    print("  Extracting...")
    with zipfile.ZipFile(zip_path) as z:
        jf = sorted([n for n in z.namelist() if n.endswith('.json') and not n.startswith('__')],
                     key=lambda n: z.getinfo(n).file_size, reverse=True)[0]
        with z.open(jf) as src, open(ror_json, 'wb') as dst:
            dst.write(src.read())
    print("  Saved to {}".format(ror_json))
    return ror_json


def parse_ror(path):
    global _known_countries
    print("Parsing ROR data...")
    with open(path) as f:
        records = json.load(f)
    is_v2 = 'names' in (records[0] if records else {})
    orgs = []
    for rec in records:
        ror_id = rec.get('id', '')
        if is_v2:
            names = []
            primary = ''
            for n in rec.get('names', []):
                v = n.get('value', '')
                if v:
                    names.append(v)
                    if 'ror_display' in n.get('types', []):
                        primary = v
            if not primary and names:
                primary = names[0]
            locs = rec.get('locations', [])
            city = locs[0].get('geonames_details', {}).get('name', '') if locs else ''
            country = locs[0].get('geonames_details', {}).get('country_name', '') if locs else ''
        else:
            primary = rec.get('name', '')
            names = [primary] + rec.get('aliases', [])
            for lbl in rec.get('labels', []):
                if lbl.get('label'):
                    names.append(lbl['label'])
            addrs = rec.get('addresses', [])
            city = addrs[0].get('city', '') if addrs else ''
            country = rec.get('country', {}).get('country_name', '')
        all_lower = list(set(n.lower().strip() for n in names if n.strip()))
        c_low = country.lower().strip()
        _known_countries.add(c_low)
        orgs.append({
            'org_id': ror_id, 'name': primary, 'all_names_lower': all_lower,
            'city': city, 'city_lower': city.lower().strip(),
            'country': country, 'country_lower': c_low,
        })
    print("  {} organizations".format(len(orgs)))
    return orgs


# ============================================================
# Source: OpenAlex
# ============================================================

def download_openalex():
    cache = os.path.join(WORK_DIR, 'openalex_data.json')
    if os.path.exists(cache):
        print("OpenAlex data already cached, skipping download.")
        return cache
    print("Downloading OpenAlex institutions (paginated API)...", flush=True)
    all_results = []
    cursor = '*'
    page = 0
    while True:
        page += 1
        url = ('https://api.openalex.org/institutions'
               '?per_page=200&cursor={}'
               '&select=id,display_name,alternate_names,country_code,geo'
               '&mailto=curation@caltech.edu').format(cursor)
        try:
            data = json.loads(_url_fetch(url, {'Accept': 'application/json'}))
        except Exception as e:
            print("  OpenAlex API error at page {}: {}".format(page, e))
            break
        results = data.get('results', [])
        if not results:
            break
        all_results.extend(results)
        cursor = data.get('meta', {}).get('next_cursor')
        if not cursor:
            break
        if page % 50 == 0:
            print("  Page {} — {} institutions so far...".format(page, len(all_results)), flush=True)
    print("  Downloaded {} institutions in {} pages".format(len(all_results), page))
    with open(cache, 'w') as f:
        json.dump(all_results, f)
    return cache


def parse_openalex(path):
    global _known_countries
    print("Parsing OpenAlex data...")
    with open(path) as f:
        records = json.load(f)
    orgs = []
    for rec in records:
        oa_id = rec.get('id', '')
        primary = rec.get('display_name', '')
        names = [primary] + (rec.get('alternate_names') or [])
        geo = rec.get('geo') or {}
        city = geo.get('city', '') or ''
        country = geo.get('country', '') or ''
        all_lower = list(set(n.lower().strip() for n in names if n and n.strip()))
        c_low = country.lower().strip()
        if c_low:
            _known_countries.add(c_low)
        orgs.append({
            'org_id': oa_id, 'name': primary, 'all_names_lower': all_lower,
            'city': city, 'city_lower': city.lower().strip(),
            'country': country, 'country_lower': c_low,
        })
    print("  {} organizations".format(len(orgs)))
    return orgs


# ============================================================
# Source: Wikidata
# ============================================================

WIKIDATA_TYPES = [
    ('Q3918', 'university'),
    ('Q875538', 'public university'),
    ('Q902104', 'private university'),
    ('Q1664720', 'institute of technology'),
    ('Q15936437', 'research university'),
    ('Q38723', 'higher education institution'),
    ('Q31855', 'research institute'),
    ('Q7315155', 'research center'),
    ('Q16917', 'hospital'),
    ('Q2467461', 'medical school'),
    ('Q1391145', 'government agency'),
    ('Q4830453', 'business enterprise'),
    ('Q43229', 'organization'),
]


def download_wikidata():
    cache = os.path.join(WORK_DIR, 'wikidata_data.json')
    if os.path.exists(cache):
        print("Wikidata data already cached, skipping download.")
        return cache
    print("Downloading Wikidata organizations via SPARQL...", flush=True)
    endpoint = 'https://query.wikidata.org/sparql'
    all_orgs = {}  # keyed by item URI to deduplicate
    for qid, label in WIKIDATA_TYPES:
        sparql = """
SELECT ?item ?itemLabel ?countryLabel WHERE {{
  ?item wdt:P31 wd:{qid} .
  OPTIONAL {{ ?item wdt:P17 ?country . }}
  SERVICE wikibase:label {{ bd:serviceParam wikibase:language "en" . }}
}}
LIMIT 100000""".format(qid=qid)
        url = '{}?query={}&format=json'.format(
            endpoint, urllib.request.quote(sparql))
        print("  Querying {} ({})...".format(label, qid), flush=True)
        try:
            data = json.loads(_url_fetch(url, {
                'Accept': 'application/sparql-results+json',
                'User-Agent': 'CaltechCurationBot/1.0 (curation@caltech.edu)'
            }))
        except Exception as e:
            print("    FAILED: {}".format(e))
            continue
        bindings = data.get('results', {}).get('bindings', [])
        for b in bindings:
            uri = b.get('item', {}).get('value', '')
            if uri and uri not in all_orgs:
                all_orgs[uri] = {
                    'id': uri,
                    'name': b.get('itemLabel', {}).get('value', ''),
                    'country': b.get('countryLabel', {}).get('value', ''),
                }
        print("    {} results, {} unique orgs total".format(len(bindings), len(all_orgs)),
              flush=True)
        time.sleep(2)  # Be polite to Wikidata
    print("  Total: {} unique Wikidata organizations".format(len(all_orgs)))
    with open(cache, 'w') as f:
        json.dump(list(all_orgs.values()), f)
    return cache


def parse_wikidata(path):
    global _known_countries
    print("Parsing Wikidata data...")
    with open(path) as f:
        records = json.load(f)
    orgs = []
    for rec in records:
        wd_id = rec.get('id', '')
        primary = rec.get('name', '')
        if not primary or primary == wd_id:
            continue  # Skip items without English labels
        country = rec.get('country', '') or ''
        all_lower = [primary.lower().strip()] if primary.strip() else []
        c_low = country.lower().strip()
        if c_low:
            _known_countries.add(c_low)
        orgs.append({
            'org_id': wd_id, 'name': primary, 'all_names_lower': all_lower,
            'city': '', 'city_lower': '',  # Wikidata query doesn't fetch city
            'country': country, 'country_lower': c_low,
        })
    print("  {} organizations".format(len(orgs)))
    return orgs


# ============================================================
# Indices
# ============================================================

def build_name_index(orgs):
    idx = defaultdict(list)
    for i, o in enumerate(orgs):
        for n in o['all_names_lower']:
            idx[n].append(i)
    return dict(idx)

def build_country_index(orgs):
    idx = defaultdict(list)
    for i, o in enumerate(orgs):
        if o['country_lower']:
            idx[o['country_lower']].append(i)
    return dict(idx)

def build_city_country_index(orgs):
    idx = defaultdict(list)
    for i, o in enumerate(orgs):
        if o['city_lower'] and o['country_lower']:
            idx[(o['city_lower'], o['country_lower'])].append(i)
    return dict(idx)

_STOP_WORDS = frozenset([
    'of', 'the', 'and', 'for', 'de', 'du', 'des', 'la', 'le', 'les', 'di',
    'del', 'da', 'das', 'dos', 'den', 'der', 'die', 'van', 'von', 'und',
    'e', 'y', 'a', 'in', 'en', 'et', 'al', 'el', 'i',
])

def _tokenize(name):
    return set(w for w in re.findall(r'[a-z]{3,}', name.lower()) if w not in _STOP_WORDS)

def build_word_country_index(orgs):
    idx = defaultdict(set)
    for i, o in enumerate(orgs):
        c = o['country_lower']
        for name in o['all_names_lower']:
            for w in _tokenize(name):
                idx[(w, c)].add(i)
    return dict(idx)

def get_word_filtered_candidates(query_name, country_norm, word_country_idx, country_index):
    words = _tokenize(query_name)
    if not words:
        return []
    word_sets = []
    for w in words:
        key = (w, country_norm)
        if key in word_country_idx:
            word_sets.append((w, word_country_idx[key]))
    if not word_sets:
        return []
    word_sets.sort(key=lambda x: len(x[1]))
    if len(word_sets) >= 2:
        candidates = word_sets[0][1] & word_sets[1][1]
        if not candidates:
            candidates = word_sets[0][1] | word_sets[1][1]
    else:
        candidates = word_sets[0][1]
    if len(candidates) > 500:
        for _, s in word_sets[2:]:
            candidates = candidates & s
            if len(candidates) <= 500:
                break
        if len(candidates) > 500:
            candidates = set(list(candidates)[:500])
    return list(candidates)


# ============================================================
# Matching utilities
# ============================================================

def normalize_country(name):
    if not name:
        return ''
    c = name.strip().lower()
    if c in _country_cache:
        return _country_cache[c]
    if c in COUNTRY_ALIASES:
        result = COUNTRY_ALIASES[c]
        _country_cache[c] = result
        return result
    if c in _known_countries:
        _country_cache[c] = c
        return c
    best_score = 0.0
    best = c
    for rc in _known_countries:
        s = difflib.SequenceMatcher(None, c, rc).ratio()
        if s > best_score:
            best_score = s
            best = rc
    if best_score >= 0.85:
        _country_cache[c] = best
        return best
    _country_cache[c] = c
    return c


def parse_two_institution(value):
    if ';' in value:
        parts = value.split(';', 1)
        name = parts[0].strip()
        location = parts[1].strip()
    elif ',' in value:
        segments = [p.strip() for p in value.split(',')]
        if len(segments) >= 3:
            name = ', '.join(segments[:-2])
            city_state = segments[-2]
            country = segments[-1]
            m = re.match(r'^(.+?)\s+([A-Z]{2})$', city_state)
            if m:
                return (name, m.group(1), m.group(2), country)
            return (name, city_state, '', country)
        return (value, '', '', '')
    else:
        return (value, '', '', '')
    if ',' in location:
        loc_parts = [p.strip() for p in location.rsplit(',', 1)]
        city_state = loc_parts[0]
        country = loc_parts[1] if len(loc_parts) > 1 else ''
    else:
        city_state = location
        country = ''
    m = re.match(r'^(.+?)\s+([A-Z]{2})$', city_state)
    if m:
        return (name, m.group(1), m.group(2), country)
    return (name, city_state, '', country)


def fuzzy_match_name(query, candidate_indices, orgs, threshold=FUZZY_THRESHOLD, top_n=TOP_N):
    q = query.lower().strip()
    if not q:
        return []
    q_len = len(q)
    results = []
    for idx in candidate_indices:
        best = 0.0
        for oname in orgs[idx]['all_names_lower']:
            o_len = len(oname)
            if o_len == 0:
                continue
            ratio = q_len / o_len
            if ratio < 0.4 or ratio > 2.5:
                continue
            sm = difflib.SequenceMatcher(None, q, oname)
            if sm.real_quick_ratio() < threshold:
                continue
            if sm.quick_ratio() < threshold:
                continue
            s = sm.ratio()
            if s > best:
                best = s
        if best >= threshold:
            results.append((idx, best))
    results.sort(key=lambda x: -x[1])
    return results[:top_n]


# ============================================================
# Method A: Institution name matching
# ============================================================

def run_method_a(institutions, orgs, name_index, country_index, word_country_idx, out_dir, source):
    print("\n" + "=" * 60)
    print("[{}] METHOD A: Institution Name Matching".format(source))
    print("=" * 60)
    t0 = time.time()
    exact = []
    fuzzy = []
    nomatch = []
    mapping = {}
    total = len(institutions)
    for i, (two_inst, pcount) in enumerate(institutions):
        if (i + 1) % 2000 == 0 or i + 1 == total:
            print("  {}/{} ({:.0f}s)".format(i + 1, total, time.time() - t0), flush=True)
        name, city, state, country = parse_two_institution(two_inst)
        name_lower = name.lower().strip()
        country_norm = normalize_country(country)
        if name_lower in name_index:
            candidates = name_index[name_lower]
            best = candidates[0]
            if country_norm:
                for idx in candidates:
                    if orgs[idx]['country_lower'] == country_norm:
                        best = idx
                        break
            exact.append((two_inst, best, pcount))
            mapping[two_inst] = ('exact', [(best, 1.0)])
            continue
        if country_norm:
            cands = get_word_filtered_candidates(name, country_norm, word_country_idx, country_index)
        else:
            cands = []
        matches = fuzzy_match_name(name, cands, orgs)
        if matches:
            fuzzy.append((two_inst, matches, pcount))
            mapping[two_inst] = ('fuzzy', matches)
        else:
            nomatch.append((two_inst, pcount))
            mapping[two_inst] = ('none', [])

    # Write files
    id_col = '{}_id'.format(source)
    name_col = '{}_name'.format(source)
    p = os.path.join(out_dir, 'institution_match_exact.tsv')
    with open(p, 'w', newline='') as f:
        w = csv.writer(f, delimiter='\t')
        w.writerow(['two_institution', id_col, name_col, 'person_count'])
        for inst, idx, pc in sorted(exact, key=lambda x: -x[2]):
            o = orgs[idx]
            w.writerow([inst, o['org_id'], o['name'], pc])
    p = os.path.join(out_dir, 'institution_match_fuzzy.tsv')
    with open(p, 'w', newline='') as f:
        w = csv.writer(f, delimiter='\t')
        hdr = ['two_institution']
        for n in range(1, TOP_N + 1):
            hdr += ['{}_id_{}'.format(source, n), '{}_name_{}'.format(source, n), 'score_{}'.format(n)]
        hdr.append('person_count')
        w.writerow(hdr)
        for inst, matches, pc in sorted(fuzzy, key=lambda x: -x[2]):
            row = [inst]
            for idx, sc in matches:
                row += [orgs[idx]['org_id'], orgs[idx]['name'], '{:.4f}'.format(sc)]
            while len(row) < 1 + TOP_N * 3:
                row.append('')
            row.append(pc)
            w.writerow(row)
    p = os.path.join(out_dir, 'institution_no_match.tsv')
    with open(p, 'w', newline='') as f:
        w = csv.writer(f, delimiter='\t')
        w.writerow(['two_institution', 'person_count'])
        for inst, pc in sorted(nomatch, key=lambda x: -x[1]):
            w.writerow([inst, pc])

    ex_p = sum(pc for _, _, pc in exact)
    fz_p = sum(pc for _, _, pc in fuzzy)
    nm_p = sum(pc for _, pc in nomatch)
    elapsed = time.time() - t0
    print("\n  [{}] Method A done in {:.0f}s".format(source, elapsed))
    print("  Exact:    {:>6} institutions  {:>6} persons".format(len(exact), ex_p))
    print("  Fuzzy:    {:>6} institutions  {:>6} persons".format(len(fuzzy), fz_p))
    print("  No match: {:>6} institutions  {:>6} persons".format(len(nomatch), nm_p))
    stats = {'exact_inst': len(exact), 'exact_pers': ex_p,
             'fuzzy_inst': len(fuzzy), 'fuzzy_pers': fz_p,
             'nomatch_inst': len(nomatch), 'nomatch_pers': nm_p}
    return mapping, stats


# ============================================================
# Method B: Address field matching
# ============================================================

def run_method_b(addresses, orgs, name_index, city_country_index, country_index, out_dir, source):
    print("\n" + "=" * 60)
    print("[{}] METHOD B: Address Field Matching".format(source))
    print("=" * 60)
    t0 = time.time()
    exact = []
    fuzzy = []
    nomatch = []
    mapping = {}
    keys = sorted(addresses.keys())
    total = len(keys)
    for i, jk in enumerate(keys):
        if (i + 1) % 10000 == 0 or i + 1 == total:
            print("  {}/{} ({:.0f}s)".format(i + 1, total, time.time() - t0), flush=True)
        addr = addresses[jk]
        lines = [ln for _, ln in sorted(addr['street_lines'])]
        city = addr['city']
        state = addr['state']
        post = addr['post']
        country = addr['country']
        country_norm = normalize_country(country)
        city_lower = city.lower().strip()
        found = False
        for ln in lines:
            ln_lower = ln.lower().strip()
            if ln_lower in name_index:
                candidates = name_index[ln_lower]
                best = candidates[0]
                for idx in candidates:
                    o = orgs[idx]
                    if o['city_lower'] == city_lower and o['country_lower'] == country_norm:
                        best = idx
                        break
                else:
                    for idx in candidates:
                        if orgs[idx]['country_lower'] == country_norm:
                            best = idx
                            break
                exact.append((jk, best, ln, city, country))
                mapping[jk] = ('exact', [(best, 1.0)], ln)
                found = True
                break
        if found:
            continue
        cands = []
        if city_lower and country_norm:
            cands = city_country_index.get((city_lower, country_norm), [])
        if not cands:
            nomatch.append((jk, ' | '.join(lines), city, state, post, country))
            mapping[jk] = ('none', [], '')
            continue
        best_matches = []
        best_line = ''
        for ln in lines:
            m = fuzzy_match_name(ln, cands, orgs)
            if m and (not best_matches or m[0][1] > best_matches[0][1]):
                best_matches = m
                best_line = ln
        if best_matches:
            fuzzy.append((jk, best_matches, best_line, city, country))
            mapping[jk] = ('fuzzy', best_matches, best_line)
        else:
            nomatch.append((jk, ' | '.join(lines), city, state, post, country))
            mapping[jk] = ('none', [], '')

    # Write files
    id_col = '{}_id'.format(source)
    name_col = '{}_name'.format(source)
    p = os.path.join(out_dir, 'address_match_exact.tsv')
    with open(p, 'w', newline='') as f:
        w = csv.writer(f, delimiter='\t')
        w.writerow(['joinkey', id_col, name_col, 'matched_street_line', 'city', 'country'])
        for jk, idx, ln, ci, co in exact:
            w.writerow([jk, orgs[idx]['org_id'], orgs[idx]['name'], ln, ci, co])
    p = os.path.join(out_dir, 'address_match_fuzzy.tsv')
    with open(p, 'w', newline='') as f:
        w = csv.writer(f, delimiter='\t')
        hdr = ['joinkey']
        for n in range(1, TOP_N + 1):
            hdr += ['{}_id_{}'.format(source, n), '{}_name_{}'.format(source, n), 'score_{}'.format(n)]
        hdr += ['matched_street_line', 'city', 'country']
        w.writerow(hdr)
        for jk, matches, ln, ci, co in fuzzy:
            row = [jk]
            for idx, sc in matches:
                row += [orgs[idx]['org_id'], orgs[idx]['name'], '{:.4f}'.format(sc)]
            while len(row) < 1 + TOP_N * 3:
                row.append('')
            row += [ln, ci, co]
            w.writerow(row)
    p = os.path.join(out_dir, 'address_no_match.tsv')
    with open(p, 'w', newline='') as f:
        w = csv.writer(f, delimiter='\t')
        w.writerow(['joinkey', 'street_lines', 'city', 'state', 'post', 'country'])
        for row_data in nomatch:
            w.writerow(row_data)

    elapsed = time.time() - t0
    print("\n  [{}] Method B done in {:.0f}s".format(source, elapsed))
    print("  Exact:    {:>6} persons".format(len(exact)))
    print("  Fuzzy:    {:>6} persons".format(len(fuzzy)))
    print("  No match: {:>6} persons".format(len(nomatch)))
    stats = {'exact_pers': len(exact), 'fuzzy_pers': len(fuzzy), 'nomatch_pers': len(nomatch)}
    return mapping, stats


# ============================================================
# Run one source end-to-end
# ============================================================

def run_source(source_name, orgs, institutions, person_insts, addresses):
    """Run full matching pipeline for one source.
    Returns (inst_mapping, addr_mapping, method_a_stats, method_b_stats)
    """
    out_dir = os.path.join(WORK_DIR, source_name)
    os.makedirs(out_dir, exist_ok=True)

    print("\n\n" + "#" * 60)
    print("# SOURCE: {}  ({} orgs)".format(source_name.upper(), len(orgs)))
    print("#" * 60)

    print("\n  Building indices...", flush=True)
    ni = build_name_index(orgs)
    ci = build_country_index(orgs)
    cci = build_city_country_index(orgs)
    wci = build_word_country_index(orgs)
    print("  Name: {}  Country: {}  City+Country: {}  Word+Country: {}".format(
        len(ni), len(ci), len(cci), len(wci)))

    inst_map, a_stats = run_method_a(institutions, orgs, ni, ci, wci, out_dir, source_name)
    addr_map, b_stats = run_method_b(addresses, orgs, ni, cci, ci, out_dir, source_name)

    return inst_map, addr_map, a_stats, b_stats


# ============================================================
# Combined summary
# ============================================================

def write_combined_summary(all_results, person_insts, addresses):
    """Write combined_summary.txt comparing all sources."""
    print("\n\n" + "#" * 60)
    print("# COMBINED SUMMARY")
    print("#" * 60)

    all_jk = sorted(set(person_insts.keys()) | set(addresses.keys()))
    total_persons = len(all_jk)

    lines = [
        "=== Combined Institution Matching Summary ===",
        "Generated: {}".format(time.strftime('%Y-%m-%d %H:%M:%S')),
        "Total persons: {}".format(total_persons),
        "",
    ]

    # Per-source Method A stats
    lines.append("--- Method A: Institution Name Matching ---")
    lines.append("{:<12} {:>10} {:>10} {:>10} {:>10} {:>10} {:>10}".format(
        'Source', 'ExactInst', 'ExactPers', 'FuzzyInst', 'FuzzyPers', 'NoInst', 'NoPers'))
    for src, (_, _, a_stats, _) in sorted(all_results.items()):
        lines.append("{:<12} {:>10} {:>10} {:>10} {:>10} {:>10} {:>10}".format(
            src,
            a_stats['exact_inst'], a_stats['exact_pers'],
            a_stats['fuzzy_inst'], a_stats['fuzzy_pers'],
            a_stats['nomatch_inst'], a_stats['nomatch_pers']))

    # Per-source Method B stats
    lines.append("")
    lines.append("--- Method B: Address Field Matching ---")
    lines.append("{:<12} {:>10} {:>10} {:>10}".format(
        'Source', 'Exact', 'Fuzzy', 'NoMatch'))
    for src, (_, _, _, b_stats) in sorted(all_results.items()):
        lines.append("{:<12} {:>10} {:>10} {:>10}".format(
            src, b_stats['exact_pers'], b_stats['fuzzy_pers'], b_stats['nomatch_pers']))

    # Per-person cross-source analysis using Method A (institution mapping)
    lines.append("")
    lines.append("--- Per-Person Coverage (Method A, via institution) ---")

    source_names = sorted(all_results.keys())
    # For each person, check if their institution matched (exact or fuzzy) in each source
    person_matched = {src: set() for src in source_names}
    for src, (inst_map, _, _, _) in all_results.items():
        for jk, inst in person_insts.items():
            if inst in inst_map:
                mtype, cands = inst_map[inst]
                if mtype in ('exact', 'fuzzy') and cands:
                    person_matched[src].add(jk)

    # Also add Method B matches
    person_matched_ab = {src: set(person_matched[src]) for src in source_names}
    for src, (_, addr_map, _, _) in all_results.items():
        for jk, val in addr_map.items():
            mtype = val[0]
            cands = val[1]
            if mtype in ('exact', 'fuzzy') and cands:
                person_matched_ab[src].add(jk)

    for src in source_names:
        lines.append("  {} matched (A+B): {:>6} ({:.1f}%)".format(
            src, len(person_matched_ab[src]),
            100 * len(person_matched_ab[src]) / max(total_persons, 1)))

    # Union
    union_matched = set()
    for src in source_names:
        union_matched |= person_matched_ab[src]
    lines.append("  ANY source:       {:>6} ({:.1f}%)".format(
        len(union_matched), 100 * len(union_matched) / max(total_persons, 1)))
    lines.append("  NO source:        {:>6} ({:.1f}%)".format(
        total_persons - len(union_matched),
        100 * (total_persons - len(union_matched)) / max(total_persons, 1)))

    # Venn-style breakdown (which sources matched)
    lines.append("")
    lines.append("--- Venn Breakdown (A+B combined) ---")
    from itertools import combinations
    combos = defaultdict(int)
    for jk in all_jk:
        key = tuple(src for src in source_names if jk in person_matched_ab[src])
        if not key:
            key = ('none',)
        combos[key] += 1
    for key in sorted(combos.keys(), key=lambda k: -combos[k]):
        label = ' + '.join(key) if key != ('none',) else 'NO MATCH'
        lines.append("  {:<40} {:>6} ({:.1f}%)".format(
            label, combos[key], 100 * combos[key] / max(total_persons, 1)))

    # ROR-unmatched rescued by other sources
    if 'ror' in all_results and len(source_names) > 1:
        lines.append("")
        lines.append("--- ROR-Unmatched Institutions Rescued ---")
        ror_inst_map = all_results['ror'][0]
        ror_nomatch_insts = set(
            inst for inst, (mtype, _) in ror_inst_map.items() if mtype == 'none')
        for src in source_names:
            if src == 'ror':
                continue
            other_inst_map = all_results[src][0]
            rescued = 0
            for inst in ror_nomatch_insts:
                if inst in other_inst_map:
                    mtype, cands = other_inst_map[inst]
                    if mtype in ('exact', 'fuzzy') and cands:
                        rescued += 1
            lines.append("  {} rescued {:>5} of {} ROR-unmatched institutions".format(
                src, rescued, len(ror_nomatch_insts)))

    p = os.path.join(WORK_DIR, 'combined_summary.txt')
    with open(p, 'w') as f:
        f.write('\n'.join(lines) + '\n')

    print("\n  COMBINED SUMMARY:")
    for ln in lines:
        print("  " + ln)


# ============================================================
# Main
# ============================================================

def main():
    print("=" * 60)
    print("Person-Institution Multi-Source Matching")
    print("=" * 60)
    t_start = time.time()
    os.makedirs(WORK_DIR, exist_ok=True)

    # Download all sources
    ror_path = download_ror()
    openalex_path = download_openalex()
    wikidata_path = download_wikidata()

    # Parse all sources
    ror_orgs = parse_ror(ror_path)
    openalex_orgs = parse_openalex(openalex_path)
    wikidata_orgs = parse_wikidata(wikidata_path)

    # Load DB data (once)
    institutions = load_institutions()
    person_insts = load_person_institutions()
    addresses = load_addresses()

    # Run matching for each source
    all_results = {}
    for source_name, orgs in [('ror', ror_orgs), ('openalex', openalex_orgs), ('wikidata', wikidata_orgs)]:
        inst_map, addr_map, a_stats, b_stats = run_source(
            source_name, orgs, institutions, person_insts, addresses)
        all_results[source_name] = (inst_map, addr_map, a_stats, b_stats)

    # Combined summary
    write_combined_summary(all_results, person_insts, addresses)

    elapsed = time.time() - t_start
    print("\n" + "=" * 60)
    print("ALL DONE in {:.0f}m {:.0f}s".format(elapsed // 60, elapsed % 60))
    print("Output: {}".format(WORK_DIR))
    print("=" * 60)


if __name__ == '__main__':
    main()
