#!/usr/bin/env bash
# This script runs after the Dev Container is created.
# It installs tools and configures the environment.

# Exit immediately if a command exits with a non-zero status.
set -e

echo "--- Starting Post-Create Setup ---"

# Install Containerlab
echo "[1/6] Installing Containerlab..."
sudo bash -c "$(curl -sL https://get.containerlab.dev)"
echo "Containerlab installation complete."

# Create Python virtual environment directory & set ownership
echo "[2/6] Setting up Python virtual environment directory..."
sudo mkdir -p /home/admin/ansible-venv
sudo chown admin:admin /home/admin/ansible-venv
echo "Virtual environment directory created."

# Create Python virtual environment
echo "[3/6] Creating Python virtual environment..."
python3 -m venv /home/admin/ansible-venv
echo "Virtual environment created at /home/admin/ansible-venv."

# Activate venv and install packages/collections
echo "[4/6] Activating venv and installing Python packages & Ansible collections..."
source /home/admin/ansible-venv/bin/activate

echo "Upgrading pip..."
pip install --upgrade pip
echo "Installing ansible-core, AVD dependencies, and linters..."
pip install ansible-core==2.15.* pyavd pyeapi netaddr yamllint ansible-lint
echo "Installing Ansible collections..."
ansible-galaxy collection install arista.avd arista.eos

echo "Python packages and Ansible collections installed."

# Add venv activation to shell profile for new terminals
echo "[5/6] Configuring shell profile (.zshrc) for automatic venv activation..."
echo "" >> /home/admin/.zshrc
echo "# Activate Ansible virtual environment automatically" >> /home/admin/.zshrc
echo "source /home/admin/ansible-venv/bin/activate" >> /home/admin/.zshrc
echo "Shell profile updated."

# Attempt to auto-import local cEOS image if present and remove original
echo "[6/6] Checking for local cEOS image file in /workspace..."
# Search for files like cEOS*.tar, cEOS*.tar.gz, cEOS*.tar.xz case-insensitively
IMAGE_FILE=$(find /workspace -maxdepth 1 -regextype posix-extended -iregex "/workspace/[cC]EOS.*\.tar(\.gz|\.xz)?" -print -quit)

if [ -n "${IMAGE_FILE}" ]; then
    echo "Found potential image file: ${IMAGE_FILE}"
    # Check if ceos:latest tag already exists
    if ! docker image inspect ceos:latest > /dev/null 2>&1 ; then
        echo "ceos:latest image not found. Attempting import..."
        # Import the found file and tag it as ceos:latest
        docker import "${IMAGE_FILE}" ceos:latest
        echo "Successfully imported ${IMAGE_FILE} as ceos:latest."
        # Remove original file after successful import
        echo "Removing original file: ${IMAGE_FILE}"
        rm -f "${IMAGE_FILE}"
        echo "Original file removed."
    else
        # If ceos:latest already exists, skip import
        echo "ceos:latest image already exists. Skipping import."
    fi
else
    # If no matching file found
    echo "No local cEOS image file found matching pattern '[cC]EOS*.tar*' in /workspace."
fi

# Deactivate the virtual environment for the remainder of this script's execution if needed
# deactivate

echo "--- Post-Create Setup Finished ---"

