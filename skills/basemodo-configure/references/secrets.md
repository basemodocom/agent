# Secrets

Keep API keys, tokens and passwords out of your code: set them as Secrets, and your App gets them as environment variables.

A Secret is a value your App needs and nobody else should see. Basemodo keeps it encrypted, gives it to your App's processes as an environment variable, and never shows it again, not even to you: the list shows names, who set each, and when.

## Setting one

```sh
basemodo env set STRIPE_KEY=sk_live_123 MAILER_TOKEN=abc
```

All the names in one command are set together, or none if one is wrong. To keep a value out of your shell's history, give the name alone and type or paste the value when it asks (then Enter and Ctrl-D):

```sh
basemodo env set STRIPE_KEY
```

Your App gets new or changed Secrets **the next time it starts**: the running version keeps the values it started with. Every start reads them again: a Deploy, waking from sleep, or a restart. So set them, then run [`basemodo restart`](https://basemodo.com/docs/cli/restart) (no build), or `basemodo deploy`.

In your code they are ordinary environment variables, read by name like any other: from `process.env` in Node, `os.environ` in Python.

## Listing and removing

```sh
basemodo env list
basemodo env unset MAILER_TOKEN
```

`env list` shows each name with who set it and when, and the latest changes. The App's page on basemodo.com has the same list and a form to set and unset them.

## Rules

- Names are letters, digits and `_`, not starting with a digit, at most 128 characters: `STRIPE_KEY`, `db_password_2`.
- `PORT` and every name starting with `BASEMODO_` are Basemodo's, set for every App (see [How Apps run](https://basemodo.com/docs/how-apps-run)).
- A value is at most 32 KB; an App has at most 100 Secrets.
- Everyone who may deploy an App may change its Secrets, and every change is recorded with who made it.

## Commands

- [`basemodo env set`](https://basemodo.com/docs/cli/env-set)
- [`basemodo env list`](https://basemodo.com/docs/cli/env-list)
- [`basemodo env unset`](https://basemodo.com/docs/cli/env-unset)
