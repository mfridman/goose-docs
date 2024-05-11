# Commands

The following commands are part of the **stable set** of commands and will remain backwards
compatible across minor/patch upgrades.

```shell
Usage: goose [flags] DRIVER DBSTRING <command>
```

Flags must come **before** commands, otherwise they will be interpreted as arguments to the command.

Both `DRIVER` and `DBSTRING` may be set using environment variables `GOOSE_DRIVER` and
`GOOSE_DBSTRING`. See the [environment variables](environment_variables.md) documentation for more
information.

## Commands

### **`up`**

Migrate the DB to the most recent version available

### **up-by-one**

Migrate the DB up by 1

### **up-to**

Migrate the DB to a specific VERSION

### **down**

Roll back the version by 1

### **down-to**

Roll back to a specific VERSION

### **redo**

Re-run the latest migration

### **reset**

Roll back all migrations

### **status**

Dump the migration status for the current DB

### **version**

Print the current version of the database

### **create**

Creates new migration file with the current timestamp

### **fix**

Apply sequential ordering to migrations

## Supported Drivers

| Driver       | Go package                                         |
| ------------ | -------------------------------------------------- |
| `clickhouse` | `github.com/ClickHouse/clickhouse-go/v2`           |
| `mssql`      | `github.com/microsoft/go-mssqldb`                  |
| `mysql`      | `github.com/go-sql-driver/mysql`                   |
| `postgres`   | `github.com/jackc/pgx/v5/stdlib`                   |
| `sqlite3`    | `modernc.org/sqlite`                               |
| `turso`      | `github.com/tursodatabase/libsql-client-go/libsql` |
| `vertica`    | `github.com/vertica/vertica-sql-go`                |
| `ydb`        | `github.com/yandex-cloud/ydb-go-sdk/v2`            |
