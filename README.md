# Basemodo

Deploy, share and fix Apps on Basemodo, the cloud for small software, from your agent: Basemodo's Skills, and its Remote MCP to act through.

Basemodo is your personal cloud: it puts the Apps you built online for you and the people you choose. Your agent deploys an App, and Basemodo builds it, runs it on a machine of its own with a SQLite database that keeps its data, and gives back its address. A new App is private: only the people you invite can open it, and Basemodo signs them in, so the App needs no login of its own.

Signed in as you, your agent can:
- build an App from the chat: you say what it is for, and your agent starts it from one of Basemodo's Templates, writes it, deploys it and fixes it, with no code to read and no folder or repository of yours;
- deploy an App from a GitHub repository, follow its build, and roll back a Deploy that went wrong;
- share an App by email with Members or Editors, or open it to anyone with the link or to everyone;
- read an App's status and Logs to find out why it is broken or slow, and restart it;
- run SQL on its database, take a Backup and restore one;
- keep API keys out of the code as Secrets, and add a custom domain.

Your agent acts only on your own Apps on Basemodo, and you revoke it at any time on the Devices page of basemodo.com. Basemodo needs a Plan, from $5 a month for one App; the people you share an App with never pay.

## Install

In Claude Code: `/plugin install basemodo --marketplace basemodocom/agent`, or before version 2.1.275, `/plugin marketplace add basemodocom/agent` then `/plugin install basemodo@basemodo`.

## Try it

Once the plugin is installed, ask your agent:

- "Build me an App on Basemodo for my team's lunch rota and give me the link"
- "Share my Basemodo App with my team"
- "My App on Basemodo is broken: read its Logs and fix it"

## What the plugin runs, sends and fetches

- **The Remote MCP**, https://mcp.basemodo.com, the plugin's only MCP server. Your agent connects to it over HTTPS, and you sign in to Basemodo with OAuth in your browser, where you approve the connection; the plugin carries no credential. Your agent sends it the tool calls it makes for you (an App's name, a GitHub repository to deploy, SQL to run, a Secret to set) and reads their answers. Without a terminal, the Skills have your agent push a new App's code to a GitHub repository of yours, which the Remote MCP deploys.
- **The Skills**, in `skills/`: instructions your agent reads. They run nothing by themselves.
- **The CLI**, with a terminal: the Skills have your agent run `basemodo` commands, which act on your Apps through Basemodo's API, https://api.basemodo.com, signed in as you. `basemodo deploy` packs the App's folder (without `.git` and the files it ignores) and uploads it to Basemodo; `basemodo pull` and `basemodo download` write an App's code and data into a folder on your computer; `basemodo feedback` sends what you write to Basemodo.
- **Installing the CLI**: when `basemodo` is missing, the Skills offer to install it and, once you agree, run the install script the plugin carries, with setup left out: `skills/basemodo/scripts/install.sh` on macOS and Linux, `skills/basemodo/scripts/install.ps1` on Windows, the script basemodo.com's install line serves. It downloads the `basemodo` CLI from its releases, https://github.com/basemodocom/cli/releases, checks it against the release's checksums, and adds its folder to your PATH. Your agent then runs `basemodo setup --user`, which writes Basemodo's Skills where your agents read them. You sign the CLI in yourself, with `basemodo login` in your browser.

## Links

- Documentation: https://basemodo.com/docs/mcp/claude-ai
- Support: https://basemodo.com/support
- Privacy policy: https://basemodo.com/privacy
- Terms of service: https://basemodo.com/terms
