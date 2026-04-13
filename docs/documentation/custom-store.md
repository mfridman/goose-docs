# Custom database store

Goose aims to support a large number of database technologies out-of-the-box, but it's neither
possible nor practical to support every database and the various configurations.

For example, there have been many requests for
[ClickHouse engines](https://clickhouse.com/docs/en/engines/table-engines) because goose ships with
the `MergeTree` engine by default, but this may be insufficient for some projects.

- [:simple-github: pressly/gooose#809](https://github.com/pressly/gooose/issues/809)
- [:simple-github: pressly/gooose#530](https://github.com/pressly/gooose/issues/530)
- [:simple-github: pressly/gooose#520](https://github.com/pressly/gooose/issues/520)

For such cases, users can bring their own store implementation so long as it fits the
`database.Store` interface.

The core goose library makes no assumptions about the underlying database and uses the
`database.Store` for all operations.

## Usage

To use a custom store, simply pass it to the [Provider](provider.md) when creating a new instance by
supplying the `goose.WithStore` option.

```go
provider, err := goose.NewProvider(
	"",
	db,
	migrations.Embed,
	// Use custom store implementation.
	goose.WithStore(memory.New("goose_migrations")),
)
if err != nil {
	return err
}
```

!!! note

    When using a custom store, the first argument to `goose.NewProvider` must be an empty string.

## Store interface

More documentation on the `database.Store` interface can be found in the
[godoc](https://pkg.go.dev/github.com/pressly/goose/v3/database#Store), but here is a brief
overview:

```go
type Store interface {
	// Tablename is the name of the version table. This table is used to record applied migrations
	// and must not be an empty string.
	Tablename() string

	// CreateVersionTable creates the version table, which is used to track migrations.
	CreateVersionTable(ctx context.Context, db DBTxConn) error

	// Insert a version id into the version table.
	Insert(ctx context.Context, db DBTxConn, req InsertRequest) error

	// Delete a version id from the version table.
	Delete(ctx context.Context, db DBTxConn, version int64) error

	// GetMigration retrieves a single migration by version id. If the query succeeds, but the
	// version is not found, this method must return [ErrVersionNotFound].
	GetMigration(ctx context.Context, db DBTxConn, version int64) (*GetMigrationResult, error)

	// GetLatestVersion retrieves the last applied migration version. If no migrations exist, this
	// method must return [ErrVersionNotFound].
	GetLatestVersion(ctx context.Context, db DBTxConn) (int64, error)

	// ListMigrations retrieves all migrations sorted in descending order by id or timestamp. If
	// there are no migrations, return empty slice with no error. Typically this method will return
	// at least one migration, because the initial version (0) is always inserted into the version
	// table when it is created.
	ListMigrations(ctx context.Context, db DBTxConn) ([]*ListMigrationsResult, error)
}
```

## Example

Although a bit of a contrived example, see this
[memory store](https://github.com/mfridman/goose-demo/blob/d5bb88465b4b270fa6190326945568f30a227b06/customstore/memory/memory.go)
for a reference implementation.
