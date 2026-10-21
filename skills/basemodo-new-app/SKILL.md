---
name: basemodo-new-app
description: "Starts a new App on Basemodo when there is no code for it yet: chooses the Template (an App that saves data or knows who is visiting, a static site, or Python for data work), makes its folder, and makes its first Deploy to a link the person can open. Use it when the person wants something built and put online from nothing: \"make a tracker for my team\", \"build a page for our event\", \"a dashboard of these numbers others can open\", a new tool, site, form or API, also from a chat app. For code that already exists, use basemodo-deploy instead."
license: "MIT"
compatibility: "Needs the basemodo CLI on the PATH (https://basemodo.com/docs/cli), or Basemodo's MCP (https://basemodo.com/docs/mcp) in a client without a terminal."
metadata:
  version: "0.1.0"
allowed-tools: "Bash(basemodo *)"
---

# A new App on Basemodo

From a request with no code behind it to a link the person can open: choose how to build it, make its folder, build it, deploy it. The rules every command follows are in the `basemodo` Skill.

## Steps

1. **Choose how to build it.** When there is code already, or the person names a stack, build with that, and deploy it as `basemodo-deploy` says. Otherwise start from a Template: read [references/starting-from-scratch.md](references/starting-from-scratch.md) before writing any code; it says which Template fits the request and the command that makes its folder.
2. **Make its folder** with that command, named for the App in lowercase letters, digits and dashes (`lunch-rota`). The folder's name becomes the App's name and its address, `https://lunch-rota.basemodo.app`. From then on the Template's `AGENTS.md` says how the App is built, extended and checked: follow it.
3. **Build what the person asked for**, in their language, and run the check the Template's `AGENTS.md` names until it passes.
4. **Deploy it** from its folder: `basemodo deploy --json`. The first Deploy creates the App. Give the person the `url` it prints; `basemodo open` opens it in their browser, signed in.
5. **Offer a repository; the App works without one.** A GitHub repository keeps the App's history, and once the App is linked to it every push deploys it: `basemodo deploy --link` in a clone of it ([references/github.md](references/github.md)). A folder deploys as it is, with no repository.

## From a chat app, through the Remote MCP

The Remote MCP has no folder of the person's: its `deploy` deploys a GitHub repository. Write the App from the Template as above, push it to a repository of the person's, and call `deploy` with `repository` (`owner/name`). When Basemodo's GitHub App cannot read the repository yet, the error's `fix` is the link where the person installs it; call `deploy` again once they have.

## Commands

- `basemodo deploy` (MCP tool `deploy`): Deploy a folder and print its URL once it is live.
- `basemodo open` (MCP tool `open`): Open an App's URL in your browser.

`basemodo <command> --help` gives a command's arguments and examples, and `basemodo docs <topic>` a page of the documentation (`basemodo docs --list` lists them; through the MCP, the tool `docs`). Both describe the version installed: read them before using an argument this session has not seen yet, rather than one remembered.

## Read more

- [references/starting-from-scratch.md](references/starting-from-scratch.md): which Template, before writing any code.
- [references/getting-started.md](references/getting-started.md): the path from a folder to a shared link as the person sees it, for explaining the steps to them.
- [references/github.md](references/github.md): linking a repository, when the person wants pushes to deploy.

## Gotchas

- Choose the Template by what the App does: one that saves anything, has a form that persists or knows who is visiting is the app Template, however much it looks like a page.
- The App needs no login, sign-up or user table of its own: Basemodo signs visitors in before they reach it and says who they are in headers (`X-Basemodo-Email`, `X-Basemodo-Id`). The app Template already reads them.
- What the App saves goes in its database (`$BASEMODO_DB`) or under `$BASEMODO_DATA`; everything else on its Machine is replaced at the next Deploy. The Templates already keep to this.
- A new App is Private: only the person can open it. Ask whom to share it with, and share it as `basemodo-share` says.
- API keys and passwords the App needs are Secrets (`basemodo-configure`), kept out of the code and the repository.
- `plan_needed` on the first Deploy means the person has no Plan yet: they choose one on the billing page the `fix` links to, then deploy again.
- Signing in is the person's, at their browser: when a command answers `not_signed_in`, ask them to run `basemodo login` in their terminal, then try again. Never run it for them.
