#!/bin/zsh

# ==================================================================
# ADB wireless pairing/connecting via QR code — zero typing.
#   1. Clears proxy env so adb's local traffic is never routed away.
#   2. Tries to reconnect to the last saved device first.
#   3. Falls back to showing a QR code in the terminal. Scan it with
#      [Wireless debugging -> Pair device with QR code] and the script
#      auto-discovers the phone over mDNS, pairs, and connects.
# ==================================================================

# 1. Forcefully unset all proxy variables in this script's environment
unset http_proxy https_proxy all_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY
export no_proxy="localhost,127.0.0.1,192.168.0.0/16"
export NO_PROXY="localhost,127.0.0.1,192.168.0.0/16"

LAST_FILE="$(dirname "$0")/.adb_last_connect"

echo "🔄 Resetting ADB server to clear proxy cache..."
adb kill-server >/dev/null 2>&1
adb start-server >/dev/null 2>&1

# ------------------------------------------------------------------
# Helper: try to connect to a target, save it on success.
# ------------------------------------------------------------------
try_connect() {
    local target="$1"
    [[ -z "$target" ]] && return 1
    local out
    out=$(adb connect "$target" 2>&1)
    if echo "$out" | grep -qiE "connected to"; then
        echo "$target" > "$LAST_FILE"
        echo "✅ Connected to $target"
        adb devices
        return 0
    fi
    return 1
}

# ------------------------------------------------------------------
# Helper: poll `adb mdns services` for a service type, return IP:port.
#   $1 = service type substring (pairing / connect)
#   $2 = timeout seconds
# ------------------------------------------------------------------
find_mdns() {
    local type="$1" timeout="$2" i=0 line
    while (( i < timeout )); do
        # fields are TAB-separated; last field ($NF) is IP:port
        line=$(adb mdns services 2>/dev/null | grep "$type" | tail -1 | awk '{print $NF}')
        if [[ -n "$line" ]]; then
            echo "$line"
            return 0
        fi
        sleep 1
        (( i++ ))
    done
    return 1
}

# ------------------------------------------------------------------
# Step A: try to reconnect to the last device (no interaction).
# ------------------------------------------------------------------
if [[ -f "$LAST_FILE" ]]; then
    last="$(cat "$LAST_FILE")"
    echo "\n🔌 Trying to reconnect to last device: $last ..."
    if try_connect "$last"; then
        exit 0
    fi
    echo "⚠️  Reconnect failed (port usually changes) — showing QR code instead."
fi

# ------------------------------------------------------------------
# Step B: QR-code pairing.
# ------------------------------------------------------------------
NAME="debug-$(LC_ALL=C tr -dc 'a-f0-9' </dev/urandom | head -c 8)"
PASS="$(LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c 12)"
QR="WIFI:T:ADB;S:${NAME};P:${PASS};;"

echo "\n=================================================================="
echo "📱 On the phone open:  Wireless debugging -> Pair device with QR code"
echo "   Then point the camera at the QR code below."
echo "==================================================================\n"

qrencode -t ANSIUTF8 "$QR"

echo "\n🔎 Waiting for the phone to appear over mDNS (up to 60s)..."
PAIR_ADDR=$(find_mdns "_adb-tls-pairing" 60)

if [[ -z "$PAIR_ADDR" ]]; then
    echo "❌ Timed out. No pairing service found."
    echo "   Check that Mac and phone are on the same Wi-Fi and try again."
    exit 1
fi

echo "🤝 Found pairing service at $PAIR_ADDR — pairing..."
if ! adb pair "$PAIR_ADDR" "$PASS"; then
    echo "❌ Pairing failed."
    exit 1
fi
echo "✅ Paired."

# ------------------------------------------------------------------
# Step C: discover the connect service and connect.
# ------------------------------------------------------------------
echo "🔎 Looking for the connect endpoint over mDNS..."
CONNECT_ADDR=$(find_mdns "_adb-tls-connect" 30)

if [[ -n "$CONNECT_ADDR" ]] && try_connect "$CONNECT_ADDR"; then
    exit 0
fi

# Fallback: same IP as pairing usually works if connect service is slow to show.
CONNECT_IP="${PAIR_ADDR%%:*}"
echo "\nℹ️  Auto-connect endpoint not found via mDNS."
echo "   Look at the main [Wireless debugging] page for [IP:Port] (IP is likely ${CONNECT_IP})."
read "manual?Enter [IP:Port] to connect (Enter to skip): "
if [[ -n "$manual" ]] && try_connect "$manual"; then
    exit 0
fi

echo "❌ Not connected yet. Re-run the script if needed."
exit 1
