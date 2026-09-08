# Pi-hole with Cloudflare Tunnel

Run **Pi-hole** with Docker and open its dashboard from your local network or through a **Cloudflare Tunnel** protected by email login.

The tunnel publishes only the Pi-hole web interface. Pi-hole DNS remains available only on the configured local-network IP address.

For details beyond this setup, see the [Pi-hole Docker documentation](https://docs.pi-hole.net/docker/) and [Cloudflare Tunnel documentation](https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/).

## Requirements

- Docker installed (Docker Engine or Docker Desktop), with Docker Compose v2 supporting `--wait` and `--wait-timeout`. See the [installation guide](https://docs.docker.com/engine/install/).
- Bash and `sudo` for the maintenance scripts.
- A Cloudflare account and a domain managed through Cloudflare. You'll create the tunnel and copy its token below.
- A stable local-network IP address for your server, with ports `53` (TCP/UDP) and `80` (TCP) available.

## Table of Contents

- [Deployment: Step-by-Step](#deployment-step-by-step)
  - [Environment Preparation](#environment-preparation)
  - [Cloudflare Access Setup](#cloudflare-access-setup)
  - [Cloudflare Tunnel Setup](#cloudflare-tunnel-setup)
  - [Deploying Pi-hole with Docker](#deploying-pi-hole-with-docker)
  - [Start Using Pi-hole](#start-using-pi-hole)
  - [Cleanup & Troubleshooting](#cleanup--troubleshooting)
- [Extra](#extra)
  - [Checks](#checks)
  - [Auto Updates](#auto-updates)
  - [Backup](#backup)
  - [Migration](#migration)
- [The End](#the-end)

## Deployment: Step-by-Step

### Environment Preparation

1. Clone this repository to your server and open its folder:

   ```bash
   git clone https://github.com/marmag0/pi-hole-anywhere.git
   cd pi-hole-anywhere
   ```

2. Copy the example environment file. You'll fill in the values during setup:

   ```bash
   cp config/.env.example .env
   ```

Shell scripts live in `scripts/`, and example and local maintenance configuration files live in `config/`. Keep `.env` and `docker-compose.yml` at the project root so standard Docker Compose commands work. Pi-hole data remains in `etc-pihole/` and `etc-dnsmasq.d/`.

Run the commands below from the project folder unless a step says otherwise. Keep `.env` private; it contains your dashboard password and tunnel token.

### Cloudflare Access Setup

Set up Access before publishing the dashboard hostname.

1. In the Cloudflare Zero Trust dashboard, open `Integrations` > `Identity providers`. If `One-time PIN` isn't listed, select `Add new identity provider` > `One-time PIN`. See Cloudflare's [email login instructions](https://developers.cloudflare.com/cloudflare-one/integrations/identity-providers/one-time-pin/).
2. Open `Access controls` > `Applications` > `Add an application` and select `Self-hosted`.
3. Enter a name and the hostname you'll use for the dashboard, such as `pihole.example.com`. Leave the path empty to protect the whole hostname.
4. Create an `Allow` policy that includes only your approved email addresses. Select `One-time PIN` as the application's login method and save it.

Use the same hostname in the tunnel setup below. Access protects the public hostname, not the local IP address; Pi-hole's own password still applies to both.

### Cloudflare Tunnel Setup

1. In the Cloudflare dashboard, open `Networking` > `Tunnels` > `Create a tunnel`.

   ![Cloudflare tunnel list and Create a tunnel button](https://marmag0.github.io/endpoints/pi-hole-anywhere/cloudflare-tunnel-ui-1.png)

2. Select `Cloudflared` as the tunnel type.

   ![Cloudflared tunnel type selection](https://marmag0.github.io/endpoints/pi-hole-anywhere/cloudflare-tunnel-ui-2.png)

3. Give the tunnel a name, such as `pi-hole-home`.

   ![Cloudflare tunnel name field](https://marmag0.github.io/endpoints/pi-hole-anywhere/cloudflare-tunnel-ui-3.png)

4. Copy only the tunnel token from the connector installation command into `CLOUDFLARE_TUNNEL_TOKEN` in `.env`. Don't run that command on the host; this repository starts `cloudflared` in Docker.

   ![Cloudflare connector installation command containing the tunnel token](https://marmag0.github.io/endpoints/pi-hole-anywhere/cloudflare-tunnel-ui-4.png)

5. Add a published application route for the hostname from [Cloudflare Access Setup](#cloudflare-access-setup). In the current dashboard, use `Routes` > `Add route` > `Published application`. Set the service URL to `http://pihole:80`; if the form separates the fields, use type `HTTP` and URL `pihole:80`.

   ![Cloudflare public hostname and service settings](https://marmag0.github.io/endpoints/pi-hole-anywhere/cloudflare-tunnel-ui-5.png)

The screenshots show the setup flow; Cloudflare may rename menu items. Its [tunnel setup guide](https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/get-started/create-remote-tunnel/) has the current labels.

The tunnel connects after you deploy the containers. `cloudflared` reaches `pihole:80` over the Docker network, so use that address rather than `localhost`. No host port `443` mapping is needed.

### Deploying Pi-hole with Docker

1. Make sure that Docker is running.
2. Fill in `.env`:

   - `API_PASSWORD` - password used to access the Pi-hole dashboard; make sure it is strong.
   - `LOCAL_IP` - local-network IP address of your server. Pi-hole DNS and HTTP are bound to this address.
   - `CLOUDFLARE_TUNNEL_TOKEN` - token for the remotely managed Cloudflare Tunnel.

   ```dotenv
   API_PASSWORD=replace-with-a-strong-password
   LOCAL_IP=192.168.1.10
   CLOUDFLARE_TUNNEL_TOKEN=replace-with-your-cloudflare-tunnel-token
   ```

   Replace all three examples with your values. `LOCAL_IP` must be assigned to this server, not your router or another device.

3. Deploy using the script (recommended):

   - `./scripts/deploy.sh` - deploy and follow logs in the terminal. Press Ctrl+C to stop following logs without stopping the containers.
   - `./scripts/deploy.sh -d` - detached deployment.
   - Scripts resolve the project folder automatically and can be called from another working directory.

   The script applies the DNS and blocklist settings below, then waits for Pi-hole to become healthy. For `-d`, wait for `Pi-hole is running in detached mode!` before continuing.

4. Verify both access paths:

   - Open `http://LOCAL_IP/admin/`, replacing `LOCAL_IP` with the address from `.env`. You should see Pi-hole's login screen.
   - Open your public hostname over HTTPS in a private browser window. You should see Cloudflare's email login first, then Pi-hole's login screen after entering the code.
   - If either check fails, see [Cleanup & Troubleshooting](#cleanup--troubleshooting).

   ![Pi-hole dashboard login screen](https://marmag0.github.io/endpoints/pi-hole-anywhere/pi-hole-login.png)

Alternatively, run `docker compose up -d` to start the containers without provisioning. Use `docker compose up` to attach to their output; Ctrl+C then stops the containers. Follow the manual setup below or run `./scripts/provision.sh` afterward.

### Start Using Pi-hole

The deployment script already configures Cloudflare DNS, enables these five blocklists, and updates Gravity. If you used it, skip the manual settings in steps 2-4 and go to step 5 to configure your devices.

To reapply this setup later, run `./scripts/provision.sh`. Each run resets upstream DNS to `1.1.1.1` and `1.0.0.1`, enables the five lists, and refreshes Gravity. Existing list IDs, comments, and group assignments are preserved; unrelated lists are left alone. If a download fails, the script reports the affected list so you can retry.

1. Log in to the Pi-hole dashboard with the password set in `API_PASSWORD`.
2. Choose Cloudflare DNS (`1.1.1.1`, `1.0.0.1`) at `SYSTEM` > `Settings` > `DNS`.

   ![Cloudflare selected as the upstream DNS provider in Pi-hole](https://marmag0.github.io/endpoints/pi-hole-anywhere/pi-hole-choose-DNS.png)

3. Open the blocklist settings and add these URLs. Keep the default list if it's already present. This setup combines general ad and tracking lists, malware lists, and a Polish list:

   ```text
   https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts
   https://big.oisd.nl
   https://raw.githubusercontent.com/Spam404/Lists/master/main-blacklist.txt
   https://raw.githubusercontent.com/MajkiIT/polish-ads-filter/master/polish-pihole-filters/hostfile.txt
   https://urlhaus.abuse.ch/downloads/hostfile/
   ```

   ![Pi-hole blocklist settings](https://marmag0.github.io/endpoints/pi-hole-anywhere/pi-hole-blocklist.png)

4. Update Gravity after adding the lists:

   ```bash
   docker compose exec pihole pihole -g
   ```

5. On each local-network device you want to filter, set the DNS server to `LOCAL_IP` from `.env`. Open a website, then check Pi-hole's query log for requests from that device.

Adding a public DNS resolver alongside Pi-hole on a client can bypass filtering even while Pi-hole is available. Don't rely on it being used only as a fallback. Devices outside your local network can use this tunnel for the dashboard, not for DNS.

### Cleanup & Troubleshooting

Check the service state and logs before resetting anything:

```bash
docker compose ps
docker compose logs --tail=100 pihole cloudflared
```

- If startup reports a port conflict, check whether another service is using port `53` or `80` on `LOCAL_IP`.
- If the local dashboard works but the public hostname doesn't, check the tunnel token, the `cloudflared` logs, and the route to `http://pihole:80`.
- If the public hostname skips the email login in a private browser window, check that the Access application protects that exact hostname and has no bypass policy.
- If you see a maintenance lock error, follow the lock guidance in [Auto Updates](#auto-updates). Don't delete an active lock.

If you need to stop or reset the deployment:

- `docker compose down` - stop Pi-hole while preserving existing configuration.
- `docker compose down --volumes` - stop Pi-hole and remove containers and named volumes, while leaving bind-mounted configuration folders intact.
- `./scripts/cleanup.sh` - full reset. After confirmation, it stops the services and deletes `etc-pihole/` and `etc-dnsmasq.d/`. Make a [backup](#backup) first if you need that data. Backups in the default `backup/` folder and `.env` are preserved.

## Extra

### Checks

GitHub Actions validates Docker Compose, checks Bash syntax, and runs ShellCheck on every push and pull request. Compose validation uses `config/.env.example`, so these checks do not require your tunnel token or local configuration.

### Auto Updates

Use `scripts/docker-update.sh` with `cron` to update both Pi-hole and `cloudflared`. It pulls the images configured in Compose, waits for Pi-hole to become healthy, and leaves old Docker images in place.

1. If you want to change the update settings, copy `config/update.conf.example` to `config/update.conf`. Set `LOG_FILE` to the desired log path; relative paths are resolved from the project folder. The default is `cron/cron.log`, and its directory is created automatically.
2. Optional: Set `BACKUP_BEFORE_UPDATE=true` in `config/update.conf` and configure [Backup](#backup). The default is `false`. A failed backup or Pi-hole restart cancels the update. The cron user must be able to run the backup's `sudo tar` command without a password prompt.
3. Test the updater manually with `./scripts/docker-update.sh "/path/to/pi-hole"`. Replace the path with the folder containing `docker-compose.yml`, then check the configured log for `Update successful!`.
4. Open `crontab -e` and add an entry using your actual project path:

   ```cron
   0 4 * * 0 /bin/bash /path/to/pi-hole/scripts/docker-update.sh /path/to/pi-hole
   ```

This runs every Sunday at 4:00 AM in cron's configured time zone. Updates and backups can briefly interrupt DNS, so choose a time that suits your network.

Deployment, backups, updates, provisioning, and cleanup share `.maintenance.lock` in the project folder. An overlapping run exits without changing the services. Deployment releases the lock after startup, before following logs. The other scripts release it when they exit normally or handle an interrupt or termination signal.

After a power loss or forced kill, the lock may remain. Check the PID in `.maintenance.lock/pid` and confirm that no maintenance operation or child command is still running before removing the stale lock. Direct Docker Compose commands don't use this lock, so avoid running them during scripted maintenance.

If upgrading from the old layout, move your existing `backup.conf` and `update.conf` into `config/` and update any cron entries to use `scripts/docker-update.sh`.

### Backup

Use `scripts/backup.sh` to save Pi-hole's data before an update, reset, or move to another server.

1. Copy the backup configuration:

   ```bash
   cp config/backup.conf.example config/backup.conf
   ```

2. Set `BACKUP_DIR` to the directory where you want your backup archive to be stored.
3. Set `BACKUPED_DIRS` to the directories you want to archive. By default, these are the Pi-hole configuration folders that should be preserved. Relative paths are resolved from the project folder. Keep `BACKUP_DIR` outside those directories.
4. Run the backup:

   ```bash
   ./scripts/backup.sh
   ```

The script briefly stops Pi-hole so its files don't change while they're archived, then attempts to restart it even if the backup fails. A stopped Pi-hole is left stopped. Completed backups have a timestamp, a unique suffix, and a `.tar.gz` extension; incomplete archives are removed when the script handles a failure.

By default, the archive contains `etc-pihole/` and `etc-dnsmasq.d/`, not `.env`. Copy `.env` separately and keep both it and your backups private. Before relying on a backup, inspect it with `tar -tzf /path/to/backup.tar.gz`, replacing the path with your archive.

### Migration

Keep Pi-hole stopped on the destination until its data has been restored.

1. Copy your Pi-hole folder, including `docker-compose.yml`, `.env`, `scripts/`, `config/`, and the backup archive, to the new machine. Set `LOCAL_IP` in `.env` to the new server's local-network address.
2. Restore the backed up configuration directories to `etc-pihole/` and `etc-dnsmasq.d/` before starting Pi-hole. Changing backup settings does not change Docker's volume paths.
3. Run `./scripts/deploy.sh` to bring the containers back up and reapply the documented DNS and blocklist settings. Use `docker compose up -d` if you want to keep restored settings without provisioning.
4. If you want to verify the setup, check the Pi-hole dashboard locally and through the protected Cloudflare hostname.

## The End

Thanks for checking out my project! I hope the guide and scripts made your Pi-hole setup a little easier.

To see more of my work, check out my:

- [GitHub Profile](https://github.com/marmag0)
- [LinkedIn Profile](https://www.linkedin.com/in/mikolaj-mazur)
