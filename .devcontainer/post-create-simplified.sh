#!/usr/bin/env bash
# This script runs after the Dev Container is created.
# Performs minimal setup needed when using a pre-built base image.

# Exit immediately if a command exits with a non-zero status.
set -e

echo "--- Starting Simplified Post-Create Setup ---"

# [1/4] Configure passwordless sudo for the 'avd' user
# This allows running commands like 'sudo clab ...' without a password prompt.
# Note: This assumes the 'avd' user exists and 'sudo' is installed in the base image.
echo "[1/4] Configuring passwordless sudo for user 'avd'..."
# Check using grep without % and ensure the line starts correctly
SUDOERS_LINE="avd ALL=(ALL) NOPASSWD: ALL"
SUDOERS_FILE="/etc/sudoers.d/avd-nopasswd"
if ! sudo grep -qxF "${SUDOERS_LINE}" "${SUDOERS_FILE}" > /dev/null 2>&1; then
    echo "${SUDOERS_LINE}" | sudo tee "${SUDOERS_FILE}" > /dev/null
    sudo chmod 0440 "${SUDOERS_FILE}"
    echo "Passwordless sudo configured."
else
    echo "Passwordless sudo already configured for user 'avd'."
fi

# [2/4] Add 'clab' alias to run containerlab with sudo automatically
echo "[2/4] Adding 'clab' alias to /home/avd/.zshrc ..."
ZSHRC_FILE="/home/avd/.zshrc"
ALIAS_LINE="alias clab='sudo clab'"
# Check if the alias line already exists
if ! grep -qxF "${ALIAS_LINE}" "${ZSHRC_FILE}" > /dev/null 2>&1; then
    # Ensure .zshrc exists and is owned by avd (might not exist in minimal base images)
    sudo touch "${ZSHRC_FILE}"
    sudo chown avd:$(id -gn avd) "${ZSHRC_FILE}"
    # Add the alias
    echo "" >> "${ZSHRC_FILE}" # Add newline for separation
    echo "# Alias to run containerlab with sudo automatically" >> "${ZSHRC_FILE}"
    echo "${ALIAS_LINE}" >> "${ZSHRC_FILE}"
    echo "'clab' alias added to ${ZSHRC_FILE}."
else
    echo "'clab' alias already exists in ${ZSHRC_FILE}."
fi

# [3/4] Create ansible.cfg if it doesn't exist in the workspace
echo "[3/4] Checking for ansible.cfg..."
if [ ! -f "/workspace/ansible.cfg" ]; then
  echo "ansible.cfg not found in /workspace. Creating recommended version..."
  # Create ansible.cfg with recommended AVD settings
  cat << EOF > /workspace/ansible.cfg
# Ansible Configuration File for AVD

[defaults]
# Enable Jinja2 extensions recommended by AVD documentation
jinja2_extensions = jinja2.ext.loopcontrols,jinja2.ext.do

# Error on duplicate dictionary keys in YAML (recommended by AVD docs)
duplicate_dict_key = error

# Optional: Specify inventory path if standard location is used
# inventory = ./inventory/inventory.yml

# Optional: Specify default forks, timeout, etc.
# forks = 10
# timeout = 60

[inventory]
# Enable inventory plugins if needed, e.g., arista.avd.inventory
# enable_plugins = arista.avd.inventory

[ssh_connection]
# Optional: Speed up SSH connections
# pipelining = True
# ssh_args = -o ControlMaster=auto -o ControlPersist=60s -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no
EOF
  # Set ownership to the container user 'avd' and its primary group
  # Using id -gn gets the primary group name for the user
  echo "Setting ownership of /workspace/ansible.cfg to avd user..."
  # Ensure the command runs even if sudo is needed for the chown itself initially
  sudo chown avd:$(id -gn avd) /workspace/ansible.cfg
  echo "Created /workspace/ansible.cfg with recommended settings."
else
  echo "Found existing ansible.cfg in /workspace. Skipping creation."
  echo "Please ensure it includes recommended AVD settings (jinja2_extensions, duplicate_dict_key)."
fi


# [4/4] Attempt to auto-import local cEOS image if present and remove original
echo "[4/4] Checking for local cEOS image file in /workspace..."
# Search for files like cEOS*.tar, cEOS*.tar.gz, cEOS*.tar.xz case-insensitively
IMAGE_FILE=$(find /workspace -maxdepth 1 -regextype posix-extended -iregex "/workspace/[cC]EOS.*\.tar(\.gz|\.xz)?" -print -quit)

if [ -n "${IMAGE_FILE}" ]; then
    echo "Found potential image file: ${IMAGE_FILE}"

    # ---> Wait for Docker Daemon to be ready <---
    # This step might still be needed depending on when the script runs vs DinD startup
    echo "Waiting for Docker daemon to be ready..."
    ATTEMPTS=0
    MAX_ATTEMPTS=30 # Wait up to 30 seconds (adjust as needed)
    # Loop until `docker info` succeeds or we timeout
    # Running as the 'avd' user now, ensure 'avd' is in the docker group in the base image
    until docker info > /dev/null 2>&1; do
        if [ ${ATTEMPTS} -eq ${MAX_ATTEMPTS} ]; then
            echo "Docker daemon did not become ready after ${MAX_ATTEMPTS} seconds. Skipping cEOS import."
            # Set IMAGE_FILE to empty so the rest of the import logic is skipped
            IMAGE_FILE=""
            break # Exit the until loop
        fi
        ATTEMPTS=$((ATTEMPTS + 1))
        sleep 1
    done
    if [ -n "${IMAGE_FILE}" ]; then # Check if we timed out waiting for Docker
      echo "Docker daemon is ready."
    fi
    # ---> End of Wait <---

    # Proceed only if Docker is ready and IMAGE_FILE is still set
    if [ -n "${IMAGE_FILE}" ]; then
        # Check if ceos:latest tag already exists in the container's Docker environment (DinD or host)
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
            # Optionally, still remove the source file if desired, even if skipping import
            # echo "Removing original file: ${IMAGE_FILE}"
            # rm -f "${IMAGE_FILE}"
            # echo "Original file removed."
        fi
    fi # End check if IMAGE_FILE is still set after wait loop
else
    # If no matching file found
    echo "No local cEOS image file found matching pattern '[cC]EOS*.tar*' in /workspace."
fi

echo "--- Simplified Post-Create Setup Finished ---"
