#!/bin/bash

set -e 

SWAP_SIZE="2G"
SWAP_FILE="/swapfile"

echo "***Updating and upgrading the system***"
sudo apt update && sudo apt upgrade -y

echo "***Verifying if swap is already configured***"
# Detect ANY active swap (file or partition)
EXISTING_SWAP=$(swapon --noheadings --raw | awk '{print $1}')

# If existing swap is found, disable and remove it
if [ -n "$EXISTING_SWAP" ]; then
    echo "Existing swap detected: $EXISTING_SWAP"

    echo "***Disabling existing swap***"
    sudo swapoff -a

    # We create a backup of fstab before modifying it, in case something goes wrong
    sudo cp /etc/fstab /etc/fstab.bak
    sudo sed -i '/\bswap\b/d' /etc/fstab

    # Remove old swap files (never delete partitions)
    for s in $EXISTING_SWAP; do
        if [ -f "$s" ]; then
            sudo rm -f "$s"
        fi
    done
fi

echo "***Creating swap file of size $SWAP_SIZE***"
sudo fallocate -l $SWAP_SIZE $SWAP_FILE
sudo chmod 600 $SWAP_FILE
sudo mkswap $SWAP_FILE
sudo swapon $SWAP_FILE

echo "$SWAP_FILE none swap sw 0 0" | sudo tee -a /etc/fstab
echo "Swap file created and activated."

echo "***Cleaning up unnecessary packages***"
sudo apt autoremove -y
sudo apt clean

echo "INSTALLATION COMPLETED SUCCESSFULLY!"
echo "Current swap memory status:" # Show the final swap memory status
free -h