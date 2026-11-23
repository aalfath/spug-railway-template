# Changelog

Deployers get an "update available" notice on Railway when a change lands on `main`. Read the
entry for the version you are moving to before you apply it. Breaking changes are listed first.

## 4.1.2 (2026-11-23)

- First release of the template: Spug v4.1.2
  (`openspug/spug:4.1.2@sha256:d60b06ca87e80bdf98a47aac0d1252d2c04ab47bc7f1256c96d763945f9482a9`)
  with Railway's MySQL, data on a `/data` volume, the first admin created from a generated password,
  a health check on `/api/account/login/`, and the Deploy on Railway button.
- Small-plan sizing: worker, monitor and scheduler run as threads of one process; one API worker;
  private Redis capped at 96 MB; job thread pool sized to `SPUG_CPUS` (default 1). About 0.3 GB RAM.
- Restarts: every Spug process restarts on exit, and the container exits non-zero when one keeps
  failing or supervisord stops, so Railway's on-failure policy restarts it.
