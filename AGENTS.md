# Project Instructions

Applies to this repository. Read `README.md` for the setup walkthrough and inspect the relevant scripts before changing them. These are the agreed defaults, not permission to expand a task. Change them only when the user requests it, and keep this file aligned with the code.

## Style and Scope

- Never use em dashes in code, documentation, comments, commit messages, or chat. Use a standard hyphen `-` instead. Replace existing em dashes when found in project text.
- Preserve the surrounding Bash style, indentation, quoting, and `log` function format. Don't reformat unrelated code or introduce a framework for this small Compose project.
- Write direct, practical English. Keep the README's numbered walkthrough, screenshots, useful examples, and personal tone. Avoid promotional language, filler, generic advice, and claims that a task is easy.
- Keep comments short and explain intent or non-obvious behavior. Don't narrate every command or add decorative banners. Use consistent names: Pi-hole, Cloudflare Tunnel, Cloudflare Access, Docker Compose, and `cloudflared` for the process or service.
- When behavior or paths change, update the README, configuration examples, and CI references together. Check current official documentation before changing external API calls or dashboard instructions.
- Implement the requested task, not the next idea. The metrics backend and custom application API were discussed but are not approved extensions. Don't add them, substitute blocklists, or recreate a TODO list without a request.

## Deployment Decisions

- This is a Bash and Docker Compose deployment of Pi-hole, not a custom web application. Cloudflare Mesh has been replaced by token-based `cloudflared`; don't reintroduce Mesh or remote DNS access.
- Keep DNS ports `53/tcp` and `53/udp`, and dashboard port `80/tcp`, mapped to `LOCAL_IP`. Preserve local dashboard access. No host port `443` mapping is needed.
- The remotely managed tunnel targets `http://pihole:80` over the Compose network, not `localhost`. Its token comes from `CLOUDFLARE_TUNNEL_TOKEN` in `.env`.
- Cloudflare Access protects the public dashboard hostname with approved email addresses and One-time PIN login. It doesn't protect the local IP. Pi-hole's own dashboard password remains enabled.
- Preserve required `LOCAL_IP`, `API_PASSWORD`, and tunnel-token validation. `API_PASSWORD` maps to `FTLCONF_webserver_api_password` in the container. Never print the real values.
- Compose uses `pihole/pihole:latest` and `cloudflare/cloudflared:latest`. Verify compatibility when changing image-dependent behavior. Preserve the Pi-hole dashboard healthcheck and the tunnel's `service_healthy` dependency.

## Layout and Entry Points

- Keep `docker-compose.yml` and the active `.env` at the root so plain `docker compose` commands work. Put shell scripts in `scripts/` and configuration examples and local maintenance configuration in `config/`.
- Don't relocate or overwrite `etc-pihole/` or `etc-dnsmasq.d/` as part of repository cleanup. They are live bind-mounted data, not source files.
- `scripts/deploy.sh [-d]` provisions Pi-hole, waits for startup, and optionally follows logs. Ctrl+C while following its logs leaves the containers running. Direct `docker compose up` has different stop behavior and doesn't provision settings.
- `scripts/provision.sh` is the host entry point. `scripts/provision-pihole.sh` runs inside the Pi-hole container; don't run it directly on the host.
- Preserve provisioning of upstream DNS `1.1.1.1` and `1.0.0.1`, the exact five URLs shared by the README and provisioning script, and the Gravity refresh. Reruns preserve list IDs, comments, group assignments, and unrelated lists. Failed downloads must be reported, not silently replaced.
- Provisioning uses the container's configured API password. Pi-hole CLI credentials cannot perform all required configuration changes. After Gravity swaps databases, its API can briefly be stale; the final verification reads the completed database.
- README screenshots are hosted under `https://marmag0.github.io/endpoints/pi-hole-anywhere/`. Their source is a separate `endpoints` repository. Don't modify that repository as an implicit part of this one.

## Maintenance Safeguards

- `scripts/maintenance.sh` provides the project-local `.maintenance.lock`. Deployment, provisioning, backup, update, and cleanup share it. Child scripts inherit the parent's lock without owning or releasing it. Keep failure and signal cleanup intact.
- Deployment holds the lock through provisioning and startup, then releases it before following logs. Direct Compose commands bypass the lock. Never remove a stale-looking lock without checking for active maintenance processes and child commands.
- `scripts/backup.sh` reads `config/backup.conf`. Preserve the existing `BACKUP_DIR` and `BACKUPED_DIRS` names; relative paths resolve from the project root, not `config/`.
- Backups stop a running Pi-hole for consistency and attempt to restart it even on failure. A stopped service stays stopped. Preserve private archive permissions, unique filenames, incomplete-file cleanup, and rejection of destinations inside source directories.
- `scripts/docker-update.sh /path/to/project` reads optional `config/update.conf`. Defaults are `LOG_FILE="cron/cron.log"` and `BACKUP_BEFORE_UPDATE=false`. Optional backups use `backup.sh`; backup or restart failure cancels the update. A legacy root-level `update.conf` must not be silently ignored.
- Updates wait for healthy startup before reporting success. Don't add host-wide Docker image or volume pruning.
- `scripts/cleanup.sh` is destructive and requires confirmation. Its data deletion is limited to the project's two bind-mount folders. Don't run it against the user's deployment for verification.

## Verification

Run checks from the project root. CI is defined in `.github/workflows/checks.yml`:

```bash
docker compose --env-file config/.env.example config --quiet
for script in scripts/*.sh config/*.conf.example; do
    bash -n "$script" || exit 1
done
shellcheck --external-sources scripts/*.sh
git diff --check
```

- Tests must stay local in ignored `tests/` or a temporary directory. Never commit or force-add tests. When the local Python tests are present, run `python3 -B -m unittest discover -s tests -q`; don't treat an absent suite or zero tests as verification.
- For maintenance changes, test failure recovery, overlapping runs, inherited lock ownership, paths with spaces, and archive contents using disposable fixtures. For provisioning changes, verify fresh and repeated runs with `pihole/pihole:latest`, including preservation of existing list metadata.
- Live tests must use isolated containers, dummy credentials, and temporary data, without the real tunnel token or occupied host ports. Remove only the test resources you created. Never start the real tunnel or stop the user's DNS service as a side effect of testing.
- If ShellCheck is unavailable locally, use an approved installation or a container with only sanitized scripts and configuration examples mounted read-only. Don't mount the whole repository with its `.env` and runtime data.
- For documentation-only changes, check anchors, script paths, examples, and consistency with the code. Confirm comment edits leave executable lines unchanged.
- Report checks actually run and any gaps. Passing isolated container checks does not prove the user's live Cloudflare login or client DNS routing works.

## Git and Local Files

- Inspect status before editing or committing. Preserve unrelated changes, ignored runtime data, and existing stashes.
- Keep `.env`, local maintenance configuration, logs, backups, and tests ignored. Keep `AGENTS.md` tracked so the project instructions are available in future clones.
- The old `tasks.md` was completed and removed. Don't rely on it as a pending work queue.
- Commit, push, and merge when requested, not automatically after every edit. Use concise, descriptive commit subjects, such as `Unify setup documentation and inline comments`. Split logically separate work when useful; no mandatory Conventional Commits prefix.
- Before a requested merge, fetch the current remote state, check repository rules, and verify relevant CI. Prefer a fast-forward when possible. Don't force-push, bypass protections, delete branches, or assume permission for another repository.

## Keeping This Useful

Store durable decisions and verified commands here, not transcripts, secrets, temporary paths, test counts, or past commit IDs. Link to the README and code rather than copying the full deployment guide. Prune stale instructions when the project changes.
