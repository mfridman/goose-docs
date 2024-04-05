# Annotations

Annotations are comments that are placed in SQL migration files to provide additional information to
goose. They are used to parse SQL statements and optionally modify how migrations are executed.

To summarize, annotations are:

- Case-insensitive
- Placed on their own line (no leading whitespace)
- Prefixed with `-- +goose` (`^--\s\+goose\s.*$`)
- The only mandatory annotation is `-- +goose up`

There are currently seven annotations:

```sql
-- +goose up
-- +goose down
-- +goose statementbegin
-- +goose statementend
-- +goose no transaction
-- +goose envsub on
-- +goose envsub off
```

## Quick start

Here's a copy/pasteable example:

```sql
-- +goose up
SELECT 'up SQL query';

-- +goose down
SELECT 'down SQL query';
```

Important, annotations are captured as comments and cannot have leading spaces:

```sql
-- +goose up ✅

    -- +goose up ❌ (invalid, because leading whitespace)
```

## Basics

A SQL migration file must have a .sql extension and is prefixed with either a timestamp or a
sequential number. There is a handy `goose create` command to stub out migration files in a
consistent way.

Each SQL migration file is expected to have exactly one `-- +goose up` annotation.

The `-- +goose down` annotation is optional and **must** come after the `-- +goose up` annotation.

```sql
-- +goose up
SELECT 'up SQL query 1';
SELECT 'up SQL query 2';
SELECT 'up SQL query 3';

-- +goose down (1)
SELECT 'down SQL query 1';
SELECT 'down SQL query 2';
```

1.  The down annotation is optional, and may be omitted entirely if there are no down migrations.
    Within the `.sql` file it **must** come after the `-- +goose up` annotation.

    This is invalid:

    ```sql
    -- +goose down
    SELECT 'down SQL query';

    -- +goose up
    SELECT 'up SQL query';
    ```

## Complex statements

By default, SQL statements are split by semicolons (`;`) and executed individually -- in fact, query
statements **must** be separated by semicolons to be properly recognized by goose.

More complex statements, such as PL/pgSQL functions, typically have semicolons _within them_ and
must be wrapped with `-- +goose statementbegin` and `-- +goose statementend` annotations.

This pair of annotations tell goose to treat the entire block as a single statement. Comments, empty
lines, and semicolons within the block are preserved.

```sql hl_lines="3 26"
-- +goose up

-- +goose statementbegin
CREATE OR REPLACE FUNCTION histories_partition_creation( DATE, DATE )
returns void AS $$
DECLARE
  create_query text;
BEGIN
-- This comment will be preserved.
  -- And so will this one.
  FOR create_query IN SELECT
      'CREATE TABLE IF NOT EXISTS histories_'
      || TO_CHAR( d, 'YYYY_MM' )
      || ' ( CHECK( created_at >= timestamp '''
      || TO_CHAR( d, 'YYYY-MM-DD 00:00:00' )
      || ''' AND created_at < timestamp '''
      || TO_CHAR( d + INTERVAL '1 month', 'YYYY-MM-DD 00:00:00' )
      || ''' ) ) inherits ( histories );'
    FROM generate_series( $1, $2, '1 month' ) AS d
  LOOP
    EXECUTE create_query;
  END LOOP;  -- LOOP END
END;         -- FUNCTION END
$$
language plpgsql;
-- +goose statementend
```

## Multiple statements

The `-- +goose statementbegin` and `-- +goose statementend` annotations can also be used to combine
multiple statements so they get sent as a single query string instead of being executed
individually.

### Example

This is best illustrated with a contrived example. Suppose we have a migration that creates a users
table and adds 100,000 rows with distinct INSERT's.

```sql
-- +goose up
CREATE TABLE users (
    id int NOT NULL PRIMARY KEY,
    username text
);

-- (1)! Inserts:
INSERT INTO "users" ("id", "name") VALUES (1, 'gallant_almeida7');
INSERT INTO "users" ("id", "name") VALUES (2, 'brave_spence8');
.
.
INSERT INTO "users" ("id", "name") VALUES (99999, 'jovial_chaum1');
INSERT INTO "users" ("id", "name") VALUES (100000, 'goofy_ptolemy0');

-- +goose down
DROP TABLE users;
```

1.  This is a contrived example. Normally this would be a set of batched `INSERT`'s with multiple
    column values, each enclosed with parentheses and separated by commas, like so:

    ```sql
    INSERT INTO "users" ("id", "username")
    VALUES
      (1, 'gallant_almeida7'),
      (2, 'brave_spence8');
    ```

The up migration contains 100,001 unique statements, all **executed within the same transaction, but
sent to the database one-by-one**. This migration will take ~30s to complete due to the number of
round trips.

Using PostgreSQL as an example, here's what the database logs show:

```shell
LOG:  statement: INSERT INTO "users" ("id", "username") VALUES (1, 'gallant_almeida7');
LOG:  statement: INSERT INTO "users" ("id", "username") VALUES (2, 'brave_spence8');
LOG:  statement: INSERT INTO "users" ("id", "username") VALUES (3, 'lucid_bardeen6');
[...] 100,000 log statements
```

However, if we wrap the inserts with `-- +goose statementbegin` and `-- +goose statementend`
annotations, the entire block will be sent to the server as a single command.

A single command still contains several statements separated by semicolons, but they get sent to the
server in the same query string: `"INSERT INTO ...; INSERT INTO ...;"`.

```sql hl_lines="9 16"
-- +goose up
CREATE TABLE users (
    id int NOT NULL PRIMARY KEY,
    username text,
    name text,
    surname text
);

-- +goose statementbegin
INSERT INTO "users" ("id", "username") VALUES (1, 'gallant_almeida7');
INSERT INTO "users" ("id", "username") VALUES (2, 'brave_spence8');
.
.
INSERT INTO "users" ("id", "username") VALUES (99999, 'jovial_chaum1');
INSERT INTO "users" ("id", "username") VALUES (100000, 'goofy_ptolemy0');
-- +goose statementend

-- +goose down
DROP TABLE users;
```

These annotations instruct goose to execute the entire block as a single statement. Yes, that's a
larg*er* payload, but that's fine and the migration will execute in ~3s, which is an order of
magnitude faster as compared to the previous example that ran in ~30s.

## No transaction

All statements within a single migration file are run within the same transaction. However, some
statements, like `CREATE DATABASE` or `CREATE INDEX CONCURRENTLY`, cannot be run within a
transaction block.

For such cases add the `-- +goose no transaction` annotation, usually placed at the top of the file.

This annotation instructs goose to run all statements within the file outside a transaction. This
applies to all up and down statements within the file.

```sql hl_lines="1"
-- +goose no transaction

-- +goose up
CREATE INDEX CONCURRENTLY ON users (user_id);

-- +goose down
DROP INDEX users_user_id_idx;
```

## Environment variable substitution

Goose supports environment variable substitution in SQL migration files. This is useful for
parameterizing SQL queries with values that are not known at the time of writing the migration.

Substitution is **disabled by default**. To enable it, add the `-- +goose envsub on` annotation at
the location where you want to start substituting environment variables. This could be at the top of
the file, which enables substitution for the entire file, or at a specific location within the file.

goose will attempt to substitute environment variables until the end of the file, or until the
annotation `-- +goose envsub off` is found.

For example, if the environment variable `REGION` is set to `us_east_1`, the following SQL migration
will be substituted to `SELECT * FROM regions WHERE name = 'us_east_1';`.

```sql
-- +goose envsub on

-- +goose up
SELECT * FROM regions WHERE name = '${REGION}';
```

### Supported expansions

- **`${parameter}`** or **`$parameter`**
- **`${parameter:-[word]}`**
- **`${parameter-[word]}`**
- **`${parameter:[offset]}`**
- **`${parameter:[offset]:[length]}`**
- **`${parameter?[word]}`**
- **`${parameter:?[word]}`** (coming soon)

For an explanation of each expansion, refer to the
[mfridman/interpolate](https://github.com/mfridman/interpolate?tab=readme-ov-file#supported-expansions)
package. In due time, we'll update the documentation to reflect the supported expansions.
