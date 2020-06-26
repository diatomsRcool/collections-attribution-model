SOURCES = dwc
EXTS = _datamodel.py .graphql .schema.json .owl -docs .shex

all: $(foreach s,$(SOURCES), $(foreach x,$(EXTS), target/$s/$s$x))
#all: $(foreach s,$(SOURCES), all_$s/$s)
#all_%: 
#	echo $(foreach x,$(EXTS), target/$*.$x)



test:
	pytest tests/*py

# these are then moved to test
downloads/dwc.csv:
	curl -L -s https://raw.githubusercontent.com/tdwg/dwc/master/vocabulary/term_versions.csv > $@

# run tests to first generate yaml; these are then copied to target area
target/dwc/dwc.yaml: tests/dwc/dwc.yaml
	cp $< $@

#vpath %_datamodel.py target/kbase target/neon

target/%_datamodel.py: target/%.yaml
	gen-py-classes $< > $@
target/%.graphql: target/%.yaml
	gen-graphql $< > $@
target/%.schema.json: target/%.yaml
	gen-json-schema $< > $@
target/%.shex: target/%.yaml
	gen-shex $< > $@
target/%.csv: target/%.yaml
	gen-csv $< > $@
target/%.owl: target/%.yaml
	gen-owl $< > $@
target/%.ttl: target/%.owl
	cp $< $@
target/%-docs: target/%.yaml
	pipenv run gen-markdown --dir $@ $<

deploy-docs:
	$(foreach s,$(SOURCES), cp -pr target/$s/$s-docs/ docs/$s ;)

## Matches

ONTS = vivo cro
SRC_TTL = $(foreach s,$(SOURCES),target/$s/$s.ttl) $(foreach s,$(ONTS),ontologies/$s.ttl)
mappings/matches.tsv: $(SRC_TTL)
	rdfmatch -w mappings/weights.pro -i mappings/prefixes.ttl $(patsubst %, -i %, $(SRC_TTL)) match > $@
mappings/nomatches-gold-%.tsv: $(SRC_TTL)
	rdfmatch -p gold.vocab  -w mappings/weights.pro -i mappings/prefixes.ttl -i target/gold/gold.ttl -i target/$*/$*.ttl nomatch > $@
mappings/nomatches-biosample-gold-%.tsv: target/gold/biosample.ttl $(SRC_TTL)
	rdfmatch -p gold.vocab --match_prefix $*  -w mappings/weights.pro -i mappings/prefixes.ttl -i $< -i target/$*/$*.ttl nomatch > $@
mappings/nomatches-kbase-%.tsv: $(SRC_TTL)
	rdfmatch -p kbase  -w mappings/weights.pro -i mappings/prefixes.ttl -i target/kbase/kbase.ttl -i target/$*/$*.ttl nomatch > $@

mappings/%-summary.tsv: mappings/%.tsv
	grep -v ^# $<  | mlr --tsv count-distinct -f subject_source,object_source then sort -nr count > $@

OBO=http://purl.obolibrary.org/obo
ontologies/%.ttl:
	robot convert -I $(OBO)/$*.owl -o $@
ontologies/datacite.ttl:
	robot merge -I http://purl.org/spar/datacite.ttl  -o  $@