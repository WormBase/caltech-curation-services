#!/usr/bin/python

# python version of script to process alliance molecular interactions to generate stats.  2019 11 04


import re
import sys


order = "totalInteractionCount interactorsPerSpecies interactorTypes interactorTypePairsSorted interactorTypePairsSortedTaxid:9606 interactorTypePairsSortedTaxid:10116 interactorTypePairsSortedTaxid:10090 interactorTypePairsSortedTaxid:7955 interactorTypePairsSortedTaxid:7227 interactorTypePairsSortedTaxid:6239 interactorTypePairsSortedTaxid:559292 interactorTypePairsSortedTaxid:2697049 interactorTypePairsSortedInterspecies interactionTypes experimentalRoles sourceDatabases interactionIdPrefixes primaryInteractorId altInteractorId aliasInteractorId detectionMethods".split(" ")
hash = {}
for category in order:
  hash[category] = {}
taxonInteraction = {}

def main():
  processFileIntoHash()
  outputHashData()

def processFileIntoHash():
#   infile = 'alliance_molecular_interactions_sgd.txt'
  infile = 'Alliance_molecular_interactions_2.2.txt'
  if (len(sys.argv)>1):
#     print ("the script has the name %s" % (sys.argv[1]))
    infile = sys.argv[1];
  with open(infile) as fp:
    for inline in fp:
      if not inline.startswith("#"):
        lineArray = inline.split("\t")
        processPipeColon('primaryInteractorId', lineArray[0])
        processPipeColon('primaryInteractorId', lineArray[1])
        processPipeColon('altInteractorId', lineArray[2])
        processPipeColon('altInteractorId', lineArray[3])
        processPipeColon('aliasInteractorId', lineArray[4])
        processPipeColon('aliasInteractorId', lineArray[5])
        processSingle('detectionMethods', lineArray[6])
        processSingle('interactorsPerSpecies', lineArray[9])
        processSingle('interactorsPerSpecies', lineArray[10])
        processTaxonInteraction(lineArray[9], lineArray[10], lineArray[13], lineArray[20], lineArray[21])
        processSingle('interactionTypes', lineArray[11])
        processSingle('sourceDatabases', lineArray[12])
        processSingle('totalInteractionCount', lineArray[13])
        processPipeColon('interactionIdPrefixes', lineArray[13])
        processSingle('experimentalRoles', lineArray[18])
        processSingle('experimentalRoles', lineArray[19])
        processSingle('interactorTypes', lineArray[20])
        processSingle('interactorTypes', lineArray[21])

def processTaxon():
  taxonToPipe = {}
  tabToTaxon = {}
  cat = 'interactorsPerSpecies'
  categoryData = hash[cat]
  for tab in categoryData:
    taxon = re.match("taxid:(\d+)", tab)
    tabToTaxon[tab] = taxon.group(1)
    if "|" in tab:
      taxonToPipe[taxon.group(1)] = tab
  temp = {}
  for tab in categoryData:
    taxon = tabToTaxon[tab]
    if taxon in taxonToPipe:
      taxon = taxonToPipe[taxon]
    else:
      taxon = tab
    if taxon not in temp:
      temp[taxon] = categoryData[tab]
    else:
      temp[taxon] += categoryData[tab]
  textInteractorsPerSpecies = "Interactors Per Species:\n";
  sortedTemp = sorted(temp.items(), reverse=True, key=lambda x: x[1])
  for elem in sortedTemp:
    textInteractorsPerSpecies += elem[0] + "\t" + str(elem[1]) + "\n"

  temp = {}
  for taxon in taxonInteraction:
    count = len(taxonInteraction[taxon])
    if taxon in taxonToPipe:
      taxon = taxonToPipe[taxon]
    temp[taxon] = count
  print "Interactions Per Species:"
  sortedTemp = sorted(temp.items(), reverse=True, key=lambda x: x[1])
  for elem in sortedTemp:
    print elem[0] + "\t" + str(elem[1])
  print
  print textInteractorsPerSpecies.rstrip()

def processTaxonInteraction(taxid1, taxid2, interaction, inttype1, inttype2):
  intTypes = []
  if inttype1:
    intTypes.append(inttype1)
  if inttype2:
    intTypes.append(inttype2)
  key = " ".join(sorted(intTypes))
  if key not in hash['interactorTypePairsSorted']:
    hash['interactorTypePairsSorted'][key] = 1
  else:
    hash['interactorTypePairsSorted'][key] += 1
  match1 = re.match("taxid:(\d+)", taxid1)
  match2 = re.match("taxid:(\d+)", taxid2)
  taxon1 = match1.group(1)
  taxon2 = match2.group(1)
  cat = ''
  taxonInteractionCategory = ''
  if (taxon1 == taxon2):
    cat = 'interactorTypePairsSortedTaxid:' + taxon1
    taxonInteractionCategory = taxon1
  else:
    cat = 'interactorTypePairsSortedInterspecies'
    taxonInteractionCategory = 'Interspecies'
  if key not in hash[cat]:
    hash[cat][key] = 1
  else:
    hash[cat][key] += 1
  if taxonInteractionCategory not in taxonInteraction:
    taxonInteraction[taxonInteractionCategory] = {}
    taxonInteraction[taxonInteractionCategory][interaction] = 1
  else:
    subHash = taxonInteraction[taxonInteractionCategory]
    if interaction not in subHash:
      taxonInteraction[taxonInteractionCategory][interaction] = 1
    else:
      taxonInteraction[taxonInteractionCategory][interaction] += 1

def processSingle(category, column):
  if column not in hash[category]:
    hash[category][column] = 1
  else:
    hash[category][column] += 1

def processPipeColon(category, column):
  entries = column.split("|")
  for entry in entries:
    values = entry.split(":")
    if values[0] not in hash[category]:
      hash[category][values[0]] = 1
    else:
      hash[category][values[0]] += 1

def outputHashData():
  for category in order:
    categoryData = hash[category]
#     for key in sortedCategoryData:
#       print key + " is " + str(sortedCategoryData[key])
#     sortedCategoryData = sorted( ((v,k) for k,v in categoryData.iteritems()), reverse=True)	# not sure how this works
    if (category == 'totalInteractionCount'):
      print convertCamelcaseToTitle(category) + ":"
      print "total\t" + str(len(categoryData))
    elif (category == 'interactorsPerSpecies'):
      processTaxon()
    else:
      print convertCamelcaseToTitle(category) + ":"
      sortedCategoryData = sorted(categoryData.items(), reverse=True, key=lambda x: x[1])
      for elem in sortedCategoryData:
        print elem[0] + "\t" + str(elem[1])
    print

def convertCamelcaseToTitle(name):
  s1 = re.sub('(.)([A-Z])', r'\1 \2', name)
  return s1.title()

if __name__ == '__main__':
    main()

  

"""

var_gene_file = file_dir + 'WS273_variation_interactors_and_genes.txt'
int_module_pap_file = file_dir + 'WS273_genetic_interactions_and_types_and_papers.txt';
int_gene_type_file  = file_dir + 'WS273_genetic_interactions_and_interactors.txt';


varGene = {}
with open(var_gene_file) as fp:
  cnt = 0
  for inline in fp:
    cnt += 1
#     if cnt > 5:
#       break
#     inline = inline.rstrip()		# can't do this, leaves no tab for wbg if there isn't a wbg, and split complains
    inline = inline.replace('"', '')
#     print inline
#     print var + " SPACE " + wbg
    var, wbg = inline.split("\t", 1)
    if var in varGene:
      varGene[var] = 'skip'
    else:
      varGene[var] = wbg.rstrip()

# for key, value in varGene.items():
#   print key + " is " + value

intGene = {}
intSuppress = {}
with open(int_gene_type_file) as fp:
  for inline in fp:
    inline = inline.replace('"', '')
    int, gene, type, species = inline.split("\t", 3)
    species = species.strip()
    if (species == 'Caenorhabditis elegans'):
      if int not in intGene:
        intGene[int] = {}
      intGene[int][gene] = type
    else:
#       print "Species " + species + " INT " + int
      intSuppress[int] = 1


with open(int_module_pap_file) as fp:
  for inline in fp:
    inline = inline.replace('"', '')
    int, type, mod1, mod2, mod3, pap, brief = inline.split("\t", 6)
    brief = brief.strip()
    if (mod3 == 'Neutral'):
      continue
    if int in intSuppress:
#       print "skip in intSuppress " + int
      continue
    key = mod1 + 'TAB' + mod2 + 'TAB' + mod3
    tab = []
    for i in range(42):
      tab.append('-')
    tab[13] = 'wormbase:' + int
    if int in intGene:
      if (len(intGene[int]) != 2):
#         print "int " + int + " has " + str(len(intGene[int])) + " genes"
        continue
      gene1, gene2 = sorted(intGene[int], key = intGene[int].get)
      tab[0] = 'wormbase:' + gene1
      tab[1] = 'wormbase:' + gene2
    outline = "\t".join(tab)
    print outline


def foo(x):
    y = 10 * x + 2
    return y

print foo(10)

i = 10
d = 3.1415926
s = "I'm a string !"
print "%d\t%f\t%s" % (i, d, s)
print "no newline",

import math
print math.sqrt(2.0)

import sys
print len(sys.argv)
print sys.argv
"""
