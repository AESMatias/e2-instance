### Tailscale connection, configuration and running

**Important!**

When configuring the connection target in this script, it is strongly recommended to use the **MagicDNS or hostname** (e.g., `myserver` or `myserver.tail-scale.ts.net`) rather than hardcoding the specific Tailscale IP address (e.g., `100.x.y.z`).

While Tailscale IP addresses are generally stable for a specific device installation, they can change under some circumstances, If the Tailscale client is fully uninstalled and re-installed, or if the node key expires and the device is re-authenticated as a "new" device, it may be assigned a different IP. ALso, moving a device between certain ACL tags or ownership changes might occasionally result in addressing changes depending on your tailnet configuration.