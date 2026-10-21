# Workers and cron

Run code besides the web: a worker that runs all the time (a queue, a bot), or a cron entry that runs on a schedule (a nightly report), declared in the manifest.

An App's code runs as Processes on its machine. There is always one `web` Process, which answers HTTP. You can add others in [`basemodo.toml`](https://basemodo.com/docs/manifest), and they share the same machine, disk, database and Secrets.

## Workers

A worker runs continuously beside `web`, and is restarted if it stops.

```toml
[[worker]]
name = "mailer"
command = "node mailer.js"
```

Repeat `[[worker]]` for several. A worker keeps the App awake: an App with one never sleeps, so workers come with the Plans that allow Apps to stay on (see [Plans](https://basemodo.com/docs/plans)). A worker that stops is restarted after a pause that doubles each time (1 second up to a minute). One that keeps crashing (eight quick exits in a row) is left stopped and the App is paused: you are told why, `basemodo status` says `paused` with the reason, and the next Deploy resumes it. Each line a worker prints reaches the [Logs](https://basemodo.com/docs/cli/logs) with its name in front: `[mailer] sent 3 emails`.

Keys: [`worker.name`](https://basemodo.com/docs/manifest#worker.name), [`worker.command`](https://basemodo.com/docs/manifest#worker.command).

## Cron

A cron entry runs a command on a schedule.

```toml
[[cron]]
name = "nightly-report"
schedule = "0 3 * * *"
command = "node report.js"
timezone = "America/Bogota"
timeout = "5m"
```

- `schedule` has five fields: minute, hour, day of the month, month, day of the week. `0 3 * * *` is every day at 03:00; `*/15 * * * *` every 15 minutes; `0 9 * * 1` Mondays at 09:00.
- It is read in UTC unless you give a `timezone` (an IANA name, like `Europe/Madrid`).
- A run may take 15 minutes unless you give a `timeout` (`30s`, `5m`, `2h`; at most `24h`); then it is stopped.
- Runs never overlap: if the previous run is still going when the next is due, the next one is skipped (the Logs say so).
- A sleeping App is woken for its run.
- Each run's output and exit code go into the App's [Logs](https://basemodo.com/docs/cli/logs).
- On Pro and Workspace Plans, a run that fails or times out is tried again up to 3 times, after 1, 2 and 4 minutes; the Logs say when (see [Plans](https://basemodo.com/docs/plans#logs-backups-and-cron-retries)).

Repeat `[[cron]]` for several. Names must be unique among workers and cron entries, and cannot be `web`.

Keys: [`cron.schedule`](https://basemodo.com/docs/manifest#cron.schedule), [`cron.timezone`](https://basemodo.com/docs/manifest#cron.timezone), [`cron.timeout`](https://basemodo.com/docs/manifest#cron.timeout), and the rest on [the manifest's page](https://basemodo.com/docs/manifest).
