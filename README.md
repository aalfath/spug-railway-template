# Spug on Railway

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/spug?utm_medium=integration&utm_source=button&utm_campaign=spug)

One-click [Spug](https://github.com/openspug/spug) for Railway: an open-source, agentless ops platform for
managing servers over SSH. It covers a host inventory, batch command execution, a web terminal and file
manager, application deployments and pipelines, scheduled tasks, config management, uptime monitoring
and alerts.

**Version:** Spug `v4.1.2`, official image
`openspug/spug:4.1.2@sha256:d60b06ca87e80bdf98a47aac0d1252d2c04ab47bc7f1256c96d763945f9482a9`.

## What the template deploys

| Service | What it does | Volume |
|---|---|---|
| **Spug** | Web UI, API and websocket server, plus the job worker, monitor and scheduler (nginx and a private Redis run inside the same container). Built from this repo. Public HTTPS domain, health check on `/api/account/login/`. | `/data` (app code synced from the image, generated `SECRET_KEY`, deploy repos, transfer files, logs) |
| **MySQL** | Railway's MySQL 8, Spug's database (users, hosts, credentials, apps, tasks, history). | `/var/lib/mysql` |

Spug connects to MySQL over Railway's private network. On each start the upstream entrypoint waits
for MySQL, applies schema changes and, on the very first start, creates the admin account from the
`SPUG_ADMIN_USER` and generated `SPUG_ADMIN_PASSWORD` variables. There is no open setup page and no
default password.

## After deploy

1. Open the Spug service's public URL (the first start takes about a minute).
2. Log in as **`admin`** with the value of the Spug service's `SPUG_ADMIN_PASSWORD` variable
   (Railway → Spug → Variables). The login page also offers LDAP; use the default (standard) login.
3. Change the password under your profile. Changing the variable later doesn't change it: the
   variable is only read when the first admin is created.
4. Add your servers under **Hosts** (Spug connects out over SSH, so the hosts must be reachable from
   Railway) and start using batch execution, deployments, scheduled tasks and monitoring.

Optional, set in Spug's own **System settings**: email, DingTalk/WeCom/Feishu or webhook alerts,
LDAP login and two-factor login. Four wrong passwords within a day disable an account (upstream
behaviour); re-enable it with
`python3 manage.py user enable -u admin` in `/data/spug/spug_api` from the Railway shell.

## Variables

| Variable | Value | Notes |
|---|---|---|
| `SPUG_ADMIN_USER` | `admin` | Username of the first admin, used only on the first start |
| `SPUG_ADMIN_PASSWORD` | generated, 20 characters | Password of the first admin, used only on the first start |
| `MYSQL_HOST`, `MYSQL_PORT`, `MYSQL_USER`, `MYSQL_PASSWORD`, `MYSQL_DATABASE` | references to the MySQL service | Database connection over the private network |
| `PORT` | `8080` | Port nginx listens on inside the container |

There are no prompts. Optional: `TZ` (default `UTC`) sets the time zone for scheduled tasks and the
UI; `SPUG_API_WORKERS` (default `1`) and `SPUG_CPUS` (default `1`) size the API and the job pool for
larger plans.

## Memory and restarts

Spug runs in about 0.3 GB of RAM, so it fits Railway's smallest plans. To get there, this wrapper runs
upstream's worker, monitor and scheduler loops as threads of one Python process instead of three
processes, starts one API worker, caps the private Redis at 96 MB and sizes the job thread pool to the
service's CPUs instead of the host's. If any Spug process keeps crashing, or supervisord stops, the
container exits non-zero, so Railway's on-failure restart policy brings it back.

## Not included

Upstream's Compose file grants `SYS_ADMIN` and `/dev/fuse` for sshfs, which two optional features use
(distributing files *from* a host, and the pipeline "data transfer" node). Railway doesn't allow
those privileges, so those two features don't work here; everything else does.

## Updates

The Spug service builds from this repo. When we move it to a new Spug release, Railway shows an
"update available" notice on your project and you choose when to apply it. Read
[CHANGELOG.md](CHANGELOG.md) first. Schema changes are applied automatically on start; back up the
MySQL volume before a major upgrade.

## Licence

Spug is AGPL-3.0, (c) OpenSpug Organization. This wrapper only pins the official image and adds a
start script and supervisord config.
