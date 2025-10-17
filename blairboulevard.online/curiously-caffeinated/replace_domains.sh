#!/bin/bash

# ===== CONFIG =====
TARGET_DOMAIN="blairboulevard.online"
SEARCH_DOMAINS=(
  "cdnedu.online"
  "blair.boulebard.online"
  "blair.boulevard.whispr.dev"
  "blair.boulevard.mail.whispr.dev"
)

# Default directories to search
SEARCH_PATHS=(
  "/etc/nginx"
  "/var/www"
  "/etc/letsencrypt"
  "/home/wofl/sites"
)

EXTENSIONS="conf|php|env|ini|json|xml|html|sh|js|css"

# ===== SCRIPT =====
echo "[*] Starting domain replacement script..."
echo "[*] Replacing all mentions of:"
for d in "${SEARCH_DOMAINS[@]}"; do echo "    $d"; done
echo "[*] With:"
echo "    $TARGET_DOMAIN"
echo

for DIR in "${SEARCH_PATHS[@]}"; do
  echo "[*] Scanning $DIR..."
  find "$DIR" -type f -regextype posix-extended -regex ".*\.($EXTENSIONS)$" | while read -r file; do
    FOUND=0
    TMPFILE="$(mktemp)"
    cp "$file" "$TMPFILE"
    for domain in "${SEARCH_DOMAINS[@]}"; do
      if grep -q "$domain" "$file"; then
        FOUND=1
        sed -i.bak "s|$domain|$TARGET_DOMAIN|g" "$file"
      fi
    done
    if [ "$FOUND" -eq 1 ]; then
      echo "    [+] Replaced domain(s) in: $file"
    else
      rm -f "$file.bak"
    fi
    rm -f "$TMPFILE"
  done
done

echo
echo "[✓] Replacement complete. All modified files backed up as .bak"
echo "    You may want to run: sudo nginx -t && sudo systemctl reload nginx"
