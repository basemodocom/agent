# Supported runtimes

What Basemodo recognizes in a folder with no configuration, how it builds and starts each, and what to do when your App is something else.

Basemodo reads your folder's files (never the network) and says what it found and why: the files and fields it looked at. The most specific match wins: your own `Dockerfile` first, then a framework (Next.js before plain Node, Django before plain Python), then a runtime, then a static website.

- **Versions** come from your files (`.nvmrc`, `engines`, `.python-version`, `requires-python`); pin another with [`[build]`](https://basemodo.com/docs/manifest#build).
- **The start command** comes from your framework or your scripts; give another with [`web.command`](https://basemodo.com/docs/manifest#web.command). Whatever starts, it must listen on `$PORT` (see [How Apps run](https://basemodo.com/docs/how-apps-run#the-port-contract)).
- **Anything else** deploys with a `Dockerfile` at the top of the folder. When nothing matches, the Deploy stops with [`nothing_detected`](https://basemodo.com/docs/errors#nothing_detected) and the fix names the file to add.

## What is detected

| Runtime | Detected by | Plan |
| --- | --- | --- |
| Own Dockerfile (first: it wins over every detector) | `Dockerfile` at the top of the folder; `EXPOSE` in its last stage only to warn when it is not `$PORT` | built from that Dockerfile as it is (`web.command` becomes its entrypoint), run with `PORT=8080`: the web process must listen on `$PORT` (the Port Contract; a container that never answers fails `not_ready` naming it) |
| Static site | `index.html` at the top of the folder, and no build signal | the whole folder served by Caddy on port 8080 but for names that start with a dot (`.env`, `.npmrc`; `.well-known` is served), a missing path answered with the folder's `404.html` when it has one; no install, build or start command |
| Node: package manager and version (every Node row) | `packageManager` in `package.json`, else the lockfile: `pnpm-lock.yaml` (pnpm), `yarn.lock` (yarn; Yarn 2+ with `.yarnrc.yml`), `bun.lock`/`bun.lockb` (bun), `package-lock.json` (npm), none (npm). Version: `.nvmrc` (`22`, `v22.12.0`, `lts/jod`), else `.node-version`, else `engines.node` (the major the range allows, 24 first, then 22, 20, 26, 18) | install `npm ci` / `npm install` / `pnpm install --frozen-lockfile` / `yarn install --frozen-lockfile` (`--immutable`) / `bun install --frozen-lockfile`; image Basemodo's runtime image on `node:<version>-slim`, `node:24-slim` when nothing pins one; pnpm and yarn through its Corepack, bun from npm |
| Next.js | `next` in `dependencies` or `devDependencies` of `package.json` | `scripts.build` (else `next build`), `scripts.start` (else `next start`), port 3000 |
| Astro | `astro` in the dependencies; `@astrojs/node` makes it a server | `scripts.build` (else `astro build`); with `@astrojs/node`: `HOST=0.0.0.0 node ./dist/server/entry.mjs` on port 3000; without: `dist/` served by Caddy on port 8080 (`scripts.start`, `astro dev` in Astro's templates, is ignored) |
| Vite | `vite` in the dependencies and no `scripts.start` | `scripts.build` (else `vite build`), then `dist/` served by Caddy on port 8080 |
| Express | `express` in the dependencies | `scripts.build` if any; `scripts.start`, else `node <main>`, else `node server.js` (`index.js`, `app.js`, `main.js`); port 3000 |
| Hono | `hono` in the dependencies (Node with `@hono/node-server`, or Bun) | as Express |
| Node | `package.json` with `scripts.start`, `main`, or a `server.js` (`index.js`, `app.js`, `main.js`) at the top | as Express |
| Python (any) | `uv.lock` → uv; `poetry.lock` or `[tool.poetry]` → poetry; `requirements.txt` (and its `-r` includes) → pip; a `pyproject.toml` `[project]` alone → uv. Version: `.python-version`, else `requires-python` (or poetry's `python`), which picks 3.13 if allowed, else the newest of 3.9 to 3.14 allowed; else 3.13 | `python:<version>-slim`, dependencies in `/opt/venv` with `uv sync --locked --no-dev`, `poetry install --only main --no-root` or `pip install -r requirements.txt`; port 8000. Only main dependencies count. A Python folder no framework below starts is detected with no start command, and the Deploy asks for `[web] command` |
| Django | the `django` dependency, `manage.py` naming `DJANGO_SETTINGS_MODULE`, and `<project>/wsgi.py` (or `asgi.py` with uvicorn) | `gunicorn <project>.wsgi`, or `uvicorn <project>.asgi:application` when uvicorn and not gunicorn is a dependency; `python manage.py collectstatic --noinput` at build when the settings set `STATIC_ROOT`; no migrations at start |
| FastAPI | the `fastapi` dependency and a module-level `<app> = FastAPI(...)` (tests and virtualenvs not searched; with several, the conventional `main.py`, `app.py`, `app/main.py` first) | `uvicorn <module>:<app> --host 0.0.0.0 --port $PORT` (`--app-dir src` for a src layout); uvicorn added when neither it nor `fastapi[standard]` is a dependency |
| Flask | the `flask` dependency and a module-level `<app> = Flask(...)`, else `<app> = create_app()`, else `def create_app` | `gunicorn <module>:<app> --bind 0.0.0.0:$PORT` (`'<module>:create_app()'` for a factory); gunicorn added when it is not a dependency |
| Streamlit | the `streamlit` dependency and the one top-level script importing it (`streamlit_app.py` among several) | `streamlit run <script> --server.port $PORT --server.address 0.0.0.0 --server.headless true` |
