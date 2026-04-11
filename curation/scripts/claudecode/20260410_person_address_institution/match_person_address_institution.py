#!/usr/bin/env python3
"""
Match persons in caltech_curation to ROR institutions via two independent methods:
  Method A: Match two_institution field against ROR org names
  Method B: Match two_street/city/state/post/country against ROR org names
Cross-compare results at the end.

Output files written to WORK_DIR (8 TSV/TXT files).
Requires: Python 3.7+, psql on PATH, network access for ROR download.
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

# Populated after ROR load: set of lowercase ROR country names
_ror_countries = set()
# Cache: input country string -> normalized ROR country string
_country_cache = {}


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
    """Return list of (two_institution, person_count)."""
    print("Loading institutions from DB...")
    rows = run_query(
        "SELECT two_institution, COUNT(DISTINCT joinkey) "
        "FROM two_institution GROUP BY two_institution"
    )
    result = [(r[0], int(r[1])) for r in rows if len(r) >= 2]
    print("  {} distinct institutions".format(len(result)))
    return result


def load_person_institutions():
    """Return dict joinkey -> two_institution (latest per person)."""
    print("Loading person -> institution mapping...")
    rows = run_query(
        "SELECT DISTINCT ON (joinkey) joinkey, two_institution "
        "FROM two_institution ORDER BY joinkey, two_order DESC"
    )
    result = {r[0]: r[1] for r in rows if len(r) >= 2}
    print("  {} persons".format(len(result)))
    return result


def load_addresses():
    """Return dict joinkey -> {street_lines, city, state, post, country}."""
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
# ROR download and parse
# ============================================================

def download_ror():
    """Download latest ROR data dump from Zenodo. Return path to JSON."""
    ror_json = os.path.join(WORK_DIR, 'ror_data.json')
    if os.path.exists(ror_json):
        print("ROR data already at {}, skipping download.".format(ror_json))
        return ror_json

    api_url = 'https://zenodo.org/api/records/?communities=ror-data&sort=mostrecent&size=1'
    print("Fetching latest ROR record from Zenodo...")

    # Allow unverified SSL for older Python/container environments
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE

    try:
        req = urllib.request.Request(api_url, headers={'Accept': 'application/json'})
        with urllib.request.urlopen(req, timeout=60, context=ctx) as resp:
            data = json.loads(resp.read().decode('utf-8'))
    except Exception as e:
        print("urllib failed ({}), trying wget...".format(e))
        tmp = os.path.join(WORK_DIR, '_zenodo_api.json')
        subprocess.run(['wget', '-q', '-O', tmp, api_url], check=True)
        with open(tmp) as f:
            data = json.load(f)

    hits = data.get('hits', {}).get('hits', [])
    if not hits:
        sys.exit("ERROR: No ROR records found on Zenodo")

    record = hits[0]
    title = record.get('metadata', {}).get('title', 'unknown')
    print("  Record: {}".format(title))

    zip_info = None
    for f in record.get('files', []):
        if f.get('key', '').endswith('.zip'):
            zip_info = f
            break
    if not zip_info:
        sys.exit("ERROR: No zip file in ROR record")

    zip_url = zip_info['links']['self']
    zip_path = os.path.join(WORK_DIR, 'ror_data.zip')
    size_mb = zip_info.get('size', 0) / 1e6
    print("  Downloading {} ({:.1f} MB)...".format(zip_info['key'], size_mb))

    try:
        urllib.request.urlretrieve(zip_url, zip_path)
    except Exception:
        subprocess.run(['wget', '-q', '-O', zip_path, zip_url], check=True)

    print("  Extracting...")
    with zipfile.ZipFile(zip_path, 'r') as z:
        json_files = [n for n in z.namelist()
                      if n.endswith('.json') and not n.startswith('__')]
        if not json_files:
            sys.exit("ERROR: No JSON in ROR zip")
        json_files.sort(key=lambda n: z.getinfo(n).file_size, reverse=True)
        target = json_files[0]
        print("  Extracting {} ({:.1f} MB)...".format(
            target, z.getinfo(target).file_size / 1e6))
        with z.open(target) as jf, open(ror_json, 'wb') as out:
            out.write(jf.read())

    print("  Saved to {}".format(ror_json))
    return ror_json


def parse_ror(path):
    """Parse ROR JSON. Return list of org dicts."""
    global _ror_countries
    print("Parsing ROR data...")
    with open(path) as f:
        records = json.load(f)

    sample = records[0] if records else {}
    is_v2 = 'names' in sample
    print("  Schema: {}".format('v2' if is_v2 else 'v1'))

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
                l = lbl.get('label', '')
                if l:
                    names.append(l)
            addrs = rec.get('addresses', [])
            city = addrs[0].get('city', '') if addrs else ''
            ci = rec.get('country', {})
            country = ci.get('country_name', '')

        all_lower = list(set(n.lower().strip() for n in names if n.strip()))
        c_low = country.lower().strip()
        _ror_countries.add(c_low)

        orgs.append({
            'ror_id': ror_id,
            'name': primary,
            'all_names_lower': all_lower,
            'city': city,
            'city_lower': city.lower().strip(),
            'country': country,
            'country_lower': c_low,
        })

    print("  {} organizations, {} countries".format(len(orgs), len(_ror_countries)))
    return orgs


# ============================================================
# Indices
# ============================================================

def build_name_index(orgs):
    """lowercase_name -> [org indices]"""
    idx = defaultdict(list)
    for i, o in enumerate(orgs):
        for n in o['all_names_lower']:
            idx[n].append(i)
    return dict(idx)


def build_country_index(orgs):
    """country_lower -> [org indices]"""
    idx = defaultdict(list)
    for i, o in enumerate(orgs):
        if o['country_lower']:
            idx[o['country_lower']].append(i)
    return dict(idx)


def build_city_country_index(orgs):
    """(city_lower, country_lower) -> [org indices]"""
    idx = defaultdict(list)
    for i, o in enumerate(orgs):
        if o['city_lower'] and o['country_lower']:
            idx[(o['city_lower'], o['country_lower'])].append(i)
    return dict(idx)


# Words to skip in word-index (too common to be discriminating)
_STOP_WORDS = frozenset([
    'of', 'the', 'and', 'for', 'de', 'du', 'des', 'la', 'le', 'les', 'di',
    'del', 'da', 'das', 'dos', 'den', 'der', 'die', 'van', 'von', 'und',
    'e', 'y', 'a', 'in', 'en', 'et', 'al', 'el', 'i',
])


def _tokenize(name):
    """Extract significant words (>= 3 chars, not stop words) from a name."""
    return set(
        w for w in re.findall(r'[a-z]{3,}', name.lower())
        if w not in _STOP_WORDS
    )


def build_word_country_index(orgs):
    """(word, country_lower) -> set of org indices.
    Used to pre-filter fuzzy matching: only compare orgs sharing >= 1 word.
    """
    idx = defaultdict(set)
    for i, o in enumerate(orgs):
        c = o['country_lower']
        for name in o['all_names_lower']:
            for w in _tokenize(name):
                idx[(w, c)].add(i)
    # Convert to regular dict of sets for faster lookups
    return dict(idx)


def get_word_filtered_candidates(query_name, country_norm, word_country_idx, country_index):
    """Get candidate org indices that share words with query_name in the same country.
    Uses word frequency weighting: common words (matching >500 orgs) are deprioritized.
    Requires 2+ shared words if any single word returns too many hits.
    Falls back to full country list if no word overlap found.
    """
    words = _tokenize(query_name)
    if not words:
        return country_index.get(country_norm, [])

    # Gather per-word candidate sets with sizes
    word_sets = []
    for w in words:
        key = (w, country_norm)
        if key in word_country_idx:
            s = word_country_idx[key]
            word_sets.append((w, s))

    if not word_sets:
        # No tokenizable words (abbreviation/acronym) - don't search entire country
        return []

    # If we have multiple words, intersect specific words first
    # Sort by set size (ascending) — smaller sets are more discriminating
    word_sets.sort(key=lambda x: len(x[1]))

    if len(word_sets) >= 2:
        # Use intersection of 2 most specific words
        candidates = word_sets[0][1] & word_sets[1][1]
        # If intersection is empty, union the 2 smallest
        if not candidates:
            candidates = word_sets[0][1] | word_sets[1][1]
    else:
        candidates = word_sets[0][1]

    # Cap at 500 to keep fuzzy matching fast
    if len(candidates) > 500:
        # Further intersect with more words if available
        for _, s in word_sets[2:]:
            candidates = candidates & s
            if len(candidates) <= 500:
                break
        # If still too large, just take the first 500
        if len(candidates) > 500:
            candidates = set(list(candidates)[:500])

    return list(candidates)


# ============================================================
# Matching utilities
# ============================================================

def normalize_country(name):
    """Normalize a country name to match ROR country_lower values."""
    if not name:
        return ''
    c = name.strip().lower()
    if c in _country_cache:
        return _country_cache[c]

    # Check aliases
    if c in COUNTRY_ALIASES:
        result = COUNTRY_ALIASES[c]
        _country_cache[c] = result
        return result

    # Already a known ROR country?
    if c in _ror_countries:
        _country_cache[c] = c
        return c

    # Fuzzy match against ROR countries
    best_score = 0.0
    best = c
    for rc in _ror_countries:
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
    """Parse 'Name; City State, Country'. Return (name, city, state, country)."""
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

    # Parse location: "City State, Country"
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
    """Fuzzy-match a name against ROR orgs. Return [(org_idx, score)] desc by score."""
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
# Method A: Institution name -> ROR
# ============================================================

def run_method_a(institutions, orgs, name_index, country_index, word_country_idx):
    """Match two_institution values to ROR by name.
    Return dict: two_institution -> ('exact'|'fuzzy'|'none', [(org_idx, score)])
    """
    print("\n" + "=" * 60)
    print("METHOD A: Institution Name Matching")
    print("=" * 60)
    t0 = time.time()

    exact = []    # (two_inst, org_idx, pcount)
    fuzzy = []    # (two_inst, [(idx, score)], pcount)
    nomatch = []  # (two_inst, pcount)
    mapping = {}  # two_inst -> (type, [(idx, score)])

    total = len(institutions)
    for i, (two_inst, pcount) in enumerate(institutions):
        if (i + 1) % 2000 == 0 or i + 1 == total:
            elapsed = time.time() - t0
            print("  {}/{} ({:.0f}s)".format(i + 1, total, elapsed),
                  flush=True)

        name, city, state, country = parse_two_institution(two_inst)
        name_lower = name.lower().strip()
        country_norm = normalize_country(country)

        # --- Exact match ---
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

        # --- Fuzzy match (word-filtered candidates for speed) ---
        if country_norm:
            cands = get_word_filtered_candidates(
                name, country_norm, word_country_idx, country_index)
        else:
            # No country info — skip fuzzy (too expensive without filtering)
            cands = []

        matches = fuzzy_match_name(name, cands, orgs)
        if matches:
            fuzzy.append((two_inst, matches, pcount))
            mapping[two_inst] = ('fuzzy', matches)
        else:
            nomatch.append((two_inst, pcount))
            mapping[two_inst] = ('none', [])

    # --- Write files ---
    p = os.path.join(WORK_DIR, 'institution_match_exact.tsv')
    print("\n  Writing {} ({} rows)".format(p, len(exact)))
    with open(p, 'w', newline='') as f:
        w = csv.writer(f, delimiter='\t')
        w.writerow(['two_institution', 'ror_id', 'ror_name', 'person_count'])
        for inst, idx, pc in sorted(exact, key=lambda x: -x[2]):
            o = orgs[idx]
            w.writerow([inst, o['ror_id'], o['name'], pc])

    p = os.path.join(WORK_DIR, 'institution_match_fuzzy.tsv')
    print("  Writing {} ({} rows)".format(p, len(fuzzy)))
    with open(p, 'w', newline='') as f:
        w = csv.writer(f, delimiter='\t')
        hdr = ['two_institution']
        for n in range(1, TOP_N + 1):
            hdr += ['ror_id_{}'.format(n), 'ror_name_{}'.format(n), 'score_{}'.format(n)]
        hdr.append('person_count')
        w.writerow(hdr)
        for inst, matches, pc in sorted(fuzzy, key=lambda x: -x[2]):
            row = [inst]
            for idx, sc in matches:
                o = orgs[idx]
                row += [o['ror_id'], o['name'], '{:.4f}'.format(sc)]
            while len(row) < 1 + TOP_N * 3:
                row.append('')
            row.append(pc)
            w.writerow(row)

    p = os.path.join(WORK_DIR, 'institution_no_match.tsv')
    print("  Writing {} ({} rows)".format(p, len(nomatch)))
    with open(p, 'w', newline='') as f:
        w = csv.writer(f, delimiter='\t')
        w.writerow(['two_institution', 'person_count'])
        for inst, pc in sorted(nomatch, key=lambda x: -x[1]):
            w.writerow([inst, pc])

    ex_p = sum(pc for _, _, pc in exact)
    fz_p = sum(pc for _, _, pc in fuzzy)
    nm_p = sum(pc for _, pc in nomatch)
    elapsed = time.time() - t0
    print("\n  Method A done in {:.0f}s".format(elapsed))
    print("  Exact:    {:>6} institutions  {:>6} persons".format(len(exact), ex_p))
    print("  Fuzzy:    {:>6} institutions  {:>6} persons".format(len(fuzzy), fz_p))
    print("  No match: {:>6} institutions  {:>6} persons".format(len(nomatch), nm_p))

    return mapping


# ============================================================
# Method B: Address fields -> ROR
# ============================================================

def run_method_b(addresses, orgs, name_index, city_country_index, country_index):
    """Match persons by address fields.
    Return dict: joinkey -> ('exact'|'fuzzy'|'none', [(org_idx, score)], matched_line)
    """
    print("\n" + "=" * 60)
    print("METHOD B: Address Field Matching")
    print("=" * 60)
    t0 = time.time()

    exact = []    # (jk, org_idx, line, city, country)
    fuzzy = []    # (jk, [(idx,sc)], line, city, country)
    nomatch = []  # (jk, lines_str, city, state, post, country)
    mapping = {}

    keys = sorted(addresses.keys())
    total = len(keys)

    for i, jk in enumerate(keys):
        if (i + 1) % 10000 == 0 or i + 1 == total:
            elapsed = time.time() - t0
            print("  {}/{} ({:.0f}s)".format(i + 1, total, elapsed),
                  flush=True)

        addr = addresses[jk]
        lines = [ln for _, ln in sorted(addr['street_lines'])]
        city = addr['city']
        state = addr['state']
        post = addr['post']
        country = addr['country']
        country_norm = normalize_country(country)
        city_lower = city.lower().strip()

        # --- Exact name match on any street line ---
        found = False
        for ln in lines:
            ln_lower = ln.lower().strip()
            if ln_lower in name_index:
                candidates = name_index[ln_lower]
                best = candidates[0]
                # Prefer same city+country
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

        # --- Fuzzy: get candidates by city+country ---
        # (Don't fall back to entire country — too slow and imprecise)
        cands = []
        if city_lower and country_norm:
            cands = city_country_index.get((city_lower, country_norm), [])

        if not cands:
            nomatch.append((jk, ' | '.join(lines), city, state, post, country))
            mapping[jk] = ('none', [], '')
            continue

        # Fuzzy match each street line, keep best
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

    # --- Write files ---
    p = os.path.join(WORK_DIR, 'address_match_exact.tsv')
    print("\n  Writing {} ({} rows)".format(p, len(exact)))
    with open(p, 'w', newline='') as f:
        w = csv.writer(f, delimiter='\t')
        w.writerow(['joinkey', 'ror_id', 'ror_name', 'matched_street_line', 'city', 'country'])
        for jk, idx, ln, ci, co in exact:
            o = orgs[idx]
            w.writerow([jk, o['ror_id'], o['name'], ln, ci, co])

    p = os.path.join(WORK_DIR, 'address_match_fuzzy.tsv')
    print("  Writing {} ({} rows)".format(p, len(fuzzy)))
    with open(p, 'w', newline='') as f:
        w = csv.writer(f, delimiter='\t')
        hdr = ['joinkey']
        for n in range(1, TOP_N + 1):
            hdr += ['ror_id_{}'.format(n), 'ror_name_{}'.format(n), 'score_{}'.format(n)]
        hdr += ['matched_street_line', 'city', 'country']
        w.writerow(hdr)
        for jk, matches, ln, ci, co in fuzzy:
            row = [jk]
            for idx, sc in matches:
                o = orgs[idx]
                row += [o['ror_id'], o['name'], '{:.4f}'.format(sc)]
            while len(row) < 1 + TOP_N * 3:
                row.append('')
            row += [ln, ci, co]
            w.writerow(row)

    p = os.path.join(WORK_DIR, 'address_no_match.tsv')
    print("  Writing {} ({} rows)".format(p, len(nomatch)))
    with open(p, 'w', newline='') as f:
        w = csv.writer(f, delimiter='\t')
        w.writerow(['joinkey', 'street_lines', 'city', 'state', 'post', 'country'])
        for row_data in nomatch:
            w.writerow(row_data)

    elapsed = time.time() - t0
    print("\n  Method B done in {:.0f}s".format(elapsed))
    print("  Exact:    {:>6} persons".format(len(exact)))
    print("  Fuzzy:    {:>6} persons".format(len(fuzzy)))
    print("  No match: {:>6} persons".format(len(nomatch)))

    return mapping


# ============================================================
# Cross-comparison
# ============================================================

def run_cross_compare(inst_mapping, addr_mapping, person_insts, addresses, orgs):
    """Compare Method A and B results per person. Write summary + extra lines."""
    print("\n" + "=" * 60)
    print("CROSS-COMPARISON")
    print("=" * 60)
    t0 = time.time()

    both_agree = 0
    both_disagree = 0
    a_only = 0
    b_only = 0
    neither = 0
    disagree_details = []  # (jk, a_org_name, b_org_name)

    extra_lines = []  # (jk, line, matched_ror_name)

    all_jk = sorted(set(person_insts.keys()) | set(addresses.keys()))
    total = len(all_jk)

    for i, jk in enumerate(all_jk):
        if (i + 1) % 10000 == 0 or i + 1 == total:
            elapsed = time.time() - t0
            print("  {}/{} ({:.0f}s)".format(i + 1, total, elapsed))

        # Method A result for this person
        a_idx = None
        inst = person_insts.get(jk)
        if inst and inst in inst_mapping:
            _, cands = inst_mapping[inst]
            if cands:
                a_idx = cands[0][0]

        # Method B result
        b_idx = None
        if jk in addr_mapping:
            _, cands, _ = addr_mapping[jk]
            if cands:
                b_idx = cands[0][0]

        # Classify
        if a_idx is not None and b_idx is not None:
            if a_idx == b_idx:
                both_agree += 1
            else:
                both_disagree += 1
                disagree_details.append((
                    jk, orgs[a_idx]['name'], orgs[b_idx]['name']))
        elif a_idx is not None:
            a_only += 1
        elif b_idx is not None:
            b_only += 1
        else:
            neither += 1

        # Extra address lines
        best_idx = a_idx if a_idx is not None else b_idx
        if best_idx is not None and jk in addresses:
            org = orgs[best_idx]
            org_names = set(org['all_names_lower'])
            org_names.add(org['city_lower'])
            addr = addresses[jk]
            for _, ln in sorted(addr['street_lines']):
                ln_low = ln.lower().strip()
                matched = False
                for on in org_names:
                    if not on:
                        continue
                    # Quick check: substring
                    if on in ln_low or ln_low in on:
                        matched = True
                        break
                    sm = difflib.SequenceMatcher(None, ln_low, on)
                    if sm.real_quick_ratio() >= 0.7 and sm.ratio() >= 0.7:
                        matched = True
                        break
                if not matched:
                    extra_lines.append((jk, ln, org['name']))

    # --- Write extra lines ---
    p = os.path.join(WORK_DIR, 'address_extra_lines.tsv')
    print("\n  Writing {} ({} rows)".format(p, len(extra_lines)))
    with open(p, 'w', newline='') as f:
        w = csv.writer(f, delimiter='\t')
        w.writerow(['joinkey', 'extra_street_line', 'matched_ror_institution'])
        for row_data in extra_lines:
            w.writerow(row_data)

    # --- Write summary ---
    p = os.path.join(WORK_DIR, 'summary.txt')
    lines = [
        "=== Person-Institution ROR Matching Summary ===",
        "Generated: {}".format(time.strftime('%Y-%m-%d %H:%M:%S')),
        "",
        "--- Data Volume ---",
        "Persons in two_institution:  {}".format(len(person_insts)),
        "Persons in two_street:       {}".format(len(addresses)),
        "Total unique persons (union): {}".format(total),
        "",
        "--- Cross-Comparison ({} persons) ---".format(total),
        "Both matched, SAME ROR org:       {:>6}  ({:.1f}%)".format(
            both_agree, 100 * both_agree / max(total, 1)),
        "Both matched, DIFFERENT ROR org:  {:>6}  ({:.1f}%)".format(
            both_disagree, 100 * both_disagree / max(total, 1)),
        "Method A only (institution name): {:>6}  ({:.1f}%)".format(
            a_only, 100 * a_only / max(total, 1)),
        "Method B only (address fields):   {:>6}  ({:.1f}%)".format(
            b_only, 100 * b_only / max(total, 1)),
        "Neither method matched:           {:>6}  ({:.1f}%)".format(
            neither, 100 * neither / max(total, 1)),
        "",
        "--- Address Extra Lines ---",
        "Total extra street lines: {}".format(len(extra_lines)),
        "Distinct persons with extras: {}".format(
            len(set(j for j, _, _ in extra_lines))),
    ]

    if disagree_details:
        lines += [
            "",
            "--- Sample Disagreements (first 20) ---",
        ]
        for jk, a_name, b_name in disagree_details[:20]:
            lines.append("  {} : A={} | B={}".format(jk, a_name, b_name))

    with open(p, 'w') as f:
        f.write('\n'.join(lines) + '\n')

    elapsed = time.time() - t0
    print("\n  Cross-comparison done in {:.0f}s".format(elapsed))
    print("\n  SUMMARY:")
    for ln in lines:
        print("  " + ln)


# ============================================================
# Main
# ============================================================

def main():
    print("=" * 60)
    print("Person-Institution ROR Matching")
    print("=" * 60)
    t_start = time.time()

    os.makedirs(WORK_DIR, exist_ok=True)

    # ROR data
    ror_path = download_ror()
    orgs = parse_ror(ror_path)

    # Indices
    print("\nBuilding indices...", flush=True)
    name_idx = build_name_index(orgs)
    country_idx = build_country_index(orgs)
    cc_idx = build_city_country_index(orgs)
    wc_idx = build_word_country_index(orgs)
    print("  Name index:           {} unique names".format(len(name_idx)))
    print("  Country index:        {} countries".format(len(country_idx)))
    print("  City+country index:   {} combinations".format(len(cc_idx)))
    print("  Word+country index:   {} entries".format(len(wc_idx)))

    # DB data
    institutions = load_institutions()
    person_insts = load_person_institutions()
    addresses = load_addresses()

    # Method A
    inst_mapping = run_method_a(institutions, orgs, name_idx, country_idx, wc_idx)

    # Method B
    addr_mapping = run_method_b(addresses, orgs, name_idx, cc_idx, country_idx)

    # Cross-compare
    run_cross_compare(inst_mapping, addr_mapping, person_insts, addresses, orgs)

    elapsed = time.time() - t_start
    print("\n" + "=" * 60)
    print("ALL DONE in {:.0f}m {:.0f}s".format(elapsed // 60, elapsed % 60))
    print("Output: {}".format(WORK_DIR))
    print("=" * 60)


if __name__ == '__main__':
    main()
