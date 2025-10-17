sudo tee /opt/diag/diags_blair.sh >/dev/null <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
DOMAINS=("blairboulevard.online" "n8n.blairboulevard.online")

echo "=== System & network quick facts ==="
echo "Hostname: $(hostname -f || hostname)"
echo "Kernel: $(uname -a)"
echo "Uptime: $(uptime -p)"
echo

echo "=== Public IPs (egress as seen from server) ==="
( curl -4 -s https://ifconfig.io || true ) | sed 's/^/IPv4: /'
( curl -6 -s https://ifconfig.io || true ) | sed 's/^/IPv6: /'
echo

echo "=== Open listeners for 80/443 (host) ==="
sudo ss -tulpn | awk '/:80 |:443 /{print}' || true
echo

command -v dig >/dev/null || { echo "installing dnsutils..."; sudo apt-get update -y && sudo apt-get install -y dnsutils >/dev/null; }

for d in "${DOMAINS[@]}"; do
  echo "=== DNS for ${d} ==="
  echo "- A records:";    dig +short A "${d}"     | sed 's/^/  /' || true
  echo "- AAAA records:"; dig +short AAAA "${d}" | sed 's/^/  /' || true
  echo
done

echo "=== UFW status (if enabled) ==="
sudo ufw status verbose || true
echo

echo "=== Docker: running containers and published ports ==="
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"
echo

CADDY_ID="$(docker ps --format '{{.ID}} {{.Image}} {{.Names}}' | awk 'tolower($0) ~ /caddy/ {print $1; exit}')"
if [ -n "${CADDY_ID:-}" ]; then
  echo "=== Caddy logs (last 120) ==="
  docker logs --tail=120 "${CADDY_ID}" || true
else
  echo "=== No container with 'caddy' in name/image detected ==="
fi
echo

echo "=== Local HTTP probe ==="
( curl -4 -s -o /dev/null -w 'HTTP/1.1 %{http_code}\n' http://127.0.0.1/ ) || echo "HTTP on 127.0.0.1 failed"
echo

echo "=== Local HTTPS probe with SNI ==="
( curl -4 -vkI --connect-timeout 5 --resolve blairboulevard.online:443:127.0.0.1 https://blairboulevard.online/ || true )
echo

echo "=== IPv6 HTTPS probe (often the culprit) ==="
( curl -6 -vkI --connect-timeout 5 https://blairboulevard.online/ || true )
echo

echo "=== Done. Paste this output back to me. ==="
EOF

sudo chmod +x /opt/diag/diags_blair.sh
/opt/diag/diags_blair.sh
