MKDOCS_VERSION:=`pip list --no-index --format=json | jq -r '.[] | select(.name=="mkdocs").version'`
MATERIAL_VERSION:=`pip list --no-index --format=json | jq -r '.[] | select(.name=="mkdocs-material").version'`
DATE:=`date +%c`

.PHONY: preview
preview:
	mkdocs serve --dev-addr=0.0.0.0:8000

.PHONY: build
build:
	rm -rf site ./.cache \
	&& mkdocs build --config-file mkdocs.yml \
	&& rsync -chavzp site/ ~/src/github.com/pressly/goose

.PHONY: deploy
deploy:
	cd /Users/mfridman/src/github.com/pressly/goose \
	&& git checkout gh-pages \
	&& git add  . \
	&& (git commit -a -m "Update goose docs ${DATE}" -m "Deployed with MkDocs version: ${MKDOCS_VERSION} Material version: ${MATERIAL_VERSION}"  || echo "Nothing to commit")