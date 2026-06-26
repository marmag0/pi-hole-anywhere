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

3. Add your server as a node to the Mesh. Choose a name for the node, install `warp-svc.service`, and verify that the node is visible in the Mesh dashboard. It should have been assigned a Mesh IP address (something like `100.96.x.x`).

![Cloudflare web UI screenshot - node connectivity](https://marmag0.github.io/endpoints/pi-hole-anywhere/cloudflare-mesh-ui-2.png)

4. Install the Cloudflare One client on your device that will access Pi-hole later (for DNS or configuration reasons). Full instructions can be found under the `Connect to your mesh` button.

![Cloudflare web UI screenshot - node connectivity](https://marmag0.github.io/endpoints/pi-hole-anywhere/cloudflare-mesh-ui-3.png)

5. Check connectivity within the Mesh, e.g. `ping -c 5 100.96.x.x` from one node to another.
6. Disable Cloudflare's DNS enforcement in the Mesh network: `Main Panel` >> `Protect & Connect` >> `Zero Trust` >> `Team & Resources` >> `Devices` >> `Device profiles` (Cloudflare by default enforces nodes in your mesh to use its `1.1.1.1` DNS server - it's a great server, but we want to use Pi-hole.)
7. When you see all device profiles, leave only Mesh Network Profile and Default enabled (if you haven't created any others manually), then click `...` >> `Configure` on `Mesh Network Profile`.

![Device profiles in Cloudflare Zero Trust - 1](https://marmag0.github.io/endpoints/pi-hole-anywhere/cloudflare-profile-1.png)

8. Scroll down to the `Service mode` section and select `Traffic only mode`.

![Device profiles in Cloudflare Zero Trust - 2](https://marmag0.github.io/endpoints/pi-hole-anywhere/cloudflare-profile-2.png)

9. If everything works, both nodes are online and you can ping them - you're ready for Pi-hole deployment!

10. **EXTRA:** If you're using one of Cloudflare's premium plans, you can set up a default DNS for your Mesh that points to Pi-hole's IP address; in that case, leave `Traffic and DNS mode` enabled.

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
2. Navigate to your domain's panel in Cloudflare, and add a `DNS A record` pointing to the Mesh IP of the Pi-hole server: `DNS` >> `Records` >> `Add record` (if you want, you can also add the same DNS record in your origin DNS manager).
3. Wait for the new DNS record to propagate, then verify it by entering its URL in your browser. If it connects to your Pi-hole, that means it works.
4. Now you (and only you) can access your Pi-hole web UI through an easily memorable URL. Even though the DNS A record is visible to everyone, they can't connect to your Mesh IP without being part of your mesh.

![Cloudflare DNS records manager](https://marmag0.github.io/endpoints/pi-hole-anywhere/cloudflare-dns-config.png)

### Start Using Pi-Hole

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

4. To use Pi-hole on your device, update the DNS server settings to the Pi-hole IP addresses. Many devices allow multiple DNS servers for redundancy, so you can enter:

```
LOCAL_IP
MESH_IP
```

5. This configuration lets your device try the local Pi-hole first. If your device is outside your LAN, it will use the Pi-hole Mesh IP instead.
6. If Pi-hole is unavailable entirely, DNS resolution may fall back to other resolvers and will not be filtered by Pi-hole. Adding a third DNS address such as `1.1.1.1` does not guarantee ordered use on modern systems, because many clients query all configured DNS servers in parallel.
7. If you want stronger enforcement of Pi-hole-first DNS resolution, consider using a client-side tool or firewall rule that forces DNS traffic through Pi-hole.

### Cleanup & Troubleshooting

- `docker compose down` - stop Pi-hole while preserving existing configuration.
- `docker compose down --volumes` - stop Pi-hole and remove containers, while leaving any created volumes intact.
- `./cleanup.sh` - script for full cleanup of Pi-hole. It stops the service and removes all saved data (good for hard resets).

## Extra

### Backups and Auto Updates

...

### Rolling out a Backup

...

### Easy CLI Blacklisting and Whitelisting

...

## The End

Thank you very much for exploring my repository! It took me a lot of time and effort to deliver such a detailed guide with useful (I guess) scripts. I hope it was useful and easy to understand.

To see more of my work, check out my:

- [GitHub Profile](https://github.com/marmag0)
- [LinkedIn Profile](https://www.linkedin.com/in/mikolaj-mazur)
