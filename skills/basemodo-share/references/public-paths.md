# Public Paths: webhooks

Let Stripe, Trello, GitHub or any other system call your App without signing in, on the few paths you name, while the rest of the App stays protected.

A Private or Link App asks every visitor to sign in. A webhook cannot sign in, so it would only ever see the sign-in page. Public Paths are the exception: the paths you list in the manifest let anyone through, even on a Private App.

## Declaring them

In `basemodo.toml` at the top of the folder, with [`public_paths`](https://basemodo.com/docs/manifest#public_paths):

```toml
public_paths = ["/webhooks/stripe", "/hooks/*"]
```

Then deploy. They open with the Deploy that declares them, and close with the first Deploy that drops them.

- A path is matched exactly: `/webhooks/stripe` opens that path only, not `/webhooks/stripe/other`.
- `/*` at the end opens every path under it: `/hooks/*` opens `/hooks/trello` and `/hooks/a/b`.
- A path with `.` or `..` segments, an empty segment, a backslash or an encoded `/` never matches, so nobody can reach another part of your App through a Public Path.

## What a request on a Public Path gets

- It reaches your App without signing in, and **without identity headers**, unless the caller happens to be signed in to the App. So check who is calling yourself: most services sign their webhooks (Stripe's `Stripe-Signature`, GitHub's `X-Hub-Signature-256`); keep their signing secret in a [Secret](https://basemodo.com/docs/secrets) and verify every request.
- Stricter limits than signed-in visitors: 60 requests at once, 600 a minute, and a body of at most 1 MB. Over them the caller gets `429` or `413`, and your App is not disturbed. A flood on a webhook never uses up the allowance of your signed-in visitors.
- A sleeping App is woken by it, as by any visit.

## Seeing what is open

[`basemodo status`](https://basemodo.com/docs/cli/status) lists the App's Public Paths, and so does the App's page on basemodo.com, so you always know exactly what is open.

## Another App calling

For one of your own Apps calling another, a Public Path is not needed: name it one of the other App's [Callers](https://basemodo.com/docs/callers), and expose only the paths it calls. For an App of another person or Workspace, open your API with a Public Path and check an API key: [Expose an API to another Owner's App](https://basemodo.com/docs/expose-an-api).
