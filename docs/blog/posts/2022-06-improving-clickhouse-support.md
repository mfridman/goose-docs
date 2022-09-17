---
title: Improving ClickHouse support
description: goose improves ClickHouse support. Bug fixes, improvements, full end-end tests and upgrade to ClickHouse/clickhouse-go v2 driver.
date: 2022-06-19
authors: [mike]
categories: [Blog, ClickHouse]
slug: improving-clickhouse
---

# Improving ClickHouse support

[ClickHouse](https://clickhouse.com/) is a an open-source column-oriented database that is well-suited for analytical workloads. Over the past few years we've seen more and more demand for improved ClickHouse support in goose.

To summarize:

- Upgraded to the latest `/v2` driver: [ClickHouse/clickhouse-go](https://github.com/ClickHouse/clickhouse-go)
- Full end-end tests against the docker image: [clickhouse/clickhouse-server](https://hub.docker.com/r/clickhouse/clickhouse-server/)
- Bug fixes and improvements

!!! danger ""

    The `/v2` driver [changed the DSN format](https://github.com/ClickHouse/clickhouse-go/issues/525), so be prepared for a breaking change. This is actually a good thing, because it brings the format in-line with other databases.

<!-- more -->

---

## Getting started

Here's a quick tour of using goose against a running ClickHouse docker container.

```bash
docker run --rm -d \
    -e CLICKHOUSE_DB=clickdb \
    -e CLICKHOUSE_USER=clickuser \
    -e CLICKHOUSE_DEFAULT_ACCESS_MANAGEMENT=1 \
    -e CLICKHOUSE_PASSWORD=password1 \
    -p 9000:9000/tcp clickhouse/clickhouse-server:22-alpine
```

Once the container is running, we'll apply 3 migrations with goose. For the sake of this demo, we're using migrations from [pressly/goose](http://github.com/pressly/goose) repository.


At the time of this writing, goose supports 3 environment variables:

    GOOSE_DRIVER
    GOOSE_DBSTRING
    GOOSE_MIGRATION_DIR

We use them in the following command for convenience. Otherwise you'll need to set the driver and database connection strings as CLI parameters and the migration directory with the `-dir` flag.

```bash
GOOSE_DRIVER=clickhouse \
    GOOSE_DBSTRING="tcp://clickuser:password1@localhost:9000/clickdb" \
    GOOSE_MIGRATION_DIR="tests/clickhouse/testdata/migrations" \
    goose up
```

Expected output following a successful migration.

```
2022/06/19 20:19:04 OK    00001_a.sql
2022/06/19 20:19:04 OK    00002_b.sql
2022/06/19 20:19:04 OK    00003_c.sql
2022/06/19 20:19:04 goose: no migrations to run. current version: 3
```

---

## Check migrations

We can now use the [`clickhouse-client`](https://clickhouse.com/docs/en/interfaces/cli) to poke around the server:

### **Show tables**

```bash
clickhouse-client --vertical \
    --database clickdb --password password1 -u clickuser \
    -q 'SHOW TABLES'
```

Our migrations created the `goose_db_version` table, which stores migration data, and 2 new user tables: `clickstream` and `trips`.

```
Row 1:
──────
name: clickstream

Row 2:
──────
name: goose_db_version

Row 3:
──────
name: trips
```

### **Show all data from `clickstream` table**

We used the sample data from the [Getting Started with ClickHouse tutorial](https://clickhouse.com/learn/lessons/gettingstarted/).


```bash
clickhouse-client --vertical \
    --database clickdb --password password1 -u clickuser \
    -q 'SELECT * FROM clickstream'
```

Output:

```
Row 1:
──────
customer_id:      customer3
time_stamp:       2021-11-07
click_event_type: checkout
country_code:     
source_id:        307493

Row 2:
──────
customer_id:      customer2
time_stamp:       2021-10-30
click_event_type: remove_from_cart
country_code:     
source_id:        0

Row 3:
──────
customer_id:      customer1
time_stamp:       2021-10-02
click_event_type: add_to_cart
country_code:     US
source_id:        568239
```
