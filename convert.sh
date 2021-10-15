#!/bin/bash

icd_g='http://purl.bioontology.org/ontology/ICD9CM/'
snomed_g='http://purl.bioontology.org/ontology/SNOMEDCT/'
predicate='skos:relation'
map_mode='one'

function usage {
  echo "Usage: $0 [-i URL] [-s URL] [-p PRED] [-f FILE] [-m] [-I] [-S]"
  echo "  -i URL  Set the ICD9CM graph URL"
  echo "  -s URL  Set the SNOMEDCT graph URL"
  echo "  -p URL  Set the predicate to use for annotations"
  echo "  -f FILE Set path for input mapping file"
  echo "  -m      Process 1-to-many file instead of 1-to-1 file"
  echo "  -I      Generate ICD9CM class annotations"
  echo "  -S      Generate SNOMEDCT class annotations"
  exit 0
}

while getopts ':hi:s:p:f:mIS' OPTION; do
  case "$OPTION" in
    i)
      icd_g="$OPTARG"
      ;;
    s)
      snomed_g="$OPTARG"
      ;;
    p)
      predicate="$OPTARG"
      ;;
    f)
      mapping_file="$OPTARG"
      ;;
    m)
      map_mode='many'
      ;;
    I)
      gen_mode='icd'
      ;;
    S)
      gen_mode='snomed'
      ;;
    h*)
      usage
    ;;
  esac
done

# If no -f mapping_file specified then we shall guess
# the file name assuming it was extracted directly from the zip
# based on whether we are in 1-to-1 or 1-to-many processing mode
if [ "${map_mode}" == 'one' ]; then
  map_stub='ICD9CM_SNOMED_MAP_1TO1_'
else
  map_stub='ICD9CM_SNOMED_MAP_1TOM_'
fi

# Set the map_file
# 
# If -f mapping_file provided, attempt to use that (if exists)
# and throw error if not found
#
# If no -f mapping_file then attempt to find the txt file as
# it is named in the zip
# https://www.nlm.nih.gov/research/umls/mapping_projects/icd9cm_to_snomedct.html
if [ -s "${mapping_file}" ]; then
  if [ -f "${mapping_file}" ]; then
    map_file="${mapping_file}"
  else
    echo "Map file does not exist" >&2
    exit 1
  fi
elif [ -f "${map_stub}202012.txt" ]; then
  map_file="${map_stub}202012.txt"
else
  echo "No map file found, expected e.g. './ICD9CM_SNOMED_MAP_1TO1_202012.txt'" >&2
  exit 1
fi

# Turtle output, specifying prefix makes file smaller
# and doesn't require passing graph URLs to awk
echo "@prefix skos: <http://www.w3.org/2004/02/skos/core#> ."
echo "@prefix icd9cm: <${icd_g}> ."
echo "@prefix snomedct: <${snomed_g}> ."
echo ""
echo ""

# ICD and SNOMED both have a 1-to-1 and 1-to-many processing mode
# ICD mode annotates ICD concepts with predicate to the snomed concepts
# SNOMED mode annotates SNOMED concepts with predicate to the ICD concepts
#
# 1-to-1 provides a simple mapping and is easier to work with but misses
# some concepts
# See URL further up in script for more info provided by NLM
#
# First thing done in any mode is skip the TSV header row
# 1-to-many mode has an extra check as the 1-to-many map file may
# have NULL snomed codes for some rows

if [ "$gen_mode" == "icd" ] && [ "$map_mode" == 'one' ]; then
  awk -v FS='\t' \
      -v 'PRED='"${predicate}" \
      '(NR>1) { print "icd9cm:" $1 " " PRED " snomedct:" $8 " ." }' \
      "$map_file"
elif [ "$gen_mode" == "icd" ] && [ "$map_mode" == 'many' ]; then
  awk -v FS='\t' \
      -v 'PRED='"${predicate}" \
      -f- "$map_file" <<'EOF'
  (NR>1 && $8 != "NULL") {
    print "icd9cm:" $1 " " PRED " snomedct:" $8 " ."
  }
EOF
elif [ "$gen_mode" == "snomed" ] && [ "$map_mode" == 'one' ]; then
  awk -v FS='\t' \
      -v 'PRED='"${predicate}" \
      '(NR>1) { print "snomedct:" $8 " " PRED " icd9cm:" $1 " ." }' \
      "$map_file"
elif [ "$gen_mode" == "snomed" ] && [ "$map_mode" == 'many' ]; then
  awk -v FS='\t' \
      -v 'PRED='"${predicate}" \
      -f- "$map_file" <<'EOF'
  (NR>1 && $8 != "NULL") {
    print "snomedct:" $8 " " PRED " icd9cm:" $1 " ."
  }
EOF
else
  usage
fi