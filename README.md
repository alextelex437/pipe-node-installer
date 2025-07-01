# pipe-node-installer
Script to install Pipe POP Node (v0.3.2)
📋 Check Node Status Script
---

## 📋 Check Node Status Script

You can use the script below to quickly check the health and logs of your POP Node:

```bash
#!/bin/bash
echo "✅ Checking Pipe Node at: $(date)"

echo -e "\n[1] Systemd Status:"
systemctl status popcache --no-pager | head -20

echo -e "\n[2] Listening Ports:"
ss -tuln | grep -E ':80|:443|:8080'

echo -e "\n[3] Node Health:"
curl -s http://localhost/health | jq

echo -e "\n[4] Node State:"
curl -s http://localhost/state | jq

echo -e "\n[5] Node ID:"
curl -s http://localhost/state | jq '.pop_id'

echo -e "\n[6] Last 20 Logs:"
journalctl -u popcache -n 20 --no-pager
