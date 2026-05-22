# anvil

Custom n8n Docker image that adds **Docker CLI** and **rclone** to the official
[n8n](https://n8n.io) image. Designed for CasaOS but works anywhere.

**Docker CLI** enables Docker-outside-of-Docker (DooD) — n8n workflows can run
`docker` commands on the host by mounting `/var/run/docker.sock`.

**rclone** enables cloud storage sync (Google Drive, S3, Backblaze, etc.) from
within n8n workflows.

## What's Included

| Tool       | Purpose                                  |
| ---------- | ---------------------------------------- |
| Docker CLI | Run containers from n8n (DooD pattern)   |
| rclone     | Sync files to/from cloud storage         |
| curl       | HTTP requests from Execute Command nodes |
| unzip      | Archive extraction                       |

## CasaOS Installation

### 1. Build the image and export as tar

```bash
# On any machine with Docker installed
git clone https://github.com/code-lodge/anvil.git
cd anvil

docker build -t n8n-with-docker .
docker save -o n8n-with-docker.tar n8n-with-docker:latest
```

### 2. Import to CasaOS

1. Copy `n8n-with-docker.tar` to your CasaOS machine
2. Load the image:
   ```bash
   docker load -i n8n-with-docker.tar
   ```
3. In CasaOS, go to **Apps** → **Install a customized app** → import `casaos-n8n.yml`

### 3. Verify

```bash
docker exec n8n docker --version
docker exec n8n rclone --version
```

## CasaOS Configuration

The included `casaos-n8n.yml` sets up:

- **Image**: `n8n-with-docker:latest`
- **Port**: 5678 (n8n web UI)
- **Volumes**:
  - `/var/run/docker.sock` → Docker socket (DooD)
  - `/DATA/Data` → `/home/node/data` (persistent data)
  - `/DATA/AppData/n8n` → `/home/node/.n8n` (n8n config + database)

### Adding environment variables

Add n8n environment variables by editing the app in CasaOS or adding them to
the `environment` section of `casaos-n8n.yml` before import.

## rclone Setup (Google Drive)

rclone config is stored under `/home/node/data/rclone/rclone.conf`, which maps
to `/DATA/Data/rclone/rclone.conf` on the CasaOS host — it survives container
rebuilds automatically.

**Initial authentication (run once):**

```bash
docker exec -it -e RCLONE_CONFIG=/home/node/data/rclone/rclone.conf \
  n8n rclone config
```

> If your CasaOS machine is headless (no browser), run with port forwarding:
>
> ```bash
> docker run --rm -it -p 53682:53682 \
>   -v /DATA/Data:/home/node/data \
>   n8n-with-docker:latest \
>   rclone config --config /home/node/data/rclone/rclone.conf
> ```
>
> Open the URL rclone prints on any machine with a browser.

In the wizard:

1. `n` → new remote
2. Name: `gdrive`
3. Storage: `drive` (Google Drive)
4. Scope: `drive` (full access)
5. Leave client_id / client_secret blank
6. `y` to auto config → authenticate in browser

**Verify:**

```bash
docker exec -e RCLONE_CONFIG=/home/node/data/rclone/rclone.conf \
  n8n rclone ls gdrive: --max-depth 1
```

**Reconnect expired token:**

```bash
docker exec -it -e RCLONE_CONFIG=/home/node/data/rclone/rclone.conf \
  n8n rclone config reconnect gdrive:
```

## Non-CasaOS Usage

The image works with plain Docker or docker-compose:

```bash
docker build -t n8n-with-docker .

docker run -d \
  --name n8n \
  -p 5678:5678 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v n8n-data:/home/node/data \
  -v n8n-config:/home/node/.n8n \
  n8n-with-docker:latest
```

## Updating n8n

When a new n8n version is released:

```bash
docker build --no-cache -t n8n-with-docker .
docker save -o n8n-with-docker.tar n8n-with-docker:latest
docker load -i n8n-with-docker.tar  # on CasaOS machine
```

Then restart the container in CasaOS. Your data, workflows, and rclone config
are all stored on persistent volumes and survive the update.

## Workflows That Use This Image

- [stashify](https://github.com/code-lodge/stashify) — Automated Shopify store backup & restore
- [fossil](https://github.com/code-lodge/fossil) — Website archival with ArchiveBox

## Files

```
.
├── Dockerfile        # n8n + Docker CLI + rclone
├── casaos-n8n.yml    # CasaOS app definition
├── LICENSE           # GPL-3.0-or-later
└── README.md         # This file
```

## License

[GNU General Public License v3.0 or later](LICENSE)
