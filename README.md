# Pi-hole Anywhere with Cloudflare

This repository provides a step-by-step guide to deploying **Pi-hole** using **Docker** and **Cloudflare** services so you can access it from any location.

It uses a free tool called **Cloudflare Mesh** to restrict access to authorized users outside your LAN. This enables remote access to your Pi-hole while minimizing risk and without exposing your entire infrastructure.

For more information about **Pi-hole**, refer to its [web page](https://pi-hole.net), the [docker-pi-hole repository](https://github.com/pi-hole/docker-pi-hole), and the [official documentation](https://docs.pi-hole.net/docker/).

For more information about **Cloudflare Mesh**, refer to its [official documentation](https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-mesh/). Note that Mesh, while stable, is still considered beta and is under active development.

## Requirements

- **Basic requirements**
  - Docker installed (Docker Engine or Docker Desktop). See the [installation guide](https://docs.docker.com/engine/install/).
  - A free Cloudflare account - [create one here](https://www.cloudflare.com).
- **Requirements for the full experience**
  - A domain name you control.

## Deployment: Step-by-Step

### Environment Preparation

1. Clone this Git repository to your server and change your CWD to it.
2. Navigate to the Mesh panel in Cloudflare: `Protect & Connect` >> `Mesh` >> `Add node`.

![Cloudflare web UI screenshot - navigating to Mesh](https://marmag0.github.io/endpoints/pi-hole-anywhere/cloudflare-mesh-ui-1.png)

3. Add your server as a node to the Mesh. Choose its name (within mesh), install `warp-svc.service`, verify that the new node is visible within the Mesh dashboard. It should have been assigned a Mesh IP address (something like `100.96.x.x`).

![Cloudflare web UI screenshot - node connectivity](https://marmag0.github.io/endpoints/pi-hole-anywhere/cloudflare-mesh-ui-2.png)

4. Install Cloudflare One Client on your device, which should have access to Pi-hole in the future (for DNS or configuration reasons). Full instructions can be found under the `Connect to your mesh` button.

![Cloudflare web UI screenshot - node connectivity](https://marmag0.github.io/endpoints/pi-hole-anywhere/cloudflare-mesh-ui-3.png)

5. Check connectivity within the Mesh, e.g. `ping -c 5 100.96.x.x` from one node to another.
6. If everything works, both nodes are online and you can ping them - you're ready for Pi-hole deployment!

### Deploying Pi-hole with Docker

1. Make sure that Docker is running.
2. Set up environment variables inside the `.env` file:
   - `API_PASSWORD` - password used to access the Pi-hole dashboard; make sure it is strong.
   - `LOCAL_IP` - local IP address of your server.
   - `MESH_IP` - mesh IP address of your server.

```bash
API_PASSWORD=superHardPasswd
LOCAL_IP=yourPiHoleServerIpInHomeNetwork
MESH_IP=yourPiHoleServerIpInMeshNetwork
```

3. Deploy Pi-hole using the provided script and follow its instructions if they occur (recommended):
   - `./deploy.sh` - standard deployment, with logs displayed in the terminal (you can always switch it to detached mode by pressing `d`).
   - `./deploy.sh -d` - detached deployment.
   - Scripts must remain in the same folder as the `docker-compose.yml` file.

4. You can also run this yourself using:
   - `docker compose up`
   - `docker compose up -d` - consider adding `-d` so Docker does not block the terminal with logs.

5. Verify that Pi-hole is working:
   - Check that the Pi-hole web interface is accessible from both your local IP and Mesh IP.
   - If something goes wrong, check logs by attaching to the container: `docker compose attach pi-hole`.
     - Refer to [Cleanup & Troubleshooting](https://github.com/marmag0/pi-hole-anywhere#cleanup--troubleshooting) for further troubleshooting info.

![Pi-hole web UI logging screen](https://marmag0.github.io/endpoints/pi-hole-anywhere/pi-hole-login.png)

### Accessing Pi-hole via URL (optional)

1. To perform this step, **you'll need a domain name you control**.
2. ...

### Basic Pi-Hole Configuration and Integration

1. ...

### Cleanup & Troubleshooting

- `docker compose down` - stop Pi-hole while preserving existing configuration.
- `./cleanup.sh` - script for full cleanup of Pi-hole. It stops the service and removes all saved data (good for hard resets).

## Extra

### Backups and Auto Updates

...

### Rolling out a Backup

...

### Easy CLI Blacklisting and Whitelisting

...

## The End
