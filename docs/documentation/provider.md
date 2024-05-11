# Goose provider

The [Provider](https://pkg.go.dev/github.com/pressly/goose/v3#Provider) type is the entry point for
the goose library. It initializes the state and provides methods to run migrations. It does not have
global state, so you can create multiple providers with different configurations.

Initialize a provider by calling `goose.NewProvider()`:

```go
func NewProvider(
    dialect Dialect,
    db *sql.DB,
    fsys fs.FS,
    opts ...ProviderOption,
) (*Provider, error){
    // ...
}
```

## Provider

#### Dialect

The `Dialect` defines the SQL dialect of the database. Simply put, goose needs to know the raw SQL
syntax of the database its working with.

Each dialect has a corresponding constant backed by a
[database.Store](https://pkg.go.dev/github.com/pressly/goose/v3@v3.20.0/database#Store)
implementation.

For most users its sufficient to **use one of the natively supported dialects** and not worry about
the database store. For more advanced users, you may bring your own dialect and store, see the
[TODO]() section for more information.

#### db

The `*sql.DB` is the database connection that goose will use to run migrations. Goose intentionally
does not care which database driver is used.

The caller is responsible for matching the dialect with the database driver. For example, if you are
using the `goose.DialectPostgres` dialect, you'd pick the [jackc/pgx](https://github.com/jackc/pgx)
driver.

#### fsys

The [`fs.FS`](https://pkg.go.dev/io/fs#FS) is the filesystem abstraction that goose will use to read
migration files. This is will typically be [`os.DirFS`](https://pkg.go.dev/os#DirFS),
[`embed.FS`](https://pkg.go.dev/embed#FS).

Quite often you may have a heirarchy of directories with migrations, in which case you can use
[`fs.Sub`](https://pkg.go.dev/fs#Sub) to create a sub filesystem.

```go
fsys, err := fs.Sub(embeddedFS, "migrations")
```

And then pass the `fsys` to the provider.

## Provider Options

The `ProviderOption` is a functional option type that allows you to configure and customize the
provider.

### WithStore

### WithVerbose

```go
func WithVerbose(b bool)
```

This option enables verbose logging of the migration process. For example, here's the output of
running an up migration with verbose logging:

```shell
goose: OK    up 00001_users_table.sql (1.32ms)
goose: OK    up 00002_add_users.go (638.96µs)
goose: OK    up 00003_count_users.go (561.58µs)
goose: successfully migrated database, current version: 3
```

By default, the provider methods do not log anything by default.

### WithSessionLocker

```go
func WithSessionLocker(locker lock.SessionLocker)
```

By default, goose **does not** lock the database during migrations. It is up to the caller to ensure
migrations are run in a safe manner. Which means in certain environments, such as Kubernetes, you
may have multiple instances of your application running migrations concurrently.

By configuring a
[`SessionLocker`](https://pkg.go.dev/github.com/pressly/goose/v3@v3.20.0/lock#SessionLocker), you
can ensure that only one instance of your application runs migrations at a time.

The [lock package](https://pkg.go.dev/github.com/pressly/goose/v3@v3.20.0/lock) provides a few
implementations of the `SessionLocker` interface:

#### Postgres

The
[`NewPostgresSessionLocker`](https://pkg.go.dev/github.com/pressly/goose/v3@v3.20.0/lock#NewPostgresSessionLocker)
function creates a `SessionLocker` that can be used to acquire and release a lock for
synchronization purposes. The lock acquisition is retried until it is successfully acquired or until
the failure threshold is reached.

The default lock duration is set to 5 minutes, and the default unlock duration is set to 1 minute.
These can be tuned.

### WithExcludeNames

```go
func WithExcludeNames(excludes []string)
```

The option excludes the given file names from the list of migrations. If called multiple times, the
list of excludes is merged.

### WithExcludeVersions

```go
func WithExcludeVersions(versions []int64)
```

This option excludes the given versions from the list of migrations. If called multiple times, the
list of excludes is merged.

### WithGoMigrations

```go
func WithGoMigrations(migrations ...*Migration)
```

This option adds the given Go migration to the list of migrations. The migration **must be**
constructed using the
[`NewGoMigration`](https://pkg.go.dev/github.com/pressly/goose/v3#NewGoMigration) constructor.

#### NewGoMigration

```go
func NewGoMigration(version int64, up, down *GoFunc) *Migration
```

This function creates a new Go migration, which may be registered with a provider or globally.

Both up and down functions may be `nil`, in which case the migration will be recorded in the
versions table but no functions will be run. This is useful for recording (up) or deleting (down) a
version without running any functions.

A Go migration can either be executed within or outside a transaction and only one can be set. If
both are set, an error will be returned.

```go
RunTx func(ctx context.Context, tx *sql.Tx) error

// or

RunDB func(ctx context.Context, db *sql.DB) error
```

### WithDisableGlobalRegistry

```go
func WithDisableGlobalRegistry(b bool)
```

This option disables the global registry. By default, goose uses a global registry to store all
migrations. This is useful for running migrations in a single process. If you are running migrations
in multiple processes, you should disable the global registry and register migrations with the
provider.

### WithAllowOutofOrder

```go
func WithAllowOutofOrder(b bool)
```

This option allows migrations to be run out-of-order, this is often called "allow missing"
migrations. By default, goose will error if it detects that a migration is missing.

For example: migrations 1,3 are applied to the database and then versions 2,6 are introduced. If
this option is true, then goose will apply 2 (missing) and 6 (new) instead of raising an error.

The final order of applied migrations will be: 1,3,2,6. Out-of-order migrations are always applied
first, followed by new migrations.

### WithDisableVersioning

```go
func WithDisableVersioning(b bool)
```

This option disables versioning. Disabling versioning allows applying migrations without tracking
the versions in the database schema table. Useful for tests, seeding a database or running ad-hoc
queries. By default, goose will track all versions in the database schema table.
