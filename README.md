# VPN Shield

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Xray](https://img.shields.io/badge/Xray-1.8+-blue.svg)](https://github.com/XTLS/Xray-core)

**VPN Shield** - Advanced VPN solution with automatic site masquerading and intelligent traffic routing. Built with Xray-core REALITY protocol for maximum stealth and performance.

## 🌟 Key Features

### 🛡️ REALITY Protocol
- Indistinguishable from regular HTTPS traffic
- Automatic masquerading under popular websites
- Bypasses Deep Packet Inspection (DPI)
- No detectable VPN signatures

### 🤖 Fully Automatic
- **One-command installation** - No configuration needed
- **Auto site selection** - Finds working masquerade sites automatically
- **Self-healing** - Monitors and switches sites every 3 minutes
- **Zero maintenance** - Works completely autonomously

### 🎯 Smart Features
- Automatic connection link generation
- QR code support for mobile devices
- Real-time monitoring and auto-recovery
- Optimized network settings (BBR congestion control)

### 📱 Universal Client Support
- **iOS**: Shadowrocket, V2Box, Streisand
- **Android**: v2rayNG, NekoBox, Hiddify
- **Windows**: v2rayN, Nekoray, Hiddify
- **macOS**: V2rayU, Qv2ray, Hiddify
- **Linux**: Qv2ray, Nekoray

## 🚀 Quick Start

### Requirements

- VPS with Debian 11+ or Ubuntu 20.04+
- Minimum 1GB RAM, 1 CPU core
- Root access
- Public IP address

### Installation (One Command)

```bash
wget -O - https://raw.githubusercontent.com/sjgagahvabw/vpn-shield/main/auto-vpn-install.sh | bash
```

That's it! The script will:
- ✅ Install Xray-core automatically
- ✅ Find working masquerade site
- ✅ Generate secure keys
- ✅ Configure firewall
- ✅ Optimize network (BBR)
- ✅ Setup auto-monitoring
- ✅ **Give you ready-to-use connection link**

### What You Get

After installation completes, you'll see:

```
📱 CONNECTION LINK:
vless://uuid@your-ip:443?encryption=none&flow=xtls-rprx-vision...

🤖 AUTOMATIC MONITORING ENABLED
  ✓ VPN checked every 3 minutes
  ✓ Auto-switches sites if blocked
  ✓ Auto-restarts on failures
  ✓ Link always updated in: /root/vpn-shield/connection.txt
```

Just copy the link and paste it into your VPN app!

## 📖 How It Works

### Automatic Site Masquerading

VPN Shield automatically tests and selects from popular sites:
- Microsoft, Apple, Cloudflare
- Amazon, Cisco, Oracle
- Zoom, Booking, Speedtest
- And more...

The system picks the first working site and masks your VPN traffic as regular HTTPS to that site.

### Self-Healing System

Every 3 minutes, the monitor:
1. Checks if Xray is running
2. Tests if current masquerade site is accessible
3. If blocked → automatically finds new working site
4. Updates configuration and restarts
5. Updates connection link automatically

**You never need to touch the server again!**

## 🔧 Management

### Check Status
```bash
systemctl status xray                    # VPN status
systemctl status vpn-shield-monitor.timer # Monitor status
```

### View Logs
```bash
tail -f /var/log/vpn-shield-monitor.log  # Monitor logs
journalctl -u xray -f                     # Xray logs
```

### Get Current Link
```bash
cat /root/vpn-shield/connection.txt      # Always up-to-date link
```

### Manual Site Switch
```bash
/usr/local/bin/vpn-monitor.sh            # Force check and switch
```

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    VPN Shield System                     │
├─────────────────────────────────────────────────────────┤
│                                                           │
│  ┌──────────────┐         ┌──────────────┐             │
│  │  Xray-core   │◄───────►│   Monitor    │             │
│  │  (REALITY)   │         │  (Auto-heal) │             │
│  └──────┬───────┘         └──────────────┘             │
│         │                                                │
│         │ Masquerades as                                │
│         ▼                                                │
│  ┌──────────────┐                                       │
│  │ Popular Site │ (Microsoft, Apple, etc.)             │
│  │  (HTTPS)     │                                       │
│  └──────────────┘                                       │
│                                                           │
└─────────────────────────────────────────────────────────┘
```

## 🔒 Security

- **X25519 key exchange** - Strong cryptography
- **TLS 1.3** - Modern encryption
- **REALITY protocol** - Zero VPN fingerprints
- **Automatic key generation** - Unique per installation
- **BBR congestion control** - Optimized performance

## 📊 Performance

- **Latency**: Near-native (< 5ms overhead)
- **Throughput**: Up to 1 Gbps
- **Concurrent connections**: 1000+
- **Memory usage**: ~50MB idle
- **CPU usage**: ~5% idle

## 🛠️ Advanced Configuration

All configuration is in `/usr/local/etc/xray/config.json`

To manually change masquerade site:
```bash
nano /usr/local/etc/xray/config.json
# Edit "dest" and "serverNames" fields
systemctl restart xray
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## ⚠️ Disclaimer

This software is provided for educational and research purposes. Users are responsible for complying with local laws and regulations.

## 🙏 Acknowledgments

- [Xray-core](https://github.com/XTLS/Xray-core) - The core VPN engine
- [REALITY Protocol](https://github.com/XTLS/REALITY) - Stealth technology
- All contributors and users

## 📞 Support

- 📖 [Documentation](https://github.com/sjgagahvabw/vpn-shield/wiki)
- 🐛 [Issue Tracker](https://github.com/sjgagahvabw/vpn-shield/issues)
- 💬 [Discussions](https://github.com/sjgagahvabw/vpn-shield/discussions)

---

**Made with ❤️ for internet freedom**
