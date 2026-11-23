# Changelog

Deployers get an "update available" notice on Railway when a change lands on `main`. Read the
entry for the version you are moving to before you apply it. Breaking changes are listed first.

## 4.1.2 (2026-11-23)

- First release of the template: Spug v4.1.2 (`openspug/spug:4.1.2@sha256:d60b06ca87e8…`) with a
  Railway MySQL database, data on a `/data` volume, the first admin created from a generated
  password, a `/api/account/login/` health check and a non-zero exit when a Spug process dies.
