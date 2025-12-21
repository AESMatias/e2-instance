#!/bin/bash

set -e 

SWAP_SIZE="2G"
SWAP_FILE="/swapfile"

echo "Updating and upgrading the system..."
sudo apt update && sudo apt upgrade -y


echo "Verifying if swap is already configured..."

if grep -q "$SWAP_FILE" /etc/fstab; then
    echo "The swap file is already configured in /etc/fstab. Skipping swap setup."
else
    echo " -> Creating swap file of size $SWAP_SIZE..."
    sudo fallocate -l $SWAP_SIZE $SWAP_FILE
    sudo chmod 600 $SWAP_FILE
    sudo mkswap $SWAP_FILE
    sudo swapon $SWAP_FILE
    
    # We create a backup of fstab before modifying it, just in case
    sudo cp /etc/fstab /etc/fstab.bak
    echo "$SWAP_FILE none swap sw 0 0" | sudo tee -a /etc/fstab
    
    echo "Swap file created and activated."
fi

echo " Instaling basic tools (htop, git, pip, curl)..."
sudo apt install -y htop git python3-pip curl wget unzip

echo "Cleaning up unnecessary packages..."
sudo apt autoremove -y
sudo apt clean

echo "   INSTALLATION COMPLETED SUCCESSFULLY! "
# Show the final swap memory status
echo "Current swap memory status:"
free -h