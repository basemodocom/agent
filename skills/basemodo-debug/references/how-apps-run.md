# How Apps run

What an App is on Basemodo: one machine with its own disk, the port it must answer on, how it sleeps and wakes, and what it may reach.

## One App, one machine

Every App runs on its own machine (a small virtual machine), with its own disk at `/data`. Its Processes share the machine: `web`, which answers HTTP, and any [workers and cron entries](https://basemodo.com/docs/workers-and-cron) you declare. No other App runs on it, and Apps cannot reach each other.

Basemodo gives every Process these environment variables, besides your [Secrets](https://basemodo.com/docs/secrets):

| Variable | What it holds |
| --- | --- |
| `PORT` | The port the `web` Process must listen on. |
| `BASEMODO_DATA` | `/data`, the App's disk: what is written there survives every Deploy. |
| `BASEMODO_DB` | `/data/app.db`, the App's [SQLite database](https://basemodo.com/docs/data). |
| `BASEMODO_JWT_PUBLIC_KEY` | The key to verify [the identity token](https://basemodo.com/docs/identity) with. |

Processes, and commands run with [`basemodo run`](https://basemodo.com/docs/cli/run) and [`basemodo db`](https://basemodo.com/docs/data), run as your image's own `USER`, or, when the image runs as root (every image Basemodo builds), as an unprivileged user of Basemodo's (uid 10000). That user owns `/data` (and, in images Basemodo builds, the App's folder) and may write in `/tmp`; it may listen on any port, 80 too. If your own `Dockerfile` writes elsewhere while it runs, give what it writes to its `USER` (`COPY --chown`, `RUN chown`), or set `USER` to the user that owns it: a Process denied permission gets a line in the Logs that says so. One exception: your own `Dockerfile` with no [`web.command`](https://basemodo.com/docs/manifest#web.command) runs as it is, so with no `USER` (or `USER root`) it runs as root, and so do `basemodo run` and `basemodo db`. That root is root in the App's own sandbox only, but set a `USER` anyway.

The rest of the machine's filesystem, `/tmp` with it, is writable too, up to 4 GB on every Plan. What your App writes outside `/data` is kept while it sleeps or restarts, but each Deploy starts it afresh, and it is never backed up. Past 4 GB a write there fails with "No space left on device" (`ENOSPC`) in your App, and nothing else is affected. Keep what must last in `/data`.

## The Port Contract

The `web` Process must listen on the port in `$PORT`, on every interface (`0.0.0.0`, not `localhost`), and answer HTTP. Its first answer, whatever it is, within 60 seconds of starting means the App is ready, and only then does a Deploy go live. There is nothing else to configure: no health check, no exposed port.

Apps Basemodo detects keep this contract by themselves. If you start your App yourself (with [`web.command`](https://basemodo.com/docs/manifest#web.command) or your own `Dockerfile`), read the port from the environment, as in `app.listen(process.env.PORT ?? 3000, "0.0.0.0")`. `EXPOSE` in a Dockerfile does not change the port. An App that never answers fails its Deploy with [`not_ready`](https://basemodo.com/docs/errors#not_ready).

## Sleep and wake

An App nobody uses for 10 minutes falls asleep: its machine stops, its disk stays, and it costs nothing. The next visit wakes it: Basemodo holds that request for the few seconds the App takes to start, then passes it on. Nobody sees an error. Only requests that get in count as use, so strangers hitting the sign-in page of a Private App never keep it awake, but a webhook on a [Public Path](https://basemodo.com/docs/public-paths) does wake it.

[`basemodo status`](https://basemodo.com/docs/cli/status) says whether an App is awake, asleep or starting, or paused: stopped by Basemodo because a [worker](https://basemodo.com/docs/workers-and-cron) kept crashing (or by its Plan), with the reason, until it is deployed again or restarted. A worker keeps an App awake.

[`basemodo restart`](https://basemodo.com/docs/cli/restart) starts an App's machine again on its live Deploy, without building: use it to apply [Secrets](https://basemodo.com/docs/secrets) you just set (every start reads them, waking from sleep included), or to resume an App paused because a worker kept crashing or ran out of memory or disk once you fixed the cause. An App paused until its Owner chooses a Plan, for review, or until a version that builds is deployed after its [Security Update](https://basemodo.com/docs/deploying#security-updates) failed, stays paused.

## Logs

What your Processes print (stdout and stderr) and what each build prints are kept as the App's Logs for 7 days, up to 100 MB of lines a day, 200 MB on Pro and Workspace ([Plans](https://basemodo.com/docs/plans)): past that, no more lines are kept until the day ends (UTC), and the Logs say so in one line, with when they are kept again. A line longer than 8 KB is cut. Each line of a Process names it (`web`, `mailer`), and so does each of Basemodo's lines about it (a crash, a restart, a cron run); Basemodo's lines about no Process name `basemodo`. Follow them live with [`basemodo logs`](https://basemodo.com/docs/cli/logs), or see the latest on the App's page. Show one Process's lines, with Basemodo's about it, with `basemodo logs --process mailer` or the Process selector of the Logs page, and only the builds' with `--source build` or its Source selector.
Read back through all that is kept with `basemodo logs --before <cursor>` (the `older_cursor` of an earlier `--json` answer), or with **Load older lines** on the App's Logs page.
Search all that is kept for a piece of text, in any letter case, with `basemodo logs --search timeout` or the search box on the Logs page: the newest matches come first, and older ones with `--before` or **Load older lines**.

## The network

- **In**: only through Basemodo. Every request reaches the App through Basemodo's gate, which signs visitors in, applies the App's [Visibility](https://basemodo.com/docs/sharing), adds the [identity headers](https://basemodo.com/docs/identity) and limits floods. The machine has no public address of its own.
- **Out**: open by default, so your App can call any API. Basemodo blocks itself (basemodo.com and its internal networks), the provider's metadata service, private network ranges, other Apps' machines (call another App at its URL instead) and outgoing email over SMTP ports 25, 465 and 587 (send email through an email API instead). Apps a Workspace owns can be limited to a list of hosts with [`network.allow`](https://basemodo.com/docs/manifest#network.allow); the blocks still apply to the hosts listed. A personal App's Deploy with `network.allow` is refused, since the allowlist comes with the [Workspace plan](https://basemodo.com/docs/plans). The App's names are resolved by Basemodo inside its machine: names it may not reach are refused there, and other DNS servers are not reachable.

## Addresses and search engines

Apps answer at `https://<name>.basemodo.app`, a domain apart from basemodo.com. Paths under `/.basemodo/` belong to Basemodo (the sign-in) and never reach your App. Apps are never indexed by search engines unless a Public App asks to be (see [Sharing](https://basemodo.com/docs/sharing#search-engines)).
