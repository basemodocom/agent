# Sharing

Who can open an App: its Visibility, the people you invite, and how they sign in.

Basemodo stands in front of every App. When someone opens it, Basemodo decides whether to let them in, signs them in if needed, and tells your App who they are (see [Who is visiting](https://basemodo.com/docs/identity)). Your App never implements login, invitations or passwords.

You share from the terminal with [`basemodo share`](https://basemodo.com/docs/cli/share), from the Sharing section of the App's page on basemodo.com, or by asking your agent.

## Visibility

An App's Visibility says who gets in. Every new App starts Private.

### Private

Only the Owner, the Members and the Editors (the people you invited). Anyone else sees a sign-in page and, once signed in, a page saying they have no access. The safe default for anything internal.

```sh
basemodo share --visibility private
```

### Link

Anyone who has the address and signs in, with any email. Good for a group you do not want to list one by one. Signing in still matters: your App learns who each visitor is. The first time someone you did not invite opens it, Basemodo asks them to confirm they want to continue to your App as their email.

```sh
basemodo share --visibility link
```

### Public

Everyone, with no sign-in: a landing page, a public tool. Nobody is asked to sign in, so most visitors arrive without an identity and your App must work for them; a visitor who signs in to the App anyway arrives with theirs. To know who a visitor is, offer the sign-in yourself: link to `/.basemodo/sign-in?path=` on the App's address, and the visitor comes back to that path signed in (see [Who is visiting](https://basemodo.com/docs/identity)).

```sh
basemodo share --visibility public
```

### Workspace

Everyone in the [Workspace](https://basemodo.com/docs/plans#workspace) that owns the App, with no list to keep: people who join the Workspace (by invitation, or by signing in with an email at its verified domain) get in, and people taken out of it lose access on their next request. Someone only invited to the Workspace is not in it until they join. The Owner, the Members and the Editors you invited still get in, so you can let in someone from outside too. Only for Apps a Workspace owns.

Your App learns who each visitor is, as always; someone let in only because they are in the Workspace arrives with no `X-Basemodo-Role`, as on a Link App. Nobody in the Workspace is asked to confirm before continuing to the App: it is their own Workspace's. Anyone else signed in sees a page saying the App is for the people of its Workspace, with a link to request access.

```sh
basemodo share --visibility workspace
```

## Inviting people

```sh
basemodo share ana@example.com ben@example.com
```

Each email gets a message with a link to the App. The invitation is pending until they open the App signed in with that email (by a sign-in link, or Google or GitHub with the same address); then they are a Member, and you are told. The link brings them to the App signed in, whatever its Visibility, even a Public App that asks nobody to sign in: if they are not signed in to Basemodo yet, they sign in there first and come back to the App. Inviting someone again sends the email again.

See who has access, and who has not accepted yet:

```sh
basemodo share
```

Remove a Member, or take back an invitation; it takes effect at their next request:

```sh
basemodo share --remove ben@example.com
```

## Editors

An Editor is a Member who may also work on the App from their own account: deploy it, roll it back, read its Logs, change its Secrets, run commands and SQL. The developer helping you, without your password or your bill:

```sh
basemodo share --editor dev@example.com
```

Editors cannot change who reaches the App; only the Owner shares it. See [Roles](https://basemodo.com/docs/roles#editor).

## Access Requests

Someone signed in who reaches a Private App they are not invited to sees a page saying so, with a button to ask for access. You are told by email and in your notifications, and answer in one click on the App's page, or from the terminal:

```sh
basemodo share                              # lists who asked
basemodo share --approve carla@example.com  # makes her a Member
basemodo share --decline carla@example.com
```

## How visitors sign in

Visitors sign in on basemodo.com, by a link emailed to them (no password), or with Google or GitHub. One email is one person, however they sign in. Their sign-in lasts 30 days on that device, and it opens every App shared with them.

Opening an App from basemodo.com, or with [`basemodo open`](https://basemodo.com/docs/cli/open), signs you in to it on the way, even to a Public App that asks nobody to sign in. So you arrive as yourself, with your Toolbar.

## The Toolbar

On an App's pages, Basemodo shows signed-in visitors its Toolbar: a small floating pill with who is here now, the App's Visibility, and a way to share it (Share for the Owner, Copy link for everyone else). Drag it to another corner, or hide it with `⌘.` (`Ctrl+.` off a Mac); the browser remembers both for that App. Visitors who are not signed in, on a Public App, never see it.

The Toolbar only shows. It never changes who can reach the App: Share and Visibility open a small window on basemodo.com, and the change is made there.

It is on for every App. Turn it off with [`basemodo toolbar off`](https://basemodo.com/docs/cli/toolbar), from the App's page on basemodo.com, or with [`toolbar = false`](https://basemodo.com/docs/manifest#web.toolbar) under `[web]` in its manifest, which applies when that Deploy goes live. A Deploy without the line leaves the Toolbar as it is. Only the Owner turns it off or on.

```sh
basemodo toolbar off
```

The Toolbar is a script Basemodo adds to the App's HTML pages, served from the App's own address at `/.basemodo/toolbar.js`. A Content Security Policy with `script-src 'self'` lets it in. A strict policy that allows only scripts carrying a nonce keeps it out: Basemodo never edits your App's policy, so that App shows no Toolbar.

## Search engines

Apps are never indexed by search engines: Basemodo answers `/robots.txt` for every App with "disallow everything" and marks every page `noindex`, whatever the App says. A Public App can choose to be found, for a landing page: [`basemodo indexing on`](https://basemodo.com/docs/cli/indexing), or [`indexable = true`](https://basemodo.com/docs/manifest#web.indexable) under `[web]` in its manifest. Making the App anything but Public turns indexing off again.

## Webhooks

Other systems (Stripe, Trello, GitHub) cannot sign in. To let them call your App, declare those paths as [Public Paths](https://basemodo.com/docs/public-paths).

## Who can change sharing

Only the Owner changes the Visibility and the Members. [Roles](https://basemodo.com/docs/roles) explains what Owners, Members, Editors and Admins can each do.
