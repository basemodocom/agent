# Data: the disk, SQLite, db, run and Backups

Where your App keeps its data so it survives every Deploy and every sleep, the SQLite database every App already has, and how to query it or run a script where the data is.

## The disk

Every App has its own disk, mounted at `/data` (also in `$BASEMODO_DATA`). What your App writes there stays: through every Deploy, every sleep, every restart. Everything else on the machine is replaced at the next Deploy, so never keep data next to your code.

## The database

Every App has a SQLite database at `/data/app.db`, also in `$BASEMODO_DB`. There is nothing to provision or connect to: your App opens the file, and the first to open it creates it. SQLite is fast, needs no server, and is plenty for small software.

Node (22 and later have SQLite built in):

```js
import { DatabaseSync } from "node:sqlite";

const db = new DatabaseSync(process.env.BASEMODO_DB ?? "app.db");
db.exec("create table if not exists tasks (id integer primary key, title text, done integer default 0)");
const tasks = db.prepare("select * from tasks").all();
```

Python:

```python
import os
import sqlite3

db = sqlite3.connect(os.environ.get("BASEMODO_DB", "app.db"))
db.execute("create table if not exists tasks (id integer primary key, title text)")
```

Falling back to a local file name, as above, lets the same code run on your computer. With Django, point `DATABASES["default"]["NAME"]` at `os.environ.get("BASEMODO_DB")`.

## Looking at it: `basemodo db`

Run SQL against an App's database from your terminal, or let your agent do it with the `db` tool:

```sh
basemodo db "select * from tasks order by id desc limit 10"
basemodo db "update tasks set done = 1 where id = 7"
basemodo db < fix-titles.sql
```

It prints a table (or JSON with `--json`). Several statements run in order and stop at the first error. If the App is asleep, it is woken first. See [`basemodo db`](https://basemodo.com/docs/cli/db).

## Running a script: `basemodo run`

Run a one-off command inside the App's machine, where its disk, its database and its Secrets are: a migration, an import, a quick look around.

```sh
basemodo run "npm run migrate"
basemodo run python manage.py migrate
basemodo run -- ls -la /data
```

Its output comes back as it runs, and the command exits as the remote command did. It may run up to 60 seconds, or longer with `--timeout` (at most 15 minutes). See [`basemodo run`](https://basemodo.com/docs/cli/run).

Your agent has the same `run` tool, which answers within 45 seconds, before any agent's app gives up on it. A longer command keeps running: the agent gets what it printed so far and the command's id, and follows it with `runs` until it ends. While it runs, the agent's same command is refused, so it never runs twice; `basemodo runs <id>` waits for it in your terminal. See [`basemodo runs`](https://basemodo.com/docs/cli/runs).

Basemodo never runs migrations by itself when a Deploy starts: run them with `basemodo run` when you choose, so a bad migration never runs twice.

## Backups: `basemodo backup` and `basemodo restore`

Basemodo backs every App's data up once a day: the database and every file on its disk, kept 7 days (14 on Pro and Workspace, see [Plans](https://basemodo.com/docs/plans#logs-backups-and-cron-retries)), all of an App's Backups together within ten times its disk: past that, the oldest go first. On Pro and Workspace it also backs each App up every hour, each of those kept 24 hours: the App's Backups page shows them under Last 24 hours, and they restore like any other. Neither wakes an App that sleeps, and an App that has not run since its newest Backup gets no new one: nothing could have changed its data. That newest Backup is kept past its 7 or 14 days, until the App runs and is backed up again (or 13 days on, when Basemodo takes it anew), so an App asleep for weeks always has one to restore; `basemodo backups` says it is kept until the App's next Backup. Take one yourself before something risky, then put the data back if it goes wrong:

```sh
basemodo backup                  # prints the Backup's id
basemodo run "npm run migrate"
basemodo backups                 # the App's Backups, newest first
basemodo restore <backup>        # the data as it was when that Backup was taken
```

Restoring replaces everything written since the Backup; the Backup itself stays, and the App runs again afterwards. An App takes at most 10 Backups of its own in any 24 hours (Basemodo's daily ones are not counted); at that cap, `basemodo backup` says when the next one is allowed. Your agent has the same `backup`, `backups` and `restore` tools. See [`basemodo backup`](https://basemodo.com/docs/cli/backup) and [`basemodo restore`](https://basemodo.com/docs/cli/restore).

## Downloading your data

The App's Data Download is a `.tar.gz` of every file and folder on its disk as it is now (links and other special files are left out), with the database copied by SQLite's own online backup, so it is consistent even while the App writes to it. Open `data/app.db` with any SQLite tool. Only the App's Owner downloads it: from a terminal, or by asking your agent, which has the same `download` tool, it lands as `<app>-data-<date>.tar.gz` in the folder you are in:

```sh
basemodo download                     # lunch-rota-data-2026-10-20.tar.gz, here
basemodo download --out ~/backups     # or in a folder of your copies
```

On the App's Backups page on basemodo.com, **Download the data** gives the same file; an agent connected through the Remote MCP, which has no folder of yours, answers that page's link. A Backup is not downloaded: it is restored. See [`basemodo download`](https://basemodo.com/docs/cli/download).

An App paused because your Plan ended can still be downloaded, for the 30 days its data is kept: Basemodo starts it for the download alone, and it stays paused, so leaving never needs another payment. So can an App paused because its [Security Update](https://basemodo.com/docs/deploying#security-updates) did not build in time, for as long as it is paused: it stays paused until you deploy a version that builds. An App paused for a review, or whose account is suspended, cannot be downloaded until the review ends.

## Deleting an App

Deleting an App (on its page, by its Owner) stops it at once, and its address stops answering. Its last Backup is kept for 7 days (14 on Pro and Workspace): `basemodo restore <backup>` with the id the page shows brings the App back as it was. After that its data is gone for good and its address is free for someone else.
