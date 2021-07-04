# ArchiveBox

Open source self-hosted web archiving. Takes URLs/browser history/bookmarks/Pocket/Pinboard/etc., saves HTML, JS, PDFs, media, and more...

<!-- TOC -->

- [ArchiveBox](#archivebox)
  - [Installation](#installation)
    - [Connecting to VM with SSH](#connecting-to-vm-with-ssh)
    - [Configuring ArchiveBox](#configuring-archivebox)
  - [Docker Compose](#docker-compose)
  - [References](#references)

<!-- /TOC -->

## Installation

### Connecting to VM with SSH

Connect to our VM with SSH, then change working directory to `~/docker/archivebox`.

### Configuring ArchiveBox

Before starting the container with `docker-compose up`, we need to initialize and configure ArchiveBox. The configuration file is saved within the container as `/data/ArchiveBox.conf`.

Initialize and configure ArchiveBox. You will be prompted to create a superuser account.

```bash
/root/bin/docker-compose run --rm archivebox init --setup
/root/bin/docker-compose run --rm archivebox config --set OUTPUT_PERMISSIONS=644
/root/bin/docker-compose run --rm archivebox config --set SAVE_WGET=False SAVE_WARC=False SAVE_SCREENSHOT=False SAVE_DOM=False SAVE_READABILITY=False SAVE_MERCURY=False SAVE_GIT=False SAVE_MEDIA=False
```

## Docker Compose

```yaml
# Usage:
#     docker-compose run archivebox init --setup
#     docker-compose up
#     echo "https://example.com" | docker-compose run archivebox archivebox add
#     docker-compose run archivebox add --depth=1 https://example.com/some/feed.rss
#     docker-compose run archivebox config --set PUBLIC_INDEX=True
#     docker-compose run archivebox help
# Documentation:
#     https://github.com/ArchiveBox/ArchiveBox/wiki/Docker#docker-compose

version: '2.4'

services:
    archivebox:
        # build: .                              # for developers working on archivebox
        image: ${DOCKER_IMAGE:-archivebox/archivebox:latest}
        command: server --quick-init 0.0.0.0:8000
        ports:
            - 8000:8000
        environment:
            - ALLOWED_HOSTS=*                   # add any config options you want as env vars
            - MEDIA_MAX_SIZE=750m
            # - SEARCH_BACKEND_ENGINE=sonic     # uncomment these if you enable sonic below
            # - SEARCH_BACKEND_HOST_NAME=sonic
            # - SEARCH_BACKEND_PASSWORD=SecretPassword
        volumes:
            - ./data:/data
            # - ./archivebox:/app/archivebox    # for developers working on archivebox

    # To run the Sonic full-text search backend, first download the config file to sonic.cfg
    # curl -O https://raw.githubusercontent.com/ArchiveBox/ArchiveBox/master/etc/sonic.cfg
    # after starting, backfill any existing Snapshots into the index: docker-compose run archivebox update --index-only
    # sonic:
    #    image: valeriansaliou/sonic:v1.3.0
    #    expose:
    #        - 1491
    #    environment:
    #        - SEARCH_BACKEND_PASSWORD=SecretPassword
    #    volumes:
    #        - ./sonic.cfg:/etc/sonic.cfg:ro
    #        - ./data/sonic:/var/lib/sonic/store


    ### Optional Addons: tweak these examples as needed for your specific use case

    # Example: Run scheduled imports in a docker instead of using cron on the
    # host machine, add tasks and see more info with archivebox schedule --help
    # scheduler:
    #    image: archivebox/archivebox:latest
    #    command: schedule --foreground --every=day --depth=1 'https://getpocket.com/users/USERNAME/feed/all'
    #    environment:
    #        - USE_COLOR=True
    #        - SHOW_PROGRESS=False
    #    volumes:
    #        - ./data:/data

    # Example: Put Nginx in front of the ArchiveBox server for SSL termination
    # nginx:
    #     image: nginx:alpine
    #     ports:
    #         - 443:443
    #         - 80:80
    #     volumes:
    #         - ./etc/nginx/nginx.conf:/etc/nginx/nginx.conf
    #         - ./data:/var/www

    # Example: run all your ArchiveBox traffic through a WireGuard VPN tunnel
    # wireguard:
    #   image: linuxserver/wireguard
    #   network_mode: 'service:archivebox'
    #   cap_add:
    #     - NET_ADMIN
    #     - SYS_MODULE
    #   sysctls:
    #     - net.ipv4.conf.all.rp_filter=2
    #     - net.ipv4.conf.all.src_valid_mark=1
    #   volumes:
    #     - /lib/modules:/lib/modules
    #     - ./wireguard.conf:/config/wg0.conf:ro

    # Example: Run PYWB in parallel and auto-import WARCs from ArchiveBox
    # pywb:
    #     image: webrecorder/pywb:latest
    #     entrypoint: /bin/sh 'wb-manager add default /archivebox/archive/*/warc/*.warc.gz; wayback --proxy;'
    #     environment:
    #         - INIT_COLLECTION=archivebox
    #     ports:
    #         - 8080:8080
    #     volumes:
    #         ./data:/archivebox
    #         ./data/wayback:/webarchive
```

## References

