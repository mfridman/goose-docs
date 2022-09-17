# goose docs website

The documentation is available at [pressly/goose docs](pressly.github.io/goose)

Installation instructions from here:

https://squidfunk.github.io/mkdocs-material/getting-started/

### Create project

```bash
mkdocs new .
```

### Preview project

```bash
make preview
```

Available at: http://localhost:8000


### How to update mkdocs-insiders

Keep pip3 up-to-date

    brew update && brew upgrade pip3

or

    python3.9 -m pip install --upgrade pip

---

https://squidfunk.github.io/mkdocs-material/insiders/getting-started/#with-git

    cd $HOME/src/github.com/mfridman
    pip install -e mkdocs-material-insiders


### Install plugins

From https://github.com/datarobot/mkdocs-redirects

    pip install mkdocs-redirects
