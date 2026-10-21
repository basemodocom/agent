# Domains

Where an App lives: its address on basemodo.app and what it shares with other Apps there, your own domain with HTTPS, and what happens to links when you rename it.

## Its address

Every App answers at `https://<name>.basemodo.app`, its name followed by a short suffix only when another App already had that name, or the name is `www`. The address is on its own domain, apart from basemodo.com, so nothing an App does can touch your Basemodo account. Other Apps share basemodo.app with yours, though: see [Apps share one site](#apps-share-one-site).

## Apps share one site

A browser tells sites apart by the Public Suffix List, and basemodo.app is not on it yet, so a browser takes every App on basemodo.app for one site. Basemodo keeps Apps apart where it can, and the rest is up to you:

- **Requests from another App arrive signed out.** A form another App posts to yours, a `fetch` or an image it sends, or a frame it puts your App in reaches your App without the visitor's cookies or [identity headers](https://basemodo.com/docs/identity): a Private App answers with its sign-in page, a Public one sees an anonymous visitor. So your App, framed by another App, shows signed out. A link followed from another App keeps both, as does every request your App's own pages send. The same holds between the subdomains of a custom domain: a form on `www.example.com` posted to `app.example.com` arrives signed out.
- **Your cookies are your App's own.** Basemodo drops the `Domain` attribute of every cookie your App sets on basemodo.app, so none reaches other Apps. It cannot see a cookie your pages' scripts set (`document.cookie`): set those without `Domain` too. Name your cookies with the `__Host-` prefix (`__Host-cart=3; Path=/; Secure`), which no other App can set or replace. On a custom domain, Basemodo leaves `Domain` as your App sets it.
- **Your own sign-in goes on a custom domain.** A browser's password manager offers a password saved on one App on every other App, and a passkey made for `basemodo.app` works on all of them. If your App signs people in itself, with passwords or passkeys, give it a [custom domain](#custom-domains) and have people sign in there. A passkey's `rpId` is your App's own host (`app.example.com`), never `basemodo.app`.
- **Keep your cookies small.** A browser holds a limited number of cookies for all of basemodo.app together, and your App receives at most 8 KB of a visitor's cookies with each request. When there are more, Basemodo drops cookies whose name does not start with `__Host-` first, the largest first, and only then `__Host-` ones: other Apps can set cookies for yours, but never a `__Host-` one, so name the cookies your App needs (its session) `__Host-`.

## Renaming an App

[`basemodo rename`](https://basemodo.com/docs/cli/rename) gives an App a new name, and its address follows:

```sh
basemodo rename team-lunch --app lunch-rota
```

The old address keeps working for 30 days: every request to it is sent to the new one, path and all, so links people already have still land. Meanwhile no other App can take the old address. Its [custom domains](#custom-domains) do not change. From then on, deploy it with `basemodo deploy --name team-lunch` (or from a folder of that name). Only the App's Owner renames it.

## Custom domains

On every [Plan](https://basemodo.com/docs/plans) an App can also answer at a hostname of yours, like `app.example.com`, with HTTPS that Basemodo sets up and renews: a Plan has two for each App it allows.

1. Add it: [`basemodo domains add app.example.com`](https://basemodo.com/docs/cli/domains-add). It prints two DNS records.
2. Add both at your domain's DNS host:
   - a `CNAME` record at `app.example.com` pointing to `domains.basemodo.app`, which sends visitors to Basemodo;
   - a `TXT` record at `_basemodo-challenge.app.example.com` with the value it printed, which proves the domain is yours (the CNAME alone does not: anyone could have left one pointing at Basemodo).
3. Verify: [`basemodo domains verify app.example.com`](https://basemodo.com/docs/cli/domains-verify). DNS changes can take a few minutes to show; the error [`domain_not_verified`](https://basemodo.com/docs/errors#domain_not_verified) says which record is still missing. Basemodo also looks by itself every few minutes for a week.

Once verified, the App answers at the hostname at once, with the same [Visibility](https://basemodo.com/docs/sharing) and sign-in as at its basemodo.app address, and the same rules for search engines. Basemodo then gets a certificate from Let's Encrypt (a minute or so): [`basemodo domains list`](https://basemodo.com/docs/cli/domains-list) shows each domain as `pending` (records not found yet), `issuing`, `active` (served over HTTPS) or `failed` (with the reason, for example a CAA record that does not allow Let's Encrypt; Basemodo tries again within the hour). Certificates are renewed well before they expire, as long as the CNAME still points at Basemodo.

The CNAME cannot sit at the apex of a domain (`example.com` itself), so use a subdomain such as `www` or `app`. A hostname belongs to one App: the first to verify it holds it, and [`domain_taken`](https://basemodo.com/docs/errors#domain_taken) tells anyone else. [`basemodo domains remove`](https://basemodo.com/docs/cli/domains-remove) frees it; deleting the App does too.
