#!/bin/bash

# Hỏi thông tin người dùng nhập vào
read -p "📛 Nhập tên POP Node (pop_name): " POP_NAME
read -p "🌍 Nhập vị trí địa lý (pop_location): " POP_LOCATION
read -p "📨 Nhập Invite Code: " INVITE_CODE
read -p "📦 Nhập RAM dành cho cache (MB): " CACHE_RAM
read -p "💾 Nhập dung lượng cache đĩa (GB): " CACHE_DISK
read -p "🔑 Nhập Solana ví nhận thưởng: " SOLANA_PUBKEY
read -p "👤 Tên người đại diện: " YOUR_NAME
read -p "📧 Email liên hệ: " YOUR_EMAIL

# Cài đặt gói cần thiết và tối ưu mạng
sudo apt update -y && sudo apt install -y libssl-dev ca-certificates curl net-tools

# Tối ưu cấu hình mạng
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

# Giới hạn file descriptor
sudo bash -c 'cat > /etc/security/limits.d/popcache.conf << EOL
* hard nofile 65535
* soft nofile 65535
EOL'

# Tạo user và thư mục cài node
sudo useradd -m popcache || true
sudo mkdir -p /opt/popcache/logs
cd /opt/popcache

# Tải POP node
wget https://download.pipe.network/static/pop-v0.3.2-linux-x64.tar.gz -O pop.tar.gz
tar -xzf pop.tar.gz
chmod +x pop
sudo chown -R popcache:popcache /opt/popcache

# Tạo file cấu hình config.json
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

# Tạo systemd service
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

# Kích hoạt dịch vụ
sudo systemctl daemon-reload
sudo systemctl enable popcache

# Hướng dẫn tiếp theo
echo ""
echo "✅ Đã hoàn tất cài đặt POP Node!"
echo "👉 Kiểm tra và chỉnh lại file nếu cần: sudo nano /opt/popcache/config.json"
echo "👉 Khi sẵn sàng, chạy lệnh sau để khởi động node:"
echo "   sudo systemctl start popcache"
echo "👉 Kiểm tra trạng thái node:"
echo "   sudo systemctl status popcache"
