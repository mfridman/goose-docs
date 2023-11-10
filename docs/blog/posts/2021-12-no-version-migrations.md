---
title: Ad-hoc migrations with no versioning
description: Database seeding. Apply migrations with no versioning.
date: 2021-12-19
authors: [mfridman]
categories: [Blog, General]
slug: no-version-migrations
---

# Ad-hoc migrations with no versioning

This post describes a new feature recently added to `goose` -- the ability to apply migrations with
**no versioning**. A common use case is to seed a database with data _after_ versioned migrations
have been applied.

<!-- more -->

If you think of versioned migrations as the blueprint for a house (the schema), then unversioned
migrations are like the furnishings inside (the data).

A GitHub user [@soggycactus](https://github.com/soggycactus) stated the problem well
([#235 comment](https://github.com/pressly/goose/issues/259#issue-956845240)):

> ... I always find myself creating some sort of wrapper that allows me to use goose to seed my
> local and development environments with test data

### Brief Summary

- keep versioned migrations in a dedicated directory (e.g., ./schema/migrations)
- continue running `goose` commands like normal: `goose -dir ./schema/migrations up`
- add unversioned migrations to a different directory (e.g., ./schema/seed)
- run `goose` commands with `-no-versioning` flag using seed directory

By adding `-no-versioning` flag (CLI) or supplying `WithNoVersioning()` option (library), we
instruct `goose` to apply migrations but to ignore tracking the version in the database schema
table.

---

### But why?

A common use case is to seed an environment with data, such as local development environment or
integration tests. Because we don't want this data to be applied to production, we keep it separate
from the versioned migrations in a different directory.

**Seed data**: think many `INSERT INTO` statements in up migrations and `DELETE FROM` or `TRUNCATE`
in down migrations.

- new developer joins, spins up a database, applies versioned migrations but requires "seed" data to
  get started
- integration or end-end tests that rely on pre-existing data. It's common to have your application
  create data, but sometimes you just want data to be there for external tests not involving your
  API
- optimizing delicate queries on a database with pre-populated data. Avoid writing queries against
  an empty database

!!! info ""

    Remember, if your application does requires some static, pre-existing data, then just insert it along with your regular versioned schema migrations.

### Example

Seeding integration tests and wiping data, without having to reset the database schema.

Let's use an example:

```bash
.
└── schema
    ├── migrations
    │   ├── 00001_add_users_table.sql
    │   ├── 00002_add_posts_table.sql
    │   └── 00003_alter_users_table.sql
    └── seed
        ├── 00001_seed_users_table.sql
        └── 00002_seed_posts_table.sql
```

Running the following command creates the desired shape of the database:

    goose -dir ./schema/migrations up

Assuming you're using the default goose table name `goose_db_version` then querying this table will
return 3 versioned migrations.

Now, suppose we want to run integration tests against a database that contains pre-populated data.
Running the following command applies two migrations but **it does not track their version in the
database**.

    goose -dir ./schema/seed -no-versioning up

---

If you run the initial command again:

    goose -dir ./schema/migrations up

`goose` will output _"no new migrations found"_. Because `goose` knows we already applied 3
migrations, so no further work to do.

But, if you run the second command again:

    goose -dir ./schema/seed -no-versioning up

`goose` doesn't know about unversioned migrations (due to the `-no-versioning` flag) so it will
apply the seed migrations once again. Depending how you wrote the migrations, this may or may not
succeed.

---

Lastly, we're done with our integration test. The neat thing with the `-no-versioning` flag is it
enables you to wipe the data without having to migrate the entire database down and up again.

Running the following command will apply the down migrations in your seed files, in reverse order:

    goose -dir ./schema/seed -no-versioning down-to 0
    # or
    goose -dir ./schema/seed -no-versioning reset

These two commands are the same--applying all down migrations starting from the highest to the
lowest numbered migration files in the schema directory.

### Final Thoughts

With the `-no-versioning` flag (CLI) or `WithNoVersioning()` option (library) you now have the
ability to apply arbitrary SQL statements to the database.

Just remember, these operations are not tracked (versioned) and are intended to be used in
development/testing environments.
