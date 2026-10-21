# Deploying from GitHub

Link an App to a GitHub repository and every push to its branch deploys it, with no terminal involved.

Besides deploying a folder from your computer, an App can take its code from GitHub: a repository, a branch, and if the App lives in a part of the repository, its folder. Every push to that branch then makes a Deploy, exactly as `basemodo deploy` would: the same detection, the same [manifest](https://basemodo.com/docs/manifest), the same stages, and a failed one leaves the previous version running (see [Deploying](https://basemodo.com/docs/deploying)).

## Linking a repository

Basemodo reads your repositories through Basemodo's GitHub App, which you install once on your GitHub account or organization, choosing which repositories it may read. Every App you link afterwards reuses it, so linking a second repository is instant.

The quickest way is from a clone of the repository on your computer. [`basemodo deploy`](https://basemodo.com/docs/cli/deploy) notices the folder's GitHub remote and offers to link the App to that repository, the branch you are on and the folder you are in, then deploys as usual:

```sh
basemodo deploy            # asks whether to link
basemodo deploy --link     # links without asking
basemodo deploy --no-link  # never offers
```

If Basemodo's GitHub App cannot read the repository yet, it gives you the link to install it (or to give it that repository); then run the command again. With `--json`, the result's `github` says whether it linked, or gives the command or the install link.

You can also link, change or unlink from the GitHub section of the App's page on basemodo.com, which lists each Deploy with the commit it came from.

## What a push does

- A push to the linked branch deploys the commit pushed. Pushes to other branches do nothing, and for an App linked to a folder, neither do pushes that change nothing in it.
- Pushes in a row queue: Deploys of one App run one at a time, so the latest push ends live.
- A failed build is reported by email and in your notifications, with the build log in the App's [Logs](https://basemodo.com/docs/cli/logs).
- Uninstalling the GitHub App, or taking the repository away from it, disconnects the App until it is given back; renaming or transferring the repository keeps the link.

## Secrets stay out of the repository

Never commit keys or passwords. Set them with [Secrets](https://basemodo.com/docs/secrets): they reach the App at every Deploy, whether it came from a push or from your terminal.
