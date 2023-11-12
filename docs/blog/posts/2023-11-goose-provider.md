---
title: Adding a goose provider
description: Introduction to the new goose provider
date: 2023-11-11
authors: [mfridman]
categories: [Blog, Package]
slug: goose-provider
---

# Adding a goose provider

## Introduction

In this post, we'll explore the new `Provider` feature recently added to the core goose package. If
you're new to goose, it's a tool for handling database migrations, available as a standalone CLI
tool and a package that can be used in Go applications.

Requires version **[v3.16.0](https://github.com/pressly/goose/releases/tag/v3.16.0)** and above.

Adding a provider to your application is easy, here's a quick example:

```go
provider, err := goose.NewProvider(
  goose.DialectPostgres, // (1)!
  db, // (2)!
  os.DirFS("migrations"), // (3)!
)

results, err := provider.Up(ctx) // (4)!
```

1.  The first argument is the dialect. It is the type of database technology you're using. In this
    case, we're using Postgres. But goose also supports:

    clickhouse, mssql, mysql, postgres, redshift, sqlite3, tidb, vertica, ydb,

2.  The second argument is the database connection. You can use any database driver you want, as
    long as it implements the `database/sql` interface.

    A popular choice for Postgres is [pgx/v5](https://pkg.go.dev/github.com/jackc/pgx/v5)

3.  The last argument may be `nil`. Why? Because goose also supports the ability to register Go
    functions as migrations.

    However, in most cases, you'll be using SQL migrations and reading them from disk. In this case,
    you'll use [os.DirFS](https://pkg.go.dev/os#DirFS) or embed them into your binary and use
    [embed.FS](https://pkg.go.dev/embed#FS).

4.  The last step is to invoke one of the migration methods. In this case, we're running the `Up`
    method, which will run all the migrations that haven't been run yet. Here's a list of all the
    methods:

    ```go
      (p *Provider) ApplyVersion
      (p *Provider) Close
      (p *Provider) Down
      (p *Provider) DownTo
      (p *Provider) GetDBVersion
      (p *Provider) ListSources
      (p *Provider) Ping
      (p *Provider) Status
      (p *Provider) Up
      (p *Provider) UpByOne
      (p *Provider) UpTo
    ```

<!-- more -->

All functionality is scoped to the `Provider` instance. This means that you can create multiple of
them, each with their own configuration.

Here's some options you can pass to the `NewProvider` method:

| Option                    | Description                                                      |
| ------------------------- | ---------------------------------------------------------------- |
| **WithGoMigrations**      | Register Go functions as migrations directly within the provider |
| **WithSessionLocker**     | Lock database to prevent concurrent migrations                   |
| **WithStore**             | Bring your own store implementation                              |
| **WithExclude**           | Exclude migrations by name or version                            |
| **WithAllowOutofOrder**   | Allow migrations to be run out of order                          |
| **WithDisableVersioning** | Disable versioning, useful for testing and seeding data          |

... and more!

## Backwards compatibility

Although we're adding a new feature, **we're not removing any existing functionality in the /v3
package** and the `Provider` is fully backwards compatible. This means that you can continue to use
goose as you always have and migrate at your own pace. Do note, however, that the `Provider` will be
the recommended way to use goose and we'll be focusing our efforts on it going forward.

For all the limitations mentioned below, the goose package was (and still is) a great tool and we're
grateful for all the contributions and feedback from the community. We hope that the `Provider` will
compliment the existing functionality and make goose even better.

## Motivation

The motivation behind the `Provider` was simple - **to reduce global state and make goose easier to
consume as an imported package.**

Here's a quick summary:

- Avoid global state
- Make `Provider` safe to use concurrently
- Unlock (no pun intended) new features, such as database locking
- Make logging configurable
- Better error handling with proper return values
- Double down on Go migrations

---

#### Global state

Some of the functionality mentioned above was not possible, or if it was, would lead to an awkward
API. The reason is because goose used global state to store the configuration. This meant that you
could only have one configuration at a time, which was fine for the CLI, but not ideal as a package.

As an aside, if you're interested in the topic, Peter Bourgon had a nice post about
[global state](https://peter.bourgon.org/blog/2017/06/09/theory-of-modern-go.html)

> tl;dr: magic is bad; global state is magic → no package level vars; no func init

As time went on, goose became more popular and people started using it in more complex ways. For
example, they wanted to run parallel tests or run migrations against multiple databases. This made
the package unsafe to use, because global state would be overwritten by concurrent calls.

By using the `Provider`, we can scope all functionality to the instance and make it safe to use
concurrently. This means that you can create multiple providers, each with their own configuration.

#### Database locking

Another limitation is all commands, such as `goose.Up` and `goose.Down`, would take `*sql.DB` as the
database connection. This made it challenging to implement more advanced features, such as database
locking.

We'll save the details for another post, but the gist is that for most databases you need to use a
`*sql.Conn` to lock the database, and, most importantly, **use the same connection to unlock it**.

Some users got clever and worked around this limitation by using a wrapper that handled locking or
even more
[:simple-github: exotic solutions](https://github.com/pressly/goose/issues/191#issuecomment-1129850138),
such as setting the max number of connections to 1.

But this was not ideal.

With the `Provider`, you can now pass in a `SessionLocker` option which can be used to lock the
database. The only implementation supported right now is for Postgres, but we plan to add support
for other databases as requested. Here's a quick example:

```go
sessionLocker, err := lock.NewPostgresSessionLocker(
  // Timeout after 30min. Try every 15s up to 120 times.
	lock.WithLockTimeout(15, 120),
)

provider, err := goose.NewProvider(
	goose.DialectPostgres,
	db,
	os.DirFS("migrations"),
	goose.WithSessionLocker(sessionLocker), // Use session-level advisory lock.
)
```

Kudos to [@roblaszczak](https://twitter.com/roblaszczak) for the idea to support a
[custom locker interface](https://github.com/pressly/goose/pull/575).

If you've been following
[:simple-github: _Add locking mechanism to prevent parallel execution_](https://github.com/pressly/goose/issues/335)
issue, there's a bit to unpack. We'll save the details for another post.

#### Logging

There was too much logging from within the package. This made it difficult to integrate goose into
existing applications, because it would pollute the logs. We still want to have some logging, but we
want to make it configurable.

#### Error handling and return values

This is a big one. There was no way to get the results of a migration because all success and
failure states were logged _from within the package_.

With the provider, all methods return a well-defined type, which includes the results of the
migration and any errors that occurred. For example, here's the `Up` method:

```go
func (p *Provider) Up(ctx context.Context) ([]*MigrationResult, error) {
```

Notice that it returns a slice of `*MigrationResult` and an error.

By having a well-defined return value, we can also improve the CLI output and control the formatting
of the results (such as adding JSON support), as opposed to logging them directly in the goose
package through the `Logger`.

Lastly, we can handle errors in a more graceful way. Due to the nature of migrations, it's possible
that a migration may fail part way through, and we want to know exactly what state we're in. What
was the last migration that was run? What was the error? What was the migration that failed?

This is now possible because all provider methods return a `PartialError`.

#### Go migrations

Previously, all Go migrations had to be registered globally. This meant that you could only have one
set of Go migrations per application.

Now, you can register Go migrations directly with the provider, which means you can have multiple
providers, each with their own set of Go migrations. Here's a quick example:

```go
register := []*goose.Migration{
	goose.NewGoMigration(
		1,
		&goose.GoFunc{RunTx: newTxFn("CREATE TABLE users (id INTEGER)")},
		&goose.GoFunc{RunTx: newTxFn("DROP TABLE users")},
	),
}
provider, err := goose.NewProvider(goose.DialectSQLite3, db, nil,
	goose.WithGoMigrations(register...),
)
```

The goose provider will automatically register Go migrations and return any conflicts that may
occur. This means that you can mix and match SQL and Go migrations, as long as they don't conflict
with each other by having the same version.

## Conclusion

The `Provider` is a solid foundation that we can build upon and add new features. We're excited to
see how people will use it and what new ideas they'll come up with

If you have any questions or feedback, feel free to reach out on Twitter
[@\_mfridman](https://twitter.com/_mfridman) or file an issue on
[:simple-github: pressly/goose](https://github.com/pressly/goose).

ps. It's also an example of how to use functional options in Go, despite their controversial nature.
I personally like them, but I can see why some people don't. Here's a great talk by
[@jub0bs](https://twitter.com/jub0bs) on the topic:

[![Functional Options in
Go](https://img.youtube.com/vi/5uM6z7RnReE/0.jpg)](https://youtu.be/5uM6z7RnReE)

## Acknowledgments

This feature would not have been possible without all the contributions from the community. A
special thanks to everyone who opened an issue, submitted a PR, or helped with the design.

Special thanks to [@oliverpool](https://github.com/oliverpool) for pitching ideas and working
through the design around the `fs.FS` interface. I'm quite happy with how it turned out and I think
it's a great example of how to use the new `fs.FS` interface.
