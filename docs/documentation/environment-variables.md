# Environment variables

Goose supports environment variables that can be used instead of command line arguments or flags.
This is useful for setting defaults or for use in automation scripts.

Environment variables have lower precedence than command line arguments and flags.

The following environment variables are supported:

- `GOOSE_DRIVER` - The database driver to use

- `GOOSE_DBSTRING` - The database connection string

- `GOOSE_MIGRATION_DIR` - The directory containing the migration files (default: `.`)

- `NO_COLOR` - Disable color output
