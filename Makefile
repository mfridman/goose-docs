.PHONY: preview
preview:
	mkdocs serve --dev-addr=0.0.0.0:8000

.PHONY: build
build:
	mkdocs build --config-file mkdocs.yml && rsync -chavzp site/ ~/src/github.com/pressly/goose