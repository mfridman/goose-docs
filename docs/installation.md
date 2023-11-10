# Installing goose

This project is both a command-line utility (CLI) and a library. This section covers how to install
or build `goose`.

You can also install a pre-compiled binary from the
[GitHub release page](https://github.com/pressly/goose/releases). Don't forget to set the executable
bit on macOS and Linux.

## :material-apple: macOS

---

### Homebrew

If you're on a Mac, the easiest way to get started is with the [Homebrew](https://brew.sh) package
manager.

```sh
brew install goose
```

An installation script is available that works on macOS, see
[:fontawesome-brands-linux: Linux](#linux).

## :fontawesome-brands-linux: Linux

---

At the root of the project is an
[`install.sh` script](https://github.com/pressly/goose/blob/master/install.sh) to download and
install the binary.

```sh
curl -fsSL \
    https://raw.githubusercontent.com/pressly/goose/master/install.sh |\
    sh #(1)!
```

1.  Since this script is downloading directly to `/usr/local/bin`, you may need to `sudo sh`. You'll
    often see an error such as:

    `curl: (23) Failure writing output to destination`

    Alternatively, change the output to a directory your current user can write to by setting
    `GOOSE_INSTALL`.

:octicons-arrow-right-16: The default output directory is `/usr/local/bin`, but can be changed by
setting `GOOSE_INSTALL`. Do not include `/bin`, it is added by the script.

:octicons-arrow-right-16: Optionally, a version can be specified as an argument. The default is to
download the `latest` version.

```sh
curl -fsSL \
    https://raw.githubusercontent.com/pressly/goose/master/install.sh |\
    GOOSE_INSTALL=$HOME/.goose sh -s v3.5.0
```

This will install `goose version v3.5.0` in directory:

    $HOME/.goose/bin/goose

## :material-microsoft-windows-classic: Windows

---

No installation script is available, but you can download a
[pre-built Windows binary](https://github.com/pressly/goose/releases) or build from source if Go is
installed.

## :toolbox: Building from source

---

You'll need Go 1.16 or later.

```sh
go install github.com/pressly/goose/v3/cmd/goose@latest
```

Alternatively, you can clone the repository and build from source.

```sh
git clone https://github.com/pressly/goose
cd goose
go mod tidy
go build -o goose ./cmd/goose

./goose --version
# goose version:(devel)
```

This will produce a `goose` binary **~15M** in size because it includes all supported drivers.

### Lite version

For a lite version of the binary, use the exclusive build tags. Here's an example where we target
only `sqlite`, and the resulting binary is **~8.7M** in size.

```sh
go build \
    -tags='no_postgres no_clickhouse no_mssql no_mysql' \
    -o goose ./cmd/goose
```

Bonus, let's make this binary smaller by stripping debugging information.

```sh
go build \
    -ldflags="-s -w" \
    -tags='no_postgres no_clickhouse no_mssql no_mysql' \
    -o goose ./cmd/goose
```

We're still only targeting `sqlite` and reduced the binary to **~6.6M**.

You can go further with a tool called `upx`, for more info check out
[Shrink your go binaries with this one weird trick](https://words.filippo.io/shrink-your-go-binaries-with-this-one-weird-trick/).
