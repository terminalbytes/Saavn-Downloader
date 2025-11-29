FROM python:3.8-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    iptables \
    procps \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Install Tailscale
RUN curl -fsSL https://tailscale.com/install.sh | sh

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY scripts/ ./scripts/
COPY download_reloaded.py .
COPY urls.txt .
COPY check-url.sh .

# Copy entrypoint script
COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Create tailscale state directory
RUN mkdir -p /var/lib/tailscale

ENV PYTHONUNBUFFERED=1
ENV TS_EXIT_NODE=indian
ENV POLL_INTERVAL=120

ENTRYPOINT ["/entrypoint.sh"]
