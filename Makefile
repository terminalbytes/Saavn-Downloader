.PHONY: build up down rebuild logs shell status clean

# Build the Docker image
build:
	docker compose build

# Start the container (detached, always rebuilds)
up:
	docker compose up -d --build

# Stop the container
down:
	docker compose down

# Rebuild and restart
rebuild:
	docker compose down
	docker compose build
	docker compose up -d

# Tail logs
logs:
	docker compose logs -f

# Shell into running container
shell:
	docker compose exec saavn-downloader /bin/bash

# Show container status
status:
	docker compose ps

# Show tailscale status inside container
ts-status:
	docker compose exec saavn-downloader tailscale status

# Trigger immediate download (without waiting for poll)
run-now:
	docker compose exec saavn-downloader python /app/download_reloaded.py -o /mnt/storage-box/music -f /app/urls.txt

# Remove containers and volumes
clean:
	docker compose down -v
	docker rmi saavn-downloader_saavn-downloader 2>/dev/null || true
