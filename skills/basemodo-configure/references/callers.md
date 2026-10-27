# Callers: one of your Apps calls another

Let one of your Apps call another's API without a token: name it a Caller of the other App, and declare the paths the other App exposes to its Callers.

Say you have a CRM App and a reports App, both yours (or both your Workspace's). The reports App needs the CRM's data. Without Callers, the CRM's API asks for a sign-in no App can give. With them, the CRM names the reports App as one of its Callers, and exposes its API paths to them; the reports App then calls those paths as itself, holding no credential at all.

## Naming a Caller

From the folder of the App to be called (or with `--app`):

```sh
basemodo callers add reports --app crm
```

Or on basemodo.com: open the App to be called, then **Sharing → Callers**, choose the calling App among the Owner's other Apps, and press **Name Caller**.

Nothing is a Caller until someone names it: no App can call another by default. Who may name one:

- the called App's Owner (for a Workspace's App, its Admins);
- one of the called App's [Editors](https://basemodo.com/docs/roles).

A Member who is not an Editor is refused. Both Apps must have the **same Owner**: a person's two Apps, or two Apps of one Workspace. An App of another Owner is refused with [`caller_of_another_owner`](https://basemodo.com/docs/errors#caller_of_another_owner); Apps of different Owners call each other through a [Public Path](https://basemodo.com/docs/public-paths) with an API key of their own, kept as a [Secret](https://basemodo.com/docs/secrets) on each side: [Expose an API to another Owner's App](https://basemodo.com/docs/expose-an-api) shows how.

## Exposing paths to Callers

Naming a Caller alone opens nothing. The called App declares which of its paths its Callers may reach, in its `basemodo.toml`, with [`[callers] paths`](https://basemodo.com/docs/manifest#callers.paths):

```toml
[callers]
paths = ["/api/*", "/health"]
```

They are matched exactly as Public Paths are: `/health` is that path only, and `/api/*` every path under `/api/`. A path with `.` or `..` segments, an empty segment, a backslash or an encoded `/` never matches. Anything else, the App's pages and admin routes included, stays closed to its Callers. The paths take effect with the Deploy that declares them, and close with the first Deploy that drops them. The App's Callers page on basemodo.com shows them, at the address its Callers call; they change only in `basemodo.toml`, as [Public Paths](https://basemodo.com/docs/public-paths) do.

## Seeing and taking off Callers

```sh
basemodo callers list --app crm
basemodo callers remove reports --app crm
```

`callers list` shows each Caller with who named it and when, the paths the App exposes to them, and the latest changes. Every change is recorded with who made it. The App's Callers page on basemodo.com shows the same, and takes a Caller off with **Take off**, after asking; only the App's Owner and its Editors have that page.

A Caller stays one until:

- someone takes it off with `basemodo callers remove`;
- either App is deleted (an App made later with the same name is no Caller);
- a Transfer leaves the two Apps with different Owners: moving either App into a Workspace, or giving it to another person.

A Caller a Transfer took off is told to the called App's Owner (its Admins, for a Workspace's App) in their notifications on basemodo.com, not by email, and its change says why (`crm moved into Acme`). It does not come back if the two Apps share an Owner again later: name it again then.

Renaming either App keeps it a Caller.

## Calling the other App

The calling App's server code calls the other App at its internal address, `http://<slug>.apps.internal`, where `<slug>` is the called App's slug, the label of its URL (`crm` for `crm.basemodo.app`; after a Rename, its new one):

```ts
const res = await fetch("http://crm.apps.internal/api/contacts");
const contacts = await res.json();
```

Plain HTTP, no token, no API key. The address answers only inside the calling App's Machine: never in a browser, and never from outside Basemodo. The Host the Machine runs on knows which App every request there comes from, because it comes from that App's own Machine, and vouches for it to Basemodo's gate; any `x-basemodo-*` header the calling App sets is dropped on the way, so an App can only ever call as itself. An [allowlist](https://basemodo.com/docs/manifest#network.allow) does not close the address: who may call an App is for that App to say, with its Callers and exposed paths.

## How a call works

Basemodo lets a call through only to the exposed paths, and tells the called App who is calling in the `x-basemodo-caller` header (the calling App's slug). A Caller's request never carries a visitor's identity headers, and a visitor's request never carries `x-basemodo-caller`: Basemodo removes it from every request that comes from outside. A Caller's `X-Forwarded-For` is the calling App's internal address, its Machine's, which may change with each Deploy: tell Callers apart by `x-basemodo-caller`, never by address.

A call wakes the called App if it sleeps, as a visitor's request does, and shows in its [Logs](https://basemodo.com/docs/cli/logs) with the Caller's name: `[basemodo] Caller reports called GET /api/contacts`. A call Basemodo refuses never reaches the called App, and answers JSON with a stable code and the fix:

- [`not_a_caller`](https://basemodo.com/docs/errors#not_a_caller): the calling App is not named (or was taken off); the fix is the `basemodo callers add` that names it.
- [`path_not_exposed`](https://basemodo.com/docs/errors#path_not_exposed): the path is not in the called App's `[callers] paths`.
- [`caller_of_another_owner`](https://basemodo.com/docs/errors#caller_of_another_owner): the Apps have different Owners; use a Public Path instead.
- [`not_an_app_address`](https://basemodo.com/docs/errors#not_an_app_address): the call named no App; call `http://<slug>.apps.internal`, not an address.

## Commands

- [`basemodo callers list`](https://basemodo.com/docs/cli/callers-list)
- [`basemodo callers add`](https://basemodo.com/docs/cli/callers-add)
- [`basemodo callers remove`](https://basemodo.com/docs/cli/callers-remove)
