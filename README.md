# Pi-hole with Cloudflare Tunnel

This repository deploys **Pi-hole** with Docker and makes its web interface available locally and through a Cloudflare Tunnel.

The tunnel publishes only the Pi-hole web interface. Pi-hole DNS remains available only on the configured local-network IP address.

For more information about **Pi-hole**, refer to its [web page](https://pi-hole.net), the [docker-pi-hole repository](https://github.com/pi-hole/docker-pi-hole), and the [official documentation](https://docs.pi-hole.net/docker/).

For more information about **Cloudflare Tunnel**, refer to its [official documentation](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/).

## Requirements

- Docker installed (Docker Engine or Docker Desktop). See the [installation guide](https://docs.docker.com/engine/install/).
- A Cloudflare account and a remotely managed tunnel token.
- A domain name you control to publish the protected Pi-hole hostname.

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

1. Clone this Git repository to your server and change your CWD to it.
2. Copy the example environment file and set its values:

```bash
cp .env.example .env
```

### Cloudflare Access Setup

1. Navigate to the Cloudflare Zero Trust panel and choose `Access controls` > `Applications` > `Add an application`.
2. Select `Self-hosted`, enter a name, and configure the same public hostname that will be used for the Pi-hole dashboard.
3. Create an `Allow` policy that includes only the email addresses allowed to access the dashboard. Enable `One-time PIN` as the login method.
4. Save the application. Authorized users will receive a login code by email when opening the dashboard domain.

### Cloudflare Tunnel Setup

1. Navigate to the Cloudflare Zero Trust panel and choose `Networking` > `Tunnels` > `Create a tunnel`.

![Cloudflare Zerotrust tunnels and connector dashboard](https://marmag0.github.io/endpoints/pi-hole-anywhere/cloudflare-tunnel-ui-1.png)

2. Select `Cloudflared` as the tunnel type.

![Cloudflare tunnel type selection](https://marmag0.github.io/endpoints/pi-hole-anywhere/cloudflare-tunnel-ui-2.png)

3. Choose a name that identifies the connector's purpose, such as `pi-hole-home`.

![Cloudflare tunnel name selection](https://marmag0.github.io/endpoints/pi-hole-anywhere/cloudflare-tunnel-ui-3.png)

4. Copy the Cloudflare Tunnel token and set it in `.env` as `CLOUDFLARE_TUNNEL_TOKEN=yourCloudflareTunnelToken`.

![Cloudflare tunnel access token codeblocks](https://marmag0.github.io/endpoints/pi-hole-anywhere/cloudflare-tunnel-ui-4.png)

5. Add a public hostname for the Pi-hole dashboard domain. Set the service to `http://pihole:80`. The hostname will require the email authentication configured in [Cloudflare Access Setup](#cloudflare-access-setup).

![Cloudflare domain selection for tunnel](https://marmag0.github.io/endpoints/pi-hole-anywhere/cloudflare-tunnel-ui-5.png)

The `cloudflared` container reaches the dashboard at `http://pihole:80` over the internal Docker network. It does not publish Pi-hole DNS through the tunnel.

### Deploying Pi-hole with Docker

1. Make sure that Docker is running.
2. Set up environment variables inside the `.env` file:
   - `API_PASSWORD` - password used to access the Pi-hole dashboard; make sure it is strong.
   - `LOCAL_IP` - local-network IP address of your server. Pi-hole DNS and HTTP are bound to this address.
   - `CLOUDFLARE_TUNNEL_TOKEN` - token for the remotely managed Cloudflare Tunnel.

```bash
API_PASSWORD=superHardPasswd
LOCAL_IP=yourPiHoleServerIpInHomeNetwork
CLOUDFLARE_TUNNEL_TOKEN=yourCloudflareTunnelToken
```

3. Deploy Pi-hole using the provided script and follow its instructions if they occur (recommended):
   - `./deploy.sh` - standard deployment, with logs displayed in the terminal (you can always switch it to detached mode by pressing `d`).
   - `./deploy.sh -d` - detached deployment.
   - Scripts must remain in the same folder as the `docker-compose.yml` file.

4. You can also run this yourself using:
   - `docker compose up`
   - `docker compose up -d` - consider adding `-d` so Docker does not block the terminal with logs.

5. Verify that Pi-hole is working:
   - Check that the Pi-hole web interface is accessible locally at `http://LOCAL_IP/admin/`.
   - After completing the tunnel setup, verify that the protected Cloudflare hostname opens the same dashboard.
   - If something goes wrong, check logs by attaching to the container: `docker compose attach pi-hole`.
     - Refer to [Cleanup & Troubleshooting](https://github.com/marmag0/pi-hole-anywhere#cleanup--troubleshooting) for further troubleshooting info.

![Pi-hole web UI logging screen](https://marmag0.github.io/endpoints/pi-hole-anywhere/pi-hole-login.png)

### Start Using Pi-Hole

`./deploy.sh` and `./deploy.sh -d` automatically configure the Cloudflare upstream DNS servers listed below, add the five blocklists, and update Gravity. If you start the containers directly with Docker Compose, run `./provision.sh` to apply the same setup. Repeated runs keep existing list IDs and unrelated lists; the five documented lists are enabled and Gravity is refreshed each time. A failed list download is reported as an error so you can retry without substituting a different list.

1. Open the Pi-hole web UI and enter your password (previously set as `API_PASSWORD`). You should now see the Pi-hole dashboard with telemetry and configuration options.
2. Choose your DNS provider at `SYSTEM` >> `Settings` >> `DNS`. I recommend Cloudflare DNS (`1.1.1.1`, `1.0.0.1`) because it is secure, privacy-oriented, and does not use your request data for profiling.

![Pi-hole DNS recursive resolver settings](https://marmag0.github.io/endpoints/pi-hole-anywhere/pi-hole-choose-DNS.png)

3. Add extra blocklists to Pi-hole to block more ads and tracking. Example suggestions:
   - Default Pi-hole list
   - General tracking and ad blocking list
   - Two malware blocklists from different sources for redundancy
   - A local-language blocklist for your region (for example, a Polish list if that is appropriate for you)

```
https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts
https://big.oisd.nl
https://raw.githubusercontent.com/Spam404/Lists/master/main-blacklist.txt
https://raw.githubusercontent.com/MajkiIT/polish-ads-filter/master/polish-pihole-filters/hostfile.txt
https://urlhaus.abuse.ch/downloads/hostfile/
```

![Blocklist panel in Pi-hole](https://marmag0.github.io/endpoints/pi-hole-anywhere/pi-hole-blocklist.png)

4. To use Pi-hole on a local-network device, set its DNS server to `LOCAL_IP` (the IP address of the Pi-hole server).

5. This project does not expose Pi-hole DNS through Cloudflare Tunnel. Devices outside the LAN can use the protected tunnel only to open the web interface.
6. If Pi-hole is unavailable entirely, DNS resolution may fall back to other resolvers and will not be filtered by Pi-hole. Adding a third DNS address such as `1.1.1.1` does not guarantee ordered use on modern systems, because many clients query all configured DNS servers in parallel (the Pi-hole won't work properly).
7. If you want stronger enforcement of Pi-hole-first DNS resolution, consider using a client-side tool or firewall rule that forces DNS traffic through Pi-hole.

### Cleanup & Troubleshooting

- `docker compose down` - stop Pi-hole while preserving existing configuration.
- `docker compose down --volumes` - stop Pi-hole and remove containers and named volumes, while leaving bind-mounted configuration folders intact.
- `./cleanup.sh` - script for full cleanup of Pi-hole. It stops the service and removes all saved data (good for hard resets).

## Extra

### Checks

GitHub Actions validates Docker Compose, checks Bash syntax, and runs ShellCheck on every push and pull request. Compose validation uses `.env.example`, so these checks do not require your tunnel token or local configuration.

### Auto Updates

Keeping self-hosted services up to date is one of the most important parts of maintaining a secure and reliable setup. For Pi-hole, a lightweight solution is often better than running a larger tool such as [Watchtower](https://containrrr.dev/watchtower/), especially on low-power hardware.

The provided `docker-update.sh` script lets you update Pi-hole automatically with `cron` and also clean up unused Docker images after a successful refresh.

1. If you want to change the update settings, copy `update.conf.example` to `update.conf`. Set `LOG_FILE` to the desired log path; relative paths are resolved from the project folder. The default is `cron/cron.log`, and its directory is created automatically.
2. Run the script with the path to the folder that contains `docker-compose.yml`, for example: `./docker-update.sh "/path/to/pi-hole"`.
3. If you want a backup before every update, set `BACKUP_BEFORE_UPDATE=true` in `update.conf` and configure `backup.conf` as described in [Backup](#backup). The updater calls `backup.sh` and cancels the update if the backup or Pi-hole restart fails. Make sure the cron user can run the backup's `sudo tar` command without an interactive password prompt.
4. Add the script to `cron` for regular automatic updates >> `crontab -e`. A sample entry could look like this:

```bash
0 4 * * 0 /bin/bash /path/to/docker-update.sh /path/to/pi-hole
```

This will run the update once a week, on Sunday at 4:00 AM.

Backups, updates, and provisioning share `.maintenance.lock` in the project folder. An overlapping run exits without changing the services. The lock is released when the process exits normally or receives an interrupt or termination signal. After a power loss or forced kill, remove the stale lock only after confirming no backup, update, or provisioning run is still running.

### Backup

If you want to preserve Pi-hole configuration before updating or migrating, you can use the provided `backup.sh` script.

1. Copy `backup.conf.example` to `backup.conf`.
2. Set `BACKUP_DIR` to the directory where you want your backup archive to be stored.
3. Set `BACKUPED_DIRS` to the directories you want to archive. By default, these are the Pi-hole configuration folders that should be preserved.
4. Run the script with:

```bash
./backup.sh
```

The script briefly stops a running Pi-hole for a consistent backup and creates a timestamped `.tar.gz` archive in the backup directory.

### Migration

If you need to move your Pi-hole setup to a new device or a new folder, you can do it in a few simple steps.

1. Copy your Pi-hole folder, including `docker-compose.yml`, the scripts, and the backup archive, to the new machine.
2. Restore the backed up configuration directories to the expected paths or adjust the backup script settings to match the new environment.
3. Run `./deploy.sh` from the folder that contains `docker-compose.yml` to bring the container back up.
4. If you want to verify the setup, check the Pi-hole dashboard locally and through the protected Cloudflare hostname.

## The End

Thank you very much for exploring my repository! It took me a lot of time and effort to deliver such a detailed guide with useful (I guess) scripts. I hope it was useful and easy to understand.

To see more of my work, check out my:

- [GitHub Profile](https://github.com/marmag0)
- [LinkedIn Profile](https://www.linkedin.com/in/mikolaj-mazur)
