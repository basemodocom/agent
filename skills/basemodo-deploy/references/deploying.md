# Deploying

What happens when you deploy a folder: what is sent, how Basemodo works out how to build and run it, when it goes live, and what happens when it fails.

A Deploy is one published version of an App. You make one with [`basemodo deploy`](https://basemodo.com/docs/cli/deploy) in the App's folder (or an agent makes one with the `deploy` tool). The first Deploy creates the App. An App with no Deploy yet can start from one of Basemodo's Templates instead of a folder: `--template app|site`.

## What is sent

The CLI packs the folder and uploads it. It leaves out `.git` and everything your `.gitignore`, `.ignore`, `.basemodoignore` and `.dockerignore` files exclude, so dependencies like `node_modules` and build output stay home (Basemodo installs and builds on its own machines, never on yours). It reads all four in the folder and in every folder inside it. Above the folder it reads only `.gitignore` and `.ignore`, as git does: up to the root of the git repository the folder is in, and none when it is in no repository. A `.basemodoignore` or `.dockerignore` above the folder never applies, since the folder is what is built, and Docker reads `.dockerignore` only from there. A folder may pack to at most 50 MB; add a `.basemodoignore` (same syntax as `.gitignore`) to leave out large files you do not need.

## A folder's `.basemodo/`

After each Deploy, the CLI writes `.basemodo/` in the folder: it names the App and the Deploy the folder came from, and it is never uploaded. `basemodo pull <app>` writes it too, with the App's latest code, into a new folder. From then on:

- The folder deploys that App only: another `--name`, `--workspace` or `name` in `basemodo.toml` is refused with [`app_mismatch`](https://basemodo.com/docs/errors#app_mismatch).
- Its next Deploy is made on the Deploy it came from. Once the App's code changed since (a Change from a chat, another folder's Deploy), it is refused with [`folder_behind`](https://basemodo.com/docs/errors#folder_behind): bring the changes in first, or deploy the folder over them with `basemodo deploy --replace`. They stay in the App's history.
- `basemodo pull <app> .` in the folder brings those changes in, joined with the folder's own, as git merges: it lists each Change with who made it, writes the files only the other side changed, deletes only files the folder's Deploy had that the latest code dropped, and never writes a file the folder leaves out of its upload (ignored, `.env`), there already or new. Where both sides changed the same lines of a text file, it leaves git's conflict markers, and the next Deploy is refused with [`conflict_markers`](https://basemodo.com/docs/errors#conflict_markers) until they are gone. A binary file, or one over 1 MB, that both changed stays as the folder has it.
- What agents and tools obey (agents' instructions and settings: `AGENTS.md`, `CLAUDE.md`, `CLAUDE.local.md`, `GEMINI.md`, `.cursorrules`, `.windsurfrules`, `.github/copilot-instructions.md`, `.claude/`, `.cursor/`, `.gemini/`, `.windsurf/`, `.vscode/`, `.mcp.json`; what a tool runs on its own: `.envrc`, `.npmrc`, `.yarnrc.yml`, `.yarn/`, `.pnpmfile.cjs`, `bunfig.toml`, `.husky/`, `package.json`'s scripts; and ignore files) is written only with `--accept` when another Person changed it: without it, `pull` lists it with who changed it and leaves it as it is, so an Editor cannot steer your agent or run code on your computer.

## How Basemodo knows what to build

Basemodo looks at the files and says what it found and why: "Detected Next.js 15 (next.config.ts, package.json dependencies.next)". That detection decides how to install, build and start the App. [Supported runtimes](https://basemodo.com/docs/runtimes) lists what it recognizes and what each becomes. In short:

1. A `Dockerfile` at the top of the folder wins: Basemodo builds it as it is.
2. Otherwise a framework it knows (Next.js, Django...), then a runtime it knows (Node, Python), then a static website (an `index.html`).
3. Otherwise the Deploy stops with [`nothing_detected`](https://basemodo.com/docs/errors#nothing_detected), and the fix names the file to add.

When detection cannot know something (the command that starts your App, the Node version you need, the App's name), say it in the manifest, a small `basemodo.toml` at the top of the folder: see [the manifest](https://basemodo.com/docs/manifest). What the manifest changes is listed next to the detection's explanation, each with its line.

## The stages

`basemodo deploy` reports each stage as it happens (an agent receives them as progress):

- **upload**: the folder is packed and sent.
- **detect**: what Basemodo found, and what the manifest changed.
- **queued**: another Deploy of this App is still running; Deploys of one App run one at a time, in the order they were asked for, so two in a row end with the latest one live.
- **build_turn** (`turn` in a terminal): the Deploy waits for a build turn: Basemodo's builders are all busy, and it builds as soon as one is free. Turns are shared fairly: whoever has waited longest goes next, however many Deploys someone else asked for. `basemodo status` and `basemodo deploys` say `building, waiting for a build turn` meanwhile.
- **build**: the image is built on Basemodo's builders, for up to 20 minutes from when its build starts, however long it waited for a turn. Its log goes into the App's [Logs](https://basemodo.com/docs/cli/logs).
- **start**: the new version starts on the App's machine.
- **ready**: it answered HTTP, so visitors now reach it.

## When it is live

Your App must listen for HTTP on the port in the `PORT` environment variable, on every interface (`0.0.0.0`), and answer within 60 seconds of starting. Any answer counts, even an error page. Detected Apps do this by themselves; an App started by your own command or `Dockerfile` must do it itself. [How Apps run](https://basemodo.com/docs/how-apps-run) explains this Port Contract.

## When it fails

A failed Deploy changes nothing for your visitors: the previous version keeps running. The error says why, with the fix:

- [`build_failed`](https://basemodo.com/docs/errors#build_failed): the build stopped; the error carries the build log, so you (or your agent) can read what broke.
- [`image_too_large`](https://basemodo.com/docs/errors#image_too_large): the image it built is larger than 2 GB, compressed; the error says its size.
- [`not_ready`](https://basemodo.com/docs/errors#not_ready): it built and started, but never answered HTTP on `$PORT` within 60 seconds.
- [`web_exited`](https://basemodo.com/docs/errors#web_exited): its `web` process exited before it answered; the error says how, and carries its last lines.
- [`start_failed`](https://basemodo.com/docs/errors#start_failed): it could not start at all.
- [`invalid_manifest`](https://basemodo.com/docs/errors#invalid_manifest): `basemodo.toml` has a mistake; the error names the key and the line.

You are also told by email and in your notifications on basemodo.com.

## Going back

[`basemodo rollback`](https://basemodo.com/docs/cli/rollback) makes an earlier Deploy live again, as a new Deploy that runs that Deploy's image: nothing is rebuilt, and it takes seconds. It uses the App's Secrets as they are now. Basemodo keeps the images of the live Deploy and the two before it, so you can roll back to either; older images are deleted, and a Deploy further back needs a new build ([`deploy_image_deleted`](https://basemodo.com/docs/errors#deploy_image_deleted)): deploy its Source again, from its folder or commit. A Deploy from before a [Security Update](#security-updates) rebuilt the App cannot be rolled back to, since its image has the vulnerability ([`deploy_before_security_update`](https://basemodo.com/docs/errors#deploy_before_security_update)); deploy its Source again instead, from its folder or commit, and it is built on the patched runtime. [`basemodo deploys`](https://basemodo.com/docs/cli/deploys) and the App's page on basemodo.com list its Deploys, newest first, with their ids; `basemodo deploy --json` prints the id of the Deploy it made.

## Who made each Deploy

Every Deploy names its author: you or an Editor, when deployed or rolled back from your own account (the CLI, the MCP, basemodo.com or the API); a push, when it came from the [GitHub repository](https://basemodo.com/docs/github) the App is linked to; or Basemodo, when it rebuilt the App for a Security Update. Deploys made before Basemodo recorded authors say so instead.

## Security Updates

When a vulnerability is in what Basemodo puts under your App (the runtime it builds on, its supervisor), Basemodo closes it without waiting for you: it rebuilds the App from the Source of its live Deploy, on the patched runtime, as a new Deploy whose author is Basemodo. Your code and your `basemodo.toml` stay as they are, and the Deploy goes through the same queue and readiness check as yours, so a rebuild that does not answer leaves the previous Deploy live. An App built from your own Dockerfile gets only Basemodo's new supervisor; the images your Dockerfile names stay yours. An urgent one is applied at once; any other when the App next sleeps, so no visitor waits for it, or at once if it never sleeps (it runs a worker). A paused App is left alone. You are told by email and in your notifications what changed and why.

A [`[build]`](https://basemodo.com/docs/manifest#build) pin to an exact release (`node = "22.1.0"`) is moved to the patched release of its line (Node 22.1.1): a pin chooses a version of the runtime, not its vulnerabilities. The Deploy shows the move as an override next to your pin, your `basemodo.toml` stays as it is, and your own Deploys keep the patched release while it is newer than your pin. A pin to a whole line (`node = "22"`) already follows its patched releases, and a pin to another line is left alone.

A Deploy of yours made after the Security Update was decided applies it too: built from your Source on the patched runtime, it counts as the App's rebuild, even after Basemodo's rebuild failed, and Basemodo does not rebuild the App again. A Rollback does not, as it runs an earlier image.

When the rebuild fails (it does not build, or never answers), the previous Deploy stays live as for any failed Deploy, and you are told at once, by email and in your notifications, with a date: the App has 7 days to deploy a version that builds (fewer, from 1, when the vulnerability is being exploited, and you are told if Basemodo shortens it). Any Deploy of yours that goes live before then is enough. Past that date the App is paused with that reason, and deploying a version that builds resumes it; restarting it does not, since that would run the vulnerable image again. Its data can still be [downloaded](https://basemodo.com/docs/data#downloading-your-data) meanwhile, and it stays paused.

When the vulnerability is in what your App's Machine runs on (its kernel, the Host under it), Basemodo restarts the Machine instead: nothing is built, and the same Deploy runs again. An urgent one restarts it at once, and visitors wait a moment rather than get an error, as when the App wakes; any other restarts only an App that never sleeps, at once, and every other Machine takes the patched layers when it next starts. A sleeping or paused App is not started for it. You are told in your notifications, not by email.

## Names and addresses

An App's name is the folder's name, or `name` in `basemodo.toml`, or `--name`: lowercase letters, digits and dashes, at most 40. Its address is `https://<name>.basemodo.app`, with a short random suffix (`lunch-rota-3f9a`) only when another App already has that name, or the name is `www`. Apps live on `basemodo.app`, a domain apart from basemodo.com, so an App can never read your basemodo.com sign-in.
