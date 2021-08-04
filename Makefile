.PHONY: preview
preview:
	mkdocs serve --dev-addr=0.0.0.0:8000

.PHONY: build
build:
	mkdocs build && rsync -chavzp site/ ~/go/src/github.com/pressly/goose