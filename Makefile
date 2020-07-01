SOURCES = dwc
EXTS = .schema.json

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
target/%.schema.json: target/%.yaml
	gen-json-schema $< > $@

deploy-docs:
	$(foreach s,$(SOURCES), cp -pr target/$s/$s-docs/ docs/$s ;)
