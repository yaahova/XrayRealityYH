#!/bin/bash

echo "Installing dependencies..."

if ! command -v qrencode &> /dev/null
then
    if [ -f /etc/debian_version ]; then
        sudo apt update && sudo apt install qrencode -y
    elif [ -f /etc/redhat-release ]; then
        sudo yum install qrencode -y
    else
        exit 1
    fi
fi

if ! command -v xray &> /dev/null
then
    curl -s -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh | bash
fi

echo "Dependencies installed."

SERVER="172.86.93.67"
SERVER_PORT="443"
UUID="8e90c5bc-ae74-4dee-95ab-48768d356fba"
REALITY_PUBLIC_KEY="w8lk7x4G1whNuh9rMQlFHbo0YtXaD0JP6eLouLpPCGw"
REALITY_SHORT_ID="d5b96326a3a42f82"
TLS_SERVER_NAME="1.1.1.1"

DNS_SERVERS=("1.1.1.1" "8.8.8.8")
ROUTE="proxy"
RULES="geosite-category-ads-all"

INTERFACE_NAME="singbox_tun"
MTU="9000"
STRICT_ROUTE=true
AUTO_ROUTE=true

cat > xray.json << EOF
{
  "log": {
    "level": "warn",
    "timestamp": true
  },
  "dns": {
    "servers": [
      {
        "tag": "remote",
        "address": "1.1.1.1",
        "strategy": "prefer_ipv4",
        "detour": "proxy"
      },
      {
        "tag": "local",
        "address": "8.8.8.8",
        "strategy": "prefer_ipv4",
        "detour": "direct"
      }
    ],
    "rules": [
      {
        "server": "remote",
        "clash_mode": "Global"
      },
      {
        "server": "local",
        "domain_suffix": [".ir"],
        "rule_set": ["geosite-ir"]
      }
    ],
    "final": "remote"
  },
  "inbounds": [
    {
      "type": "tun",
      "tag": "tun-in",
      "interface_name": "${INTERFACE_NAME}",
      "address": ["172.18.0.1/30", "fdfe:dcba:9876::1/126"],
      "mtu": ${MTU},
      "auto_route": ${AUTO_ROUTE},
      "strict_route": ${STRICT_ROUTE},
      "stack": "system",
      "sniff": true
    }
  ],
  "outbounds": [
    {
      "type": "vless",
      "tag": "proxy",
      "server": "${SERVER}",
      "server_port": ${SERVER_PORT},
      "uuid": "${UUID}",
      "flow": "xtls-rprx-vision",
      "packet_encoding": "xudp",
      "tls": {
        "enabled": true,
        "server_name": "${TLS_SERVER_NAME}",
        "insecure": false,
        "alpn": ["h2", "http/1.1"],
        "utls": {
          "enabled": true,
          "fingerprint": "chrome"
        },
        "reality": {
          "enabled": true,
          "public_key": "${REALITY_PUBLIC_KEY}",
          "short_id": "${REALITY_SHORT_ID}"
        }
      }
    },
    {
      "type": "direct",
      "tag": "direct"
    },
    {
      "type": "block",
      "tag": "block"
    }
  ],
  "route": {
    "auto_detect_interface": true,
    "rules": [
      {
        "outbound": "proxy",
        "clash_mode": "Global"
      },
      {
        "outbound": "direct",
        "clash_mode": "Direct"
      },
      {
        "outbound": "direct",
        "ip_is_private": true
      },
      {
        "outbound": "proxy",
        "port_range": ["0:65535"]
      }
    ]
  },
  "experimental": {
    "cache_file": {
      "enabled": true,
      "path": "D:\\v2rayN-windows-64\\bin\\cache.db"
    }
  }
}
EOF

echo "xray.json configuration created."

CONFIG_VLESS="vless://$UUID@$SERVER:$SERVER_PORT?encryption=none&security=tls&flow=xtls-rprx-vision&headerType=none&route=proxy#yaahova"
echo "$CONFIG_VLESS" | qrencode -t UTF8

echo "$CONFIG_VLESS"
