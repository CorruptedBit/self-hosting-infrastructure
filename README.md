# Self-Hosting Infrastructure

Raspberry Pi 5 homelab with Docker Compose + Tailscale VPN

> **⚠️ Security Notice:** All services are accessible **only through Tailscale VPN**. No ports are exposed to the local network or internet. Direct LAN access is not available.

## Services
- **Caddy**: HTTPS reverse proxy with automatic TLS (Tailscale certificates)
- **Flame**: Self-hosted startpage for server applications and bookmarks
- **Immich**: Self-hosted photo and video backup solution (Google Photos alternative)
- **Lazydocker**: TUI for Docker container management and monitoring
- **Linkding**: Bookmark manager with tagging, archiving, and browser extensions
- **Memos**: Open-source knowledge management and note-taking platform
- **Nextcloud**: Full stack with Nextcloud + Redis cache + MariaDB (not Nextcloud AIO)
- **Navidrome**: Open-source music server and streamer
- **PsiTransfer**: Simple file sharing service
- **Quartz v4**: Personal wiki and digital garden (static site generator)

## Stack
- Raspberry Pi 5 (8GB RAM)
- Docker + Docker Compose
- Tailscale VPN for secure remote access
- 1TB NVMe storage

## Security Architecture

This setup follows a **strict VPN-only access** model with network isolation:

- ✅ All services are accessible **only via Tailscale VPN**
- ✅ Caddy binds exclusively to the Tailscale IP address
- ✅ No ports exposed to LAN or public internet
- ✅ HTTPS with Tailscale-managed certificates
- ✅ Each service runs on a dedicated port on the Tailscale interface

**Access pattern:**
User → Tailscale VPN → Caddy (Tailscale IP) → Docker services

**Not possible:**
- ❌ Direct access from local LAN
- ❌ Public internet access
- ❌ Access without being connected to Tailscale

## Directory Structure

This repository should be cloned in `~/server/self-hosting/` on your server. The expected directory layout is:

```
~/server/
├── docker-data/           # Persistent data for all containers
│   ├── caddy/
│   ├── certs/             # Tailscale TLS certificates
│   ├── flame/
│   ├── immich/
│   ├── lazydocker/
│   ├── linkding/
│   ├── memos/
│   ├── navidrome/
|       ├── music/         # Music files go here
|       ├── ...
│   ├── nextcloud/
│   ├── psitransfer/
│   └── quartz/            # Wiki content (folders and .md files) goes here
└── self-hosting/          # This repository
    ├── .gitignore
    ├── README.md
    └── stacks/
        ├── caddy/
        ├── flame/
        ├── immich/
        ├── lazydocker/
        ├── linkding/
        ├── memos/
        ├── navidrome/
        ├── nextcloud/
        ├── psitransfer/
        └── quartz-wiki/
```

## Setup

### Prerequisites

1. **Tailscale installed and configured** on the Raspberry Pi
```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
```

2. Get your Tailscale configuration:
```bash
# Get your Tailscale domain
tailscale status
# Get your Tailscale IP
tailscale ip -4
```

3. Generate Tailscale TLS certificates (for Caddy HTTPS)
- Follow Tailscale's guide for certificate generation
- Certificates should be placed in `~/server/docker-data/certs/`

### Installation

```bash
# Clone the repository with submodules:
git clone --recursive https://github.com/CorruptedBit/self-hosting-infrastructure.git ~/server/self-hosting

# Or if already cloned without --recursive:
cd ~/server/self-hosting
git submodule init
git submodule update

# Create the data directories:
mkdir -p ~/server/docker-data/{caddy,certs,flame,lazydocker,linkding,memos,navidrome,nextcloud,immich,psitransfer,quartz}

# Configure environment variables:
# - Copy each .env.example to .env in the respective stack directory
# - Edit each .env file with your actual configuration (Tailscale domain, IP, paths, passwords)
```

#### Example for Caddy:
```bash
cd ~/server/self-hosting/stacks/caddy
cp .env.example .env
nano .env  # Edit with your Tailscale details
```

### Create the Docker network:
```bash
docker network create service-network
```

## Deploy services:
```bash
cd ~/server/self-hosting/stacks/<service-name>
docker compose up -d
```

### Recommended order:
1. Caddy (reverse proxy)
2. Other services (flame, immich, memos, nextcloud, etc.)

## Management

All services are managed via Docker Compose. Each service has its own compose.yaml file in its respective directory under `stacks/`.

### Container Monitoring

**Lazydocker** (CLI/TUI monitoring):
```bash
cd ~/server/self-hosting/stacks/lazydocker
docker compose run --rm lazydocker

# Or use the provided script (requires chmod +x first):
./start-lazydocker.sh
```

## Technical Notes

### Nextcloud Stack

The Nextcloud service uses a full custom stack (not Nextcloud AIO):
- Nextcloud container (custom build with ffmpeg for video previews)
- MariaDB 11.8 for database
- Redis 7.2 for caching and performance optimization

The Nextcloud container includes **ffmpeg** for video preview generation and supports the **Memories** app (photo management with timeline view).

**Setup procedure:**

1. **Deploy and access Nextcloud** (first time setup):
```bash
cd ~/server/self-hosting/stacks/nextcloud
docker compose up -d
```
Complete the initial Nextcloud setup via web interface.

2. Install the Memories app (highly recommended, but optional):
- Via Web UI: Nextcloud → Apps → Multimedia → Search "Memories" → Install
- Via CLI:
```bash
docker exec nextcloud-app php occ app:install memories
docker exec nextcloud-app php occ app:enable memories
```

3. Run the configuration script:
```bash
cd ~/server/self-hosting/stacks/nextcloud
chmod +x setup-previews.sh
./setup-previews.sh
```

4. What the script does:
- Verifies ffmpeg and ffprobe are installed in the container
- Enables preview generation for images, videos, and documents
- Sets ffmpeg and ffprobe path for Memories app (if installed)
- Sets video streaming to "Direct" mode (no transcoding) to save CPU resources in Memories app (if installed)

5. Configure Memories settings (Admin):
- Go to: Settings → Administration → Memories → Video Streaming
- Verify ffmpeg and ffprobe paths are correctly set
- Choose transcoding preferences:
  - Direct mode (default): No transcoding, streams original quality (recommended for Pi 5)
  - Transcoding enabled: Lower quality but saves bandwidth (higher CPU usage)

6. Generate the Memories index:
```bash
docker exec nextcloud-app php occ memories:index --user YOUR_NEXTCLOUD_USERNAME --force
```

**Note:** The default configuration uses "Direct" mode (no transcoding) to avoid CPU overhead on Raspberry Pi 5. Videos stream in original quality. You can change this in the Memories admin settings if needed.

### Quartz Wiki

Quartz is included as a Git submodule pointing to the official https://github.com/jackyzha0/quartz repository.

- The upstream Dockerfile runs Quartz in `--serve` mode (hot reload, ~350MB RAM)
- This is overridden in compose.yaml to use static mode with http-server (~50MB RAM)
- Static mode rebuilds the site once at startup and serves static files
- This significantly reduces memory and CPU usage (but you have to restart your stack to update the website for new entries)

To use the default serve mode (hot reload), comment out the custom command in `stacks/quartz-wiki/compose.yaml`.

## Service Access and Dashboard

### Direct Access (Via Tailscale)

Once connected to your **Tailscale VPN**, you can directly access each service using your Tailscale hostname and the respective port.

> **Note:** The port values below are defaults. You might have changed them in your **Caddy** configuration file (`~/server/self-hosting/stacks/caddy/Caddyfile`).

| Service | Access URL | Port |
| :--- | :--- | :--- |
| **Nextcloud** | `https://your-hostname.tailnetXXXXXX.ts.net:8080` | 8080 |
| **Immich** | `https://your-hostname.tailnetXXXXXX.ts.net:2283` | 2283 |
| **Linkding** | `https://your-hostname.tailnetXXXXXX.ts.net:9090` | 9090 |
| **Flame** | `https://your-hostname.tailnetXXXXXX.ts.net:5005` | 5005 |
| **Memos** | `https://your-hostname.tailnetXXXXXX.ts.net:5230` | 5230 |
| **Quartz Wiki** | `https://your-hostname.tailnetXXXXXX.ts.net:8081` | 8081 |
| **Navidrome** | `https://your-hostname.tailnetXXXXXX.ts.net:4533` | 4533 |
| **PsiTransfer** | `https://your-hostname.tailnetXXXXXX.ts.net:3000` | 3000 |

---

### Centralized Dashboard (Flame)

You can use **Flame** (`https://your-hostname.tailnetXXXXXX.ts.net:5005`) as your primary **static home page** to quickly access all your self-hosted applications and bookmarks.

**Docker Integration:**
The **Flame Docker integration** is enabled, allowing for automatic discovery and listing of services on the dashboard.

- **How it works:** Necessary `flame.*` labels have been added to the `compose.yaml` file of each service intended to be exposed (e.g., `nextcloud-app`, `immich-server`, `linkding`, `memos`).
- **Excluded Services:** Internal services, such as databases (e.g., `nextcloud-db`, `immich_postgres`) and caches (e.g., `immich_redis`), are intentionally excluded as they do not require dashboard access.

---
