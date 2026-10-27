# The manifest: basemodo.toml

Every key of `basemodo.toml`, the optional file that names your App and says what detection cannot know: its start command, runtime versions, workers, cron entries, Public Paths and the paths it exposes to its Callers.

Most Apps need no manifest: Basemodo detects how to build and run the folder (see [Supported runtimes](https://basemodo.com/docs/runtimes)). Add a `basemodo.toml` at the top of the folder only for the exceptions. It is [TOML](https://toml.io), and every key is optional.

```toml
name = "lunch-rota"

[web]
command = "node server.js"
```

- **Strict.** A key Basemodo does not know, or a wrong value, stops the Deploy before anything is built, with the error [`invalid_manifest`](https://basemodo.com/docs/errors#invalid_manifest) naming the key, its line, and the fix. A typo never goes unnoticed.
- **On top of detection.** What the manifest changes in the detected plan is listed as an override, with its line, next to the detection's explanation, so you always see why your App is built the way it is.
- **With your own Dockerfile**, `web.command` replaces the image's command, and `[build]` versions are refused: the Dockerfile's `FROM` line chooses the runtime.

## Every key at once

No App needs all of these; this is every key `basemodo.toml` accepts, each explained below.

```toml
name = "lunch-rota"
public_paths = ["/webhooks/stripe", "/hooks/*"]

[web]
command = "node server.js"
indexable = true
toolbar = false

[build]
node = "22"
python = "3.12"

[[worker]]
name = "mailer"
command = "node mailer.js"

[[cron]]
name = "nightly-report"
schedule = "0 3 * * *"
command = "node report.js"
timezone = "America/Bogota"
timeout = "15m"

[network]
allow = ["api.stripe.com", "*.trello.com"]

[callers]
paths = ["/api/*", "/health"]
```

## Keys

### `name`

The App's name: `basemodo deploy` deploys to the App of this name.

```toml
name = "lunch-rota"
```

### `public_paths`

Paths that bypass sign-in, for webhooks, under stricter rate and size limits; `/*` at the end opens every path under it. A Deploy that adds or widens one is the Owner's, with `--allow-public`.

```toml
public_paths = ["/webhooks/stripe", "/hooks/*"]
```

### `web`

The web Process, which answers HTTP.

```toml
[web]
```

### `web.command`

Starts the web Process instead of the detected start command; it must listen on $PORT.

```toml
[web]
command = "node server.js"
```

### `web.indexable`

Lets search engines index the App; only while its Visibility is Public.

```toml
[web]
indexable = true
```

### `web.toolbar`

Turns off the Toolbar Basemodo shows signed-in visitors on the App's pages (`true` turns it back on); without it, the App keeps the setting it has.

```toml
[web]
toolbar = false
```

### `build`

Runtime versions, one key per runtime.

```toml
[build]
```

### `build.node`

The Node.js version, instead of the detected one.

```toml
[build]
node = "22"
```

### `build.python`

The Python version, instead of the detected one.

```toml
[build]
python = "3.12"
```

### `worker`

A Process that runs continuously beside web, in the same Machine; repeatable.

```toml
[[worker]]
```

### `worker.name`

The worker's name, in logs.

```toml
[[worker]]
name = "mailer"
```

### `worker.command`

How the worker starts.

```toml
[[worker]]
command = "node mailer.js"
```

### `cron`

A Process run on a schedule; repeatable.

```toml
[[cron]]
```

### `cron.name`

The entry's name, in logs.

```toml
[[cron]]
name = "nightly-report"
```

### `cron.schedule`

Five fields: minute hour day-of-month month day-of-week.

```toml
[[cron]]
schedule = "0 3 * * *"
```

### `cron.command`

What runs.

```toml
[[cron]]
command = "node report.js"
```

### `cron.timezone`

The time zone the schedule is read in; default UTC.

```toml
[[cron]]
timezone = "America/Bogota"
```

### `cron.timeout`

How long a run may take before it is killed; default 15m, at most 24h.

```toml
[[cron]]
timeout = "15m"
```

### `network`

Outbound network rules (Workspace Apps only).

```toml
[network]
```

### `network.allow`

The only hosts the App may reach (`*.` for every subdomain); what Basemodo always blocks stays blocked.

```toml
[network]
allow = ["api.stripe.com", "*.trello.com"]
```

### `callers`

What the App's Callers, the other Apps of its Owner named to call it, may reach.

```toml
[callers]
```

### `callers.paths`

The paths the App's Callers may reach, matched as `public_paths` are (`/*` at the end for every path under it); nothing else is reachable to them, and without any, naming a Caller opens nothing. A Deploy that adds or widens one is the Owner's, with `--allow-public`.

```toml
[callers]
paths = ["/api/*", "/health"]
```
