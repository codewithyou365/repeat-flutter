#!/bin/zsh

# 1. Forcefully unset all proxy variables in this script's environment
unset http_proxy https_proxy all_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY
export no_proxy="localhost,127.0.0.1,192.168.0.0/16"
export NO_PROXY="localhost,127.0.0.1,192.168.0.0/16"

echo "🔄 Resetting ADB server to clear proxy cache..."
adb kill-server
adb start-server

echo "------------------------------------------------"
echo "📱 Make sure your phone and Mac are on the same Wi-Fi,"
echo "   and open [Wireless debugging -> Pair device with pairing code]"
echo "------------------------------------------------"

# 2. Interactive prompt for IP:Port and Pairing Code
read "ip_port?Enter the [IP:Port] shown on your phone (e.g., 192.168.1.101:39289): "
read "pairing_code?Enter the 6-digit [Pairing Code] (e.g., 498936): "

if [[ -z "$ip_port" || -z "$pairing_code" ]]; then
    echo "❌ Error: IP:Port or Pairing Code cannot be empty!"
    exit 1
fi

echo "\n🚀 Starting pairing process for $ip_port ..."

# 3. Use 'expect' to automate code injection to prevent handshake timeouts
if command -v expect &> /dev/null; then
    expect -c "
        spawn adb pair $ip_port
        expect \"Enter pairing code:\"
        send \"$pairing_code\r\"
        expect eof
    "
else
    # Fallback to standard pairing if 'expect' is not installed
    echo "💡 Note: 'expect' tool not found. Please enter the code manually when prompted below."
    adb pair "$ip_port"
fi

echo "\n🎉 Pairing process finished."
echo "👉 Check your phone for the NEW Wireless Debugging Port (it usually changes after pairing) and run 'adb connect IP:NEW_PORT'."