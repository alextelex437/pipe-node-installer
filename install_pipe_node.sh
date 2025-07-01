#!/bin/bash

echo ""
echo "🛠️ Starting Pipe POP Node Installation (v0.3.2)"
echo "📖 Please read carefully before proceeding:"
echo " - Recommended RAM for cache: 50–70% of total system RAM (e.g., 8GB => 4096–6144 MB)"
echo " - Recommended disk space for cache: 60–80% of available space"
echo " - Your identity info and wallet will be used for dashboard display and rewards"
echo ""

# Prompting user for configuration input
read -p "📛 Enter POP Node name (e.g., toanmb-node-1): " POP_NAME
read -p "🌍 Enter location (e.g., Frankfurt, Germany): " POP_LOCATION
read -p "📨 Enter your Invite Code (from Pipe Network): " INVITE_CODE

echo ""
read -p "📦 Enter RAM for cache in MB [Recommended: 4096–8192]: " CACHE_RAM
read -p "💾 Enter disk cache size in GB [Recommended: 100–300]: " CACHE_DISK

echo ""
read -p "🔑 Enter your Solana wallet address (for receiving rewards): " SOLANA_PUBKEY
read -p "👤 Enter your name (will appear on dashboard): " YOUR_NAME
read -p "📧 Enter your email address: " YOUR_EMAIL

# Update system and install dependencies
sudo apt update -y && sudo apt install -y libssl-dev ca-certificates curl net-tools

# Optimize kernel parameters for high-performance networking
sudo bash -c 'cat > /etc/sysctl.d/99-popcache.conf << EOL
net.ipv4.ip_local_port_range = 1024 65535
net.core.somaxconn = 65535
net.ipv4.tcp_low_latency = 1
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_wmem = 4096 65536 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.core.wmem_max = 16777216
net.core.rmem_max = 16777216
EOL'
sudo sysctl -p /etc/sysctl.d/99-popcache.conf

# Increase file descriptor limits
sudo bash -c 'cat > /etc/security/limits.d/popcache.conf << EOL
* hard nofile 65535
* soft nofile 65535
EOL'

# Create user and working directory
sudo useradd -m popcache || true
sudo mkdir -p /opt/popcache/logs
cd /opt/popcache

# Download and extract POP binary
wget https://download.pipe.network/static/pop-v0.3.2-linux-x64.tar.gz -O pop.tar.gz
tar -xzf pop.tar.gz
chmod +x pop
sudo chown -R popcache:popcache /opt/popcache

# Generate config.json based on user input
cat > /opt/popcache/config.json <<EOF
{
  "pop_name": "$POP_NAME",
  "pop_location": "$POP_LOCATION",
  "invite_code": "$INVITE_CODE",
  "server": {
    "host": "0.0.0.0",
    "port": 443,
    "http_port": 80,
    "workers": 0
  },
  "cache_config": {
    "memory_cache_size_mb": $CACHE_RAM,
    "disk_cache_path": "./cache",
    "disk_cache_size_gb": $CACHE_DISK,
    "default_ttl_seconds": 86400,
    "respect_origin_headers": true,
    "max_cacheable_size_mb": 1024
  },
  "api_endpoints": {
    "base_url": "https://dataplane.pipenetwork.com"
  },
  "identity_config": {
    "node_name": "$POP_NAME",
    "name": "$YOUR_NAME",
    "email": "$YOUR_EMAIL",
    "website": "",
    "twitter": "",
    "discord": "",
    "telegram": "",
    "solana_pubkey": "$SOLANA_PUBKEY"
  }
}
EOF

# Create systemd service for managing the node
sudo bash -c 'cat > /etc/systemd/system/popcache.service << EOL
[Unit]
Description=POP Cache Node
After=network.target

[Service]
Type=simple
User=popcache
Group=popcache
WorkingDirectory=/opt/popcache
ExecStart=/opt/popcache/pop
Restart=always
RestartSec=5
LimitNOFILE=65535
StandardOutput=append:/opt/popcache/logs/stdout.log
StandardError=append:/opt/popcache/logs/stderr.log
Environment=POP_CONFIG_PATH=/opt/popcache/config.json

[Install]
WantedBy=multi-user.target
EOL'

# Reload systemd and enable service on boot
sudo systemctl daemon-reload
sudo systemctl enable popcache

# Done!
echo ""
echo "✅ Pipe POP Node installation complete!"
echo "👉 You can edit your config file at: /opt/popcache/config.json"
echo "👉 Start your node: sudo systemctl start popcache"
echo "👉 View live logs: tail -f /opt/popcache/logs/stdout.log"
echo "👉 Check status: sudo systemctl status popcache"
