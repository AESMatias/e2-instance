#!/bin/bash

'''To install Tailscale on the VPS:
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
tailscale ip -4
'''

VPS_IP="x.x.x.x" # Tailscale IP on the VPS)
VPS_USERNAME="username" # VPS username (username@hostname)

'''The Master key, is the key used to orchestrate all the devices via Tailscale, in this case will be the laptop.
The Master Key resides in the secure environment, not in the VPS, and will be "sended" everytime we login on the 
VPS via VPN on Tailscale.'''
MASTER_KEY="ssh-ed25519 asldkasd...." # .pub content of the master key
TS_AUTHKEY="tskey-auth-kXXXXXX..." # TAILSCALE AUTH KEY (for adding new devices automatically)

LOG_FILE="Instalation_log_$(date +%F_%H-%M).txt"

echo "***Detecting Linux distribution and package manager***"
PM="" # Package Manager
SSH_SERVICE=""
if command -v apt-get &> /dev/null; then
    PM="apt"; SSH_SERVICE="ssh"
elif command -v zypper &> /dev/null; then
    PM="zypper"; SSH_SERVICE="sshd"
elif command -v pacman &> /dev/null; then
    PM="pacman"; SSH_SERVICE="sshd"
elif command -v dnf &> /dev/null; then
    PM="dnf"; SSH_SERVICE="sshd"
elif command -v yum &> /dev/null; then
    PM="yum"; SSH_SERVICE="sshd"
else
    echo "Error: this distribution is not supported, or the package manager was not found, exiting."
    exit 1
fi
echo "***System detected, using: $PM package manager***"


exec > >(tee -i "$LOG_FILE")
exec 2>&1
echo "============================================="
echo "   ***STARTING AUTOMATED SETUP SCRIPT***"
echo "   DATE: $(date)"
echo "============================================="

echo "[1/5] Detecting system and basic tools..."
if [ "$EUID" -ne 0 ]; then 
  echo "Please run this script as root! (use sudo)"
  exit 1
fi


echo "Updating package lists and upgrading system..."
case "$PM" in
    apt)
        export DEBIAN_FRONTEND=noninteractive # To avoid interactive prompts during upgrade
        echo "Updating package lists (apt-get update and apt-get upgrade)..."
        apt-get update
        # Auto accept config file changes, keep old if conflicts:
        apt-get upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"
        ;;
    zypper)
        zypper refresh
        zypper update -y
        ;;
    pacman)
        pacman -Syu --noconfirm
        ;;
    dnf)
        dnf upgrade -y
        ;;
    yum)
        yum update -y
        ;;
esac

echo "[2/5] Installing Python and essential packages..."
case "$PM" in
    apt)
        # Debian/Ubuntu
        apt-get install -y python3 python3-pip python3-venv build-essential git openssh-server sudo curl
        ;;
    zypper)
        # openSUSE
        zypper install -y python3 python3-pip python3-venv gcc git openssh sudo curl
        ;;
    pacman)
        # Arch Linux
        pacman -S --noconfirm python python-pip base-devel git openssh sudo curl
        ;;
    dnf)
        # Fedora
        dnf install -y python3 python3-pip @development-tools git openssh-server sudo curl
        ;;
    yum)
        yum install -y python3 python3-pip git openssh-server sudo curl
        # CentOS/RHEL may require groupinstall for development tools:
        yum groupinstall -y "Development Tools"
        ;;
esac


echo "[3/5] Installing Tailscale..."
curl -fsSL https://tailscale.com/install.sh | sh
#tailscale up
tailscale up --authkey=$TS_AUTHKEY --hostname="$SUDO_USER-$(hostname)-device-$(date +%s)" --ssh


echo "[4/5] Setting up secure access and keys..."
USER_HOME=$(eval echo ~${SUDO_USER})
SSH_DIR="$USER_HOME/.ssh"
KEY_PATH="$SSH_DIR/id_ed25519"

# We lock the laptop's SSH so that only we can enter via Tailscale, using the Master key (Inbound)
mkdir -p "$SSH_DIR" # Create .ssh directory if it doesn't exist
echo "$MASTER_KEY" >> "$SSH_DIR/authorized_keys"
chmod 600 "$SSH_DIR/authorized_keys" # Only owner of the file can read and write
chmod 700 "$SSH_DIR" # Only owner can access the .ssh directory
chown -R $SUDO_USER:$SUDO_USER "$SSH_DIR" # Set ownership to the user, not root (we are running this script as root via sudo)

'''This forces all SSH connections to use keys only, so if someone tries to brute-force passwords, they won't be able to.
This also prevents that if the VPS is compromised, the attacker can't use password authentication to access the laptop.
Only devices with the private Master key can access the laptop via Tailscale, and the master key is not stored on the VPS'''

sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config

# Enable and restart SSH service to apply changes, the SSH runs over Tailscale interface (VPN)
systemctl enable $SSH_SERVICE
systemctl restart $SSH_SERVICE

echo "============================================="
echo "   ***THE SETUP IS COMPLETED***"
echo "============================================="
echo ""
echo "To access this device (presuming laptop) from the VPS as a jump host, use:"
echo "ssh -J $VPS_USERNAME@$VPS_IP $SUDO_USER@$(tailscale ip -4)"
echo "The -J flag tells ssh to use the VPS as a jump host. We dont use the -A flag for agent forwarding for security reasons
as it can expose your SSH keys if the VPS is compromised!"
echo "Your Tailscale IP on this device is: $(tailscale ip -4)"