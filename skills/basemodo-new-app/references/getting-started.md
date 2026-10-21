# Getting started

From a folder on your computer to a link you can send to your team, in five steps and plain words. No servers, databases or login code to set up.

You built something: a tracker for your team, a page of numbers, a small tool. Maybe an AI agent wrote it for you. It works on your computer, and now you want other people to use it. That is what Basemodo does. If you work with an agent, you can also let it do all of this for you: see [Deploying with an agent](https://basemodo.com/docs/agents).

## What you need

- The folder with your App in it. Basemodo recognizes most web projects by themselves: a website (a folder with an `index.html`), a Node.js app (Next.js, Vite, Astro, Express, Hono), a Python app (Django, FastAPI, Flask, Streamlit), or anything with a `Dockerfile`. The full list is on [Supported runtimes](https://basemodo.com/docs/runtimes).
- A terminal to type commands in. On a Mac the terminal is the app called Terminal; on Windows, PowerShell. You only ever type the commands on this page.

## 1. Install and sign in

Install the `basemodo` command. On a Mac or on Linux, type this in the terminal and press Enter:

```sh
curl -fsSL https://basemodo.com/install | sh
```

On Windows, type this in PowerShell instead:

```powershell
irm https://basemodo.com/install.ps1 | iex
```

It puts `basemodo` in a folder of your own, with no password to give, and says where. If it tells you to open a new terminal, do that. To check the command is there:

```sh
basemodo --version
```

It answers with its version, like `basemodo 0.1.0`. Typing the same install line again later upgrades it to the newest version.

Then sign in:

```sh
basemodo login
```

Your browser opens on Basemodo. Sign in with your email (Basemodo sends you a link, no password), or with Google or GitHub, then approve this computer. The terminal says who you are signed in as. You do this once per computer: it stays signed in for 30 days. ([`basemodo login`](https://basemodo.com/docs/cli/login) has the details, like signing in over SSH.)

## 2. Go to your folder

In the terminal, move into the folder of your App. If it is in your Documents folder and called `lunch-rota`:

```sh
cd Documents/lunch-rota
```

## 3. Deploy

```sh
basemodo deploy
```

Basemodo packs the folder, sends it, says what it found in it and why (the files it looked at), builds it and starts it. When it is ready, the last line gives your App's address and how long the Deploy took: `Live at https://lunch-rota.basemodo.app in 9.3 s`. The App is named after the folder; to choose another name, add `--name`, as in `basemodo deploy --name team-lunch`.

If something goes wrong, the error says what happened and, on a line starting with `fix:`, exactly what to do; the `docs:` line links to the explanation. Your previous version, if there was one, keeps running. See [Deploying](https://basemodo.com/docs/deploying) for everything a Deploy does.

## 4. Open it

Open the address in your browser. Basemodo asks you to sign in first: a new App is **Private**, so nobody but you can open it. That protection is Basemodo's, not your App's, so your App needs no login of its own.

## 5. Share it

Invite people by email:

```sh
basemodo share ana@example.com ben@example.com
```

Each of them gets an email with the address. They sign in with that email (or Google, or GitHub, if it uses the same address) and they are in. To let in anyone who has the link and signs in, or everyone without signing in:

```sh
basemodo share --visibility link
basemodo share --visibility public
```

[Sharing](https://basemodo.com/docs/sharing) explains each choice. You can do the same from the App's page on basemodo.com.

## Changing it

Edit your App, then run `basemodo deploy` again in the same folder. Basemodo builds the new version, and switches visitors to it only once it works. If the new version turns out wrong, [`basemodo rollback`](https://basemodo.com/docs/cli/rollback) brings an earlier one back.

What your App saves on its disk (in `/data`, where its database lives) stays through every Deploy: see [Data](https://basemodo.com/docs/data).

## What next

- Something keeps secrets, like an API key? Keep them out of your code with [Secrets](https://basemodo.com/docs/secrets).
- Want to see what your App prints, or whether it is up? [`basemodo logs`](https://basemodo.com/docs/cli/logs) and [`basemodo status`](https://basemodo.com/docs/cli/status). To open it in your browser, [`basemodo open`](https://basemodo.com/docs/cli/open); to start it again, [`basemodo restart`](https://basemodo.com/docs/cli/restart).
- Want an agent to do all this for you? [Deploying with an agent](https://basemodo.com/docs/agents).
- Every command, with examples: [the CLI](https://basemodo.com/docs/cli).
