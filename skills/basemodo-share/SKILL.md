---
name: basemodo-share
description: "Decides who can reach an App on Basemodo: inviting Members and Editors by email and removing them, its Visibility (private, workspace, link, public), Access Requests, paths open to webhooks, custom domains with HTTPS, renaming its address, search engine indexing, and the Toolbar. Use it when the person wants to share an App or send someone its link, let their team or everyone in, make it public or private, give a developer access, remove someone or take back the access of someone who left, let a webhook in, put the App on their own domain, change its name or address, or let search engines find it."
license: "MIT"
compatibility: "Needs the basemodo CLI on the PATH (https://basemodo.com/docs/cli), or Basemodo's MCP (https://basemodo.com/docs/mcp) in a client without a terminal."
metadata:
  version: "0.1.0"
allowed-tools: "Bash(basemodo *)"
---

# Who can reach an App on Basemodo

Basemodo stands in front of every App: it decides who gets in, signs them in, and tells the App who they are, so the App never implements login. This Skill changes who gets in, and where. The rules every command follows are in the `basemodo` Skill.

## Sharing

- **See who can reach it**: `basemodo share --json`: its `visibility`, its Members and Editors (invited or accepted), and the Access Requests waiting.
- **Invite people**: `basemodo share ana@example.com ben@example.com`. Each gets an email with the App's link and becomes a Member the first time they open it signed in.
- **Let someone work on it** (deploy, read Logs, change Secrets, run commands and SQL from their own account): `basemodo share --editor dev@example.com`.
- **Remove someone**, or take an invitation back: `basemodo share --remove ben@example.com`.
- **Answer an Access Request**: `basemodo share --approve carla@example.com`, or `--decline`.
- **Change its Visibility** with `basemodo share --visibility <private|workspace|link|public>`: `private`, only the Owner, Members and Editors (every new App); `workspace`, also everyone in the Workspace that owns it; `link`, anyone with the link who signs in; `public`, anyone, with no sign-in.

## Webhooks

A webhook (Stripe, GitHub) cannot sign in. Open only its paths, with `public_paths = ["/webhooks/stripe"]` in `basemodo.toml`, then deploy: the rest of the App stays as its Visibility says ([references/public-paths.md](references/public-paths.md)).

## Its address

- **A custom domain**: `basemodo domains add app.example.com` prints two DNS records, a `CNAME` to `domains.basemodo.app` and a `TXT` proving the domain is the person's. The person adds both at their DNS host; then `basemodo domains verify app.example.com`, and `basemodo domains list` shows its certificate from `pending` to `active`. `basemodo domains remove` frees it.
- **A new name**: `basemodo rename <new-name>`. The address follows; the old one redirects for 30 days. Deploy it afterwards with `--name <new-name>`, or set `name` in `basemodo.toml`.
- **Search engines**: `basemodo indexing on` lets them index a Public App; every other App stays out of them.
- **The Toolbar** on the App's pages (who is here, the Visibility, Share): `basemodo toolbar off` or `on`.

## Commands

- `basemodo share` (MCP tool `share`): Share an App: invite Members and Editors by email, remove them, answer Access Requests, or change its Visibility.
- `basemodo domains add` (MCP tool `domains_add`): Claim a hostname of yours for the App, and print the DNS records to add.
- `basemodo domains verify` (MCP tool `domains_verify`): Look for a custom domain's DNS records now; once found, the App answers there.
- `basemodo domains list` (MCP tool `domains_list`): List the App's custom domains, each with its status and DNS records.
- `basemodo domains remove` (MCP tool `domains_remove`): Stop the App answering at a custom domain, and forget its certificate.
- `basemodo rename` (MCP tool `rename`): Rename an App; its old address redirects to the new one for 30 days.
- `basemodo indexing` (MCP tool `indexing`): Let search engines index a Public App (on), keep them out (off), or say which.
- `basemodo toolbar` (MCP tool `toolbar`): Turn off the Toolbar on an App's pages (off), turn it back on (on), or say which.

`basemodo <command> --help` gives a command's arguments and examples, and `basemodo docs <topic>` a page of the documentation (`basemodo docs --list` lists them; through the MCP, the tool `docs`). Both describe the version installed: read them before using an argument this session has not seen yet, rather than one remembered.

## Read more

- [references/sharing.md](references/sharing.md): each Visibility, invitations, Access Requests, how visitors sign in, the Toolbar and search engines, before changing who gets in.
- [references/roles.md](references/roles.md): what an Owner, a Member, an Editor and an Admin may each do, when a command answers `owner_only`.
- [references/domains.md](references/domains.md): custom domains, renaming, and what Apps on basemodo.app share, when a domain does not verify or the App signs people in itself.
- [references/public-paths.md](references/public-paths.md): how Public Paths match, before opening one.

## Gotchas

- Share as narrowly as the request says: "share it with my team" is their emails (or `workspace` for a Workspace's App), not `public`. Ask before making an App `public` or `link`: `share` takes effect at once and invitations are emailed at once.
- On a `public` App most visitors arrive with no identity, so the App must work for them.
- Only the Owner changes who reaches an App; an Editor gets `owner_only`.
- The DNS records are the person's to add at their DNS host. DNS takes minutes to show; `domain_not_verified` says which record is still missing. A domain's apex (`example.com`) cannot hold the CNAME: use a subdomain (`www`, `app`).
- A domain verified for one App cannot serve another until removed (`domain_taken`).
- Making an App anything but `public` turns indexing off again.
- Signing in is the person's, at their browser: when a command answers `not_signed_in`, ask them to run `basemodo login` in their terminal, then try again. Never run it for them.
