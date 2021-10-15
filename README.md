# What is this

This is a script to process the [ICD9 to SNOMEDCT mapping files](https://www.nlm.nih.gov/research/umls/mapping_projects/icd9cm_to_snomedct.html) into an RDF/TURTLE document for import into a triple store.  

# Usage

To use it, run the script in a bash-compatible shell.  
Several command-line options are available:

* -i *URL*  Set the ICD9CM graph URL
* -s *URL*  Set the SNOMEDCT graph URL
* -p *URL*  Set the predicate to use for annotations
* -f *FILE* Set path for input mapping file
* -m      Process 1-to-many file instead of 1-to-1 file
* -I      Generate ICD9CM class annotations
* -S      Generate SNOMEDCT class annotations

The only necessary choice is to provide either *-I* or *-S*.  
These set whether to output annotations for the ICD9CM or the SNOMEDCT resources.  

The mapping file is expected to be in the working directory named as it is found inside the zip (at present: ICD9CM_SNOMED_MAP_1TO1_202012.txt or ICD9CM_SNOMED_MAP_1TOM_202012.txt).  
This can be overriden with the `-f` option, but make sure you set the correct processing mode too (`-m` for 1-to-many, no flag for 1-to-1).  

The script will output to STDOUT, so must be redirected.  

Here's an example usage where the script is in the same directory as the mapping file and you wish to create annotations for the ICD9CM classes:  
`./convert.sh -I`  

With the defaults the script provides, this is equivalent to the following invocation:  
```bash
./convert.sh -I \
             -i 'http://purl.bioontology.org/ontology/ICD9CM/' \
             -s 'http://purl.bioontology.org/ontology/SNOMEDCT/' \
             -f ./ICD9CM_SNOMED_MAP_1TO1_202012.txt \
             -p skos:relation
```

Note: the only prefixes the script outputs are icd9cm, snomedct, and skos. If you provide the `-p PREDICATE` option then ensure you provide a full URL if the predicate is not inside icd9, snomed, or skos.