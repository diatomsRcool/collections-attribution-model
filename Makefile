json:
	( \
	. environment.sh; \
	pip install -r requirements.txt; \
	gen-json-schema attributionmodel.yaml > attributionmodel.json \
	)

deploy-docs:
	$(foreach s,$(SOURCES), cp -pr target/$s/$s-docs/ docs/$s ;)
