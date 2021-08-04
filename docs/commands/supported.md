# Supported Commands

The following commands are part of the **stable set** of commands and will remain
backwards compatible across minor/patch upgrades.

## **up**               
Migrate the DB to the most recent version available

## **up-by-one**
Migrate the DB up by 1

## **up-to**
Migrate the DB to a specific VERSION

## **down**
Roll back the version by 1

## **down-to**
Roll back to a specific VERSION

## **redo**
Re-run the latest migration

## **reset**
Roll back all migrations

## **status**
Dump the migration status for the current DB

## **version**
Print the current version of the database

## **create**
Creates new migration file with the current timestamp

## **fix**
Apply sequential ordering to migrations
