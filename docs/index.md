# Introduction

**goose** is a database migration tool. Manage your database schema by creating incremental SQL changes or Go functions.

## Goals of this fork

[github.com/pressly/goose](https://github.com/pressly/goose) is a fork of [bitbucket.org/liamstask/goose](https://bitbucket.org/liamstask/goose) with the following changes:

- No config files
- Default `goose` binary can migrate SQL files only
- Go migrations:
    - We don't go build Go migrations functions on-the-fly from within the `goose` binary
    - Instead, we let you create your own custom `goose` binary, register your Go migration functions explicitly and run complex migrations with your own *sql.DB connection
    - Go migration functions let you run your code within an SQL transaction, if you use the *sql.Tx argument
- The `goose` pkg is decoupled from the binary:
  - `goose` pkg doesn't register any SQL drivers anymore, thus no driver panic() conflict within your codebase!
  - `goose` pkg doesn't have any vendor dependencies anymore
- We use timestamped migrations by default but recommend a hybrid approach of using timestamps in the development process and sequential versions in production.