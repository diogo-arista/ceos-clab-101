# Containerlab Dev Container Environment

This repository provides a ready-to-use development environment for working with Arista Validated Designs (AVD) and Containerlab, leveraging VS Code Dev Containers. It includes Ansible, PyAVD, Containerlab, Docker-in-Docker, and necessary dependencies, all configured within a container.

## Features

* **Reproducible Environment:** Ensures all developers use the same set of tools and dependency versions.
* **Containerlab Ready:** Includes Containerlab and Docker-in-Docker for deploying virtual network labs.
* **AVD Pre-configured:** Installs `ansible-core`, `pyavd`, `arista.avd`, `arista.eos`, and required Python libraries with compatible versions pinned.
* **Python Virtual Environment:** Uses a dedicated Python venv (`ansible-venv`) which is automatically activated in the terminal.
* **VS Code Integration:** Configured settings for Python and the Containerlab extension. Includes commented-out settings for the optional Ansible extension.
* **Automatic cEOS Import:** Includes a script to automatically import a local Arista cEOS image (`.tar`, `.tar.gz`, `.tar.xz`) into the container's Docker environment on the first build.

## Prerequisites

1.  **VS Code:** Install the latest version of Visual Studio Code.
2.  **VS Code Remote - Containers Extension:** Install the `ms-vscode-remote.remote-containers` extension from the VS Code Marketplace.
3.  **Podman:** Install Podman and Podman Desktop (optional but helpful). Ensure the Podman machine is running (`podman machine start`). *Note: While the Dev Container aims for compatibility, running privileged Docker-in-Docker containers might require specific Podman configurations or encounter nuances.*
4.  **Arista cEOS Image:** You need a cEOS lab image file (e.g., `cEOS-lab-4.xx.x.tar.xz`). Download this from your Arista account.
    * **Architecture Note:** It is crucial to download the correct image for your host system's architecture:
        * **macOS (Apple Silicon M1/M2/M3/M4):** You **must** download the **ARM64 (aarch64)** version of the cEOS-lab image. 
        * **x86 Windows / GitHub Codespaces:** Use the standard **x86_64** version of the cEOS-lab image, as these environments typically run on or emulate x86_64 architecture.
    * **Placement:** This file must be placed in the root directory of this repository *before* building the Dev Container for the first time so the automatic import script can find it.

## Setup Instructions

Follow the instructions for your preferred environment (Podman Desktop or GitHub Codespaces):

### Option 1: Local Development (Podman Desktop)

*Ensure Podman is installed and the Podman machine is running (`podman machine start`).*

1.  **Clone Repository:** Clone this repository to your local machine.
    ```bash
    git clone <your-repository-url>
    cd <repository-directory>
    ```
2.  **Place cEOS Image:** Copy your downloaded cEOS image file (making sure it's the correct architecture - see Prerequisites #4) into the root directory of the cloned repository.
3.  **Configure VS Code (If Needed):** The Remote - Containers extension usually detects Podman automatically. If you encounter issues, you might need to tell VS Code to use Podman:
    * Open VS Code Settings (`Cmd+,` or `Ctrl+,`).
    * Search for `docker path`.
    * Under "Remote > Containers > Docker Path", set it to `podman` (or the full path to your Podman executable if it's not in the system PATH).
4.  **Open in VS Code:** Open the repository folder (`<repository-directory>`) in VS Code.
5.  **Reopen in Container:** VS Code should prompt you to reopen in a container: "Folder contains a Dev Container configuration file. Reopen folder to develop in a container." Click **"Reopen in Container"**.
    * Alternatively, use the Command Palette (`Cmd+Shift+P` or `Ctrl+Shift+P`) and run **"Remote-Containers: Reopen in Container"**.
6.  **Build Process:** VS Code (using Podman) will build the image and start the container. Monitor the logs for progress. This might take several minutes on the first run. *Note: If you encounter issues related to privileged operations or Docker-in-Docker, consult Podman documentation regarding running privileged containers within its virtual machine.*

### Option 2: GitHub Codespaces

1.  **Place cEOS Image:**
    * Commit the **x86_64** version of your downloaded cEOS image file (e.g., `cEOS-lab-4.xx.x.tar.xz`) to the root directory of the repository *before* creating the Codespace. This ensures it's available when the Codespace builds.
    * *Alternatively*, you can upload the image to the Codespace *after* it starts, but you will need to manually run the import command inside the Codespace terminal: `docker import /workspace/<your-ceos-image-file.tar.xz> ceos:latest && rm /workspace/<your-ceos-image-file.tar.xz>`
2.  **Create Codespace:** Navigate to the repository on GitHub. Click the **"< > Code"** button, go to the **"Codespaces"** tab, and click **"Create codespace on main"** (or your desired branch).
3.  **Build Process:** GitHub will create and configure the Codespace based on the `devcontainer.json` file. This includes building the container, running the `post-create.sh` script, and importing the cEOS image (if present).
4.  **Connect:** Once ready, the Codespace will open directly in your browser or you can connect using VS Code Desktop.

## Using the Environment

* **Terminal:** Open a new terminal in VS Code (`Terminal > New Terminal`). The Python virtual environment (`ansible-venv`) should be automatically activated, indicated by `(ansible-venv)` in the prompt.
* **Tools:** `ansible`, `ansible-galaxy`, `ansible-lint`, `yamllint`, `containerlab`, and `docker` commands are available directly in the terminal.
* **cEOS Image:** If the import script ran successfully during the build, you can verify the image exists within the container's Docker environment:
    ```bash
    docker images ceos:latest
    ```
* **Containerlab:** You can now use Containerlab to deploy topologies defined in `.clab.yml` files:
    ```bash
    # Example: Deploy a topology defined in topology.clab.yml
    containerlab deploy -t topology.clab.yml

    # List running lab containers
    containerlab inspect

    # Destroy the lab
    containerlab destroy -t topology.clab.yml --cleanup
    ```
* **Ansible/AVD:** Run your Ansible playbooks as usual. The environment is configured to use the correct Python interpreter and collections.

## Troubleshooting

* **Slow Build:** The initial build can be slow due to downloads and installations. Subsequent starts should be faster.
* **cEOS Import Failed:** Ensure the cEOS image file (with the correct architecture) was placed in the repository root *before* the first build. Check the build logs (`Dev Containers: Show Container Log`) for errors during the import step in `post-create.sh`. You can manually import it later if needed (see Codespaces alternative step).
* **Podman Issues:** Privileged operations needed by Docker-in-Docker can sometimes be tricky with Podman setups. Consult Podman documentation or community forums if you face permission errors. Ensure your Podman machine is configured appropriately.
* **Resource Limits:** Running multiple cEOS nodes is resource-intensive (CPU/RAM). Ensure your local machine or Codespace instance has sufficient resources (16GB+ RAM recommended). Check the `hostRequirements` in `devcontainer.json`.
* **Architecture Mismatch:** If you accidentally use the x86_64 cEOS image on an Apple Silicon Mac with Podman, the container may fail to start or run extremely slowly due to QEMU emulation. Ensure you are using the ARM64 image on Apple Silicon.
