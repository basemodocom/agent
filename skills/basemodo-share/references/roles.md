# Roles

Who can do what with an App: its Owner, its Members, its Editors, and the Admins of a Workspace.

## The roles

### Owner

The person (or [Workspace](https://basemodo.com/docs/plans#workspace)) an App belongs to. The Owner decides who can reach the App, pays for it, and can do everything: deploy, roll back, read the Logs, change Secrets, run commands and SQL, share it. Whoever deploys an App first owns it. Your App hears `X-Basemodo-Role: owner` for its Owner.

### Member

A person the Owner shares the App with, by inviting their email (see [Sharing](https://basemodo.com/docs/sharing)). Members use the App: they pass Basemodo's sign-in and reach it, and nothing more. Your App hears `X-Basemodo-Role: member`. Someone let in only because the App is Link, Public or Workspace is not a Member, and your App hears no role for them.

In a Workspace, Member also means a person who belongs to the Workspace. Each one is a seat on the Workspace's bill, not a payer: the Workspace pays.

### Editor

A Member the Owner lets work on the App without owning it: the developer helping you, added with `basemodo share --editor EMAIL`. Editors deploy, roll back, read the Logs, change Secrets, run commands and SQL, and take Backups, from their own account. They do not change who can reach the App, restore a Backup (which overwrites its data), download its data or delete it (they get [`owner_only`](https://basemodo.com/docs/errors#owner_only)), and they do not pay for it. Your App hears `X-Basemodo-Role: editor`.

### Admin

A Workspace Member who also manages the Workspace: its people, its bill, and every App the Workspace owns, including those Apps' Members and Editors: your App hears `X-Basemodo-Role: owner` for every Admin of the Workspace that owns it. Nothing in a Workspace depends on one employee. A Workspace always has at least one Admin.

## Who can do what

| | Owner | Editor | Member |
| --- | --- | --- | --- |
| Open the App | yes | yes | yes |
| Deploy, roll back, read Logs | yes | yes | no |
| Change Secrets, run commands and SQL | yes | yes | no |
| Take and list Backups | yes | yes | no |
| Restore a Backup, download the data, delete the App | yes | no | no |
| Change the Visibility, invite and remove Members | yes | no | no |
| Pay for it | yes | no | no |

The Admins of a Workspace can do everything an Owner can on every App the Workspace owns.

## When an App changes hands

A Transfer moves an App into a Workspace, or gives it to another Person, who accepts it (an Admin of the Workspace, or that Person). Only its Owner changes: its Members and Editors stay. Before accepting, the receiver sees the App's Editors (`basemodo transfers list`, or the Transfer on basemodo.com) and can take any of them off in the same step (`basemodo transfers accept ID --remove-editor EMAIL`), so whoever gave the App keeps no way in through an Editor they invited. Moved into a Workspace, whoever asked becomes one of its Editors.

A Person who leaves a Workspace, or is taken out of it, keeps no role on its Apps, not even one they were invited to as an Editor or a Member. Deleting an App cancels its pending Transfer.

## Everyone is a Person

Owners, Members, Editors and Admins are all Persons: one email is one Person, whether they sign in by email link, Google or GitHub, and whether they own Apps or were only ever invited to one. Members never pay.
