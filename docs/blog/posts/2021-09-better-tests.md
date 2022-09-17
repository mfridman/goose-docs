---
title: Better tests with containers
description: A container a test makes the bugs 🐛 go away.
date: 2021-09-17
authors: [mike]
categories: [Blog, Testing]
slug: better-tests
---

# Better tests with containers

Managing state is hard. Managing database state is even harder. And coordinating state within a test suite is just always a bad time.

But it doesn't have to be this way!

There is a fantastic Go package called [ory/dockertest](https://github.com/ory/dockertest) that allows you to spin up ephemeral docker containers. It'll work both locally (assuming you have Docker installed) and in your Continuous Integration (CI) pipelines.

<!-- more -->

After applying thousands of migrations in production we know `goose` is production-ready and does the right thing. But we have plans to add more functionality to `goose`, and integration tests are a welcome addition to the `goose` test-suie.

In a recent `goose` release ([PR#276](https://github.com/pressly/goose/pull/276)) we added container-based database tests. These tests spin up a fresh database *per test*. Yes, that's right, we're talking dozens of containers.

After each test is completed the container is cleaned up, something like this:

```go
t.Cleanup(func() {
	if err := pool.Purge(container); err != nil {
		log.Printf("failed to purge resource: %v", err)
	}
})
```

For integration tests this is perfect. We can spin up a fresh lightweight container for each test, such as `postgres:14-alpine`, and not worry about tests stomping on each other or having to coordinate state between tests.

The entire thing is fast! Where tests run in parallel using `t.Parallel()` and the entire integration test-suite run in about 6-7s (for `postgres:14-alpine`).

Check it out..

```
+--------+---------+----------------------------+---------+
| STATUS | ELAPSED |            TEST            | PACKAGE |
+--------+---------+----------------------------+---------+
| PASS   |    5.77 | TestMigrateOutOfOrderDown  | e2e     |
| PASS   |    5.54 | TestNowAllowMissingUpByOne | e2e     |
| PASS   |    5.28 | TestAllowMissingUp         | e2e     |
| PASS   |    4.60 | TestAllowMissingUpByOne    | e2e     |
| PASS   |    4.48 | TestNotAllowMissing        | e2e     |
| PASS   |    4.39 | TestMigrateUpTo            | e2e     |
| PASS   |    4.31 | TestMigrateUpByOne         | e2e     |
| PASS   |    3.69 | TestMigrateUp              | e2e     |
| PASS   |    2.30 | TestMigrateFull            | e2e     |
+--------+---------+----------------------------+---------+

+--------+---------+---------------------------------------+
| STATUS | ELAPSED |                PACKAGE                |
+--------+---------+---------------------------------------+
| PASS   | 6.12s   | github.com/pressly/goose/v3/tests/e2e |
+--------+---------+---------------------------------------+
```

So, next time you need a database in your containers
