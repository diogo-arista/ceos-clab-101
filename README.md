## Generating and Using an Arista API Token for Downloads

This guide explains how to generate an API access token from the Arista customer portal. This token allows tools (like `ardl`) to programmatically access Arista resources, such as downloading software images (like cEOS), without requiring manual login via a browser. This is particularly useful for automated setups like Dev Containers or CI/CD pipelines.

**Prerequisites:**

* An active user account on the Arista customer portal (`https://www.arista.com/`).

**Steps:**

1.  **Log In to Arista Portal:**
    * Open your web browser and navigate to `https://www.arista.com/`.
    * Log in using your registered customer account credentials.

2.  **Navigate to Token Generation:**
    * Once logged in, locate your user profile area. This is typically accessed by clicking your username or profile icon, usually found in the top-right corner of the page.
    * Look for a menu item related to your profile, account settings, or specifically **"Access Tokens"** or **"API Access"**. Click on it.
    * *(Note: Website layouts can change, so you may need to explore the profile/account sections slightly if the exact naming differs.)*

3.  **Generate a New Token:**
    * Within the Access Tokens section, look for an option like **"Generate Token"**, **"Create New Token"**, or similar. Click it.
    * You will likely be prompted to give the token a descriptive **name** (e.g., `Codespaces-Download-Token`, `DevContainer-Token`). Choose a name that helps you remember its purpose.
    * You might be asked to set **permissions** or **scopes**. For downloading software, ensure the token has the necessary read/download permissions related to software entitlements or downloads.
    * You may also be able to set an **expiration date**. It's good security practice to set an expiration date appropriate for your needs.

4.  **Copy the Token Immediately:**
    * After confirming the details, the portal will generate the token.
    * **IMPORTANT:** The token secret (the actual long string of characters) is typically shown **only once** immediately after generation for security reasons.
    * **Copy the entire token value** carefully and immediately store it in a secure location (like a password manager). Do not close the window or navigate away until you have copied it. If you lose it, you will need to generate a new one.

5.  **Configure Token as a GitHub Codespaces Secret:**
    * Navigate to the GitHub repository where you are using Codespaces.
    * Click on the repository's **"Settings"** tab.
    * In the left sidebar, under "Security", click **"Secrets and variables"** > **"Codespaces"**.
    * Click the **"New repository secret"** button.
    * In the **"Name"** field, enter `ARISTA_TOKEN`. It's important to use this exact name if you intend to use it with the `devcontainer.json` configurations we discussed previously (which referenced `${localEnv:ARISTA_TOKEN}` or a secret named `ARISTA_TOKEN`).
    * In the **"Value"** field, paste the Arista API token you copied in Step 4.
    * Click **"Add secret"**.

**Security Considerations:**

* **Treat your API token like a password.** Keep it confidential.
* **Do not** commit the token directly into your source code, `devcontainer.json`, or any other file in your Git repository. Use the Codespaces secrets mechanism as described above.
* Use tokens with appropriate permissions and expiration dates.
* Revoke tokens if they are compromised or no longer needed.

---

Once you have generated the token and added it as a Codespaces secret named `ARISTA_TOKEN`, a Dev Container environment launched in that repository could potentially access it as an environment variable, allowing tools like `ardl` to authenticate and download images automatically during the build process (if the `devcontainer.json` and setup scripts were configured to do so).
