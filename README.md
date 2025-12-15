# Ethereum Ephemery Node & Validator Setup

This project runs an Ethereum Full Node (Geth + Prysm) and a Validator on the **Ephemery Testnet**.
It is designed to be cross-platform (macOS/Linux/Windows) using Docker.

## Prerequisites

1.  **Docker Desktop**: Install and ensure it is running.
2.  **Git**: For cloning the repository.
3.  **Terminal**:
    *   **Windows**: Use **Git Bash** (recommended) or WSL2. PowerShell may work but script syntax (`.sh`) is designed for Bash.
    *   **Mac/Linux**: Standard Terminal.

## Quick Start (How to Run)

### 1. Setup & Start Node
This script will download the latest Ephemery network config, generate a JWT secret, and start the node.

```bash
bash setup_ephemery.sh
```

*   Wait for the node to sync. Check logs with: `docker-compose logs -f`

### 2. Generate Validator Keys
Run this script to interactively create your validator keys (mnemonic & keystore).
**Note:** You will need to manually back up the Mnemonic phrase shown.

```bash
bash generate_validator_keys.sh
```

*   Files will be generated in `validator_keys/`.

### 3. Deposit (Launchpad)
1.  Go to [https://launchpad.ephemery.dev/](https://launchpad.ephemery.dev/)
2.  Upload the `deposit_data-*.json` file found in `validator_keys/`.
3.  Perform the deposit transaction using MetaMask (requires 32 testnet ETH).

### 4. Import Keys
After depositing, import the keys into your running Validator client.

```bash
bash import_keys.sh
```

*   You will be prompted for:
    1.  A new wallet password (for Prysm).
    2.  The keystore password you set in Step 2.

## Folder Structure
*   `ethereum_data_ephemery/`: Stores the blockchain data (Ignored by git).
*   `ephemery_config/`: Stores genesis files (Downloaded automatically).
*   `validator_keys/`: Stores your generated keys (Ignored by git).

## Troubleshooting
*   **Ports**: Setup uses ports 8545/30303 etc. Ensure they are free.
*   **Reset**: Ephemery resets every few weeks. If the network stops working, run `docker-compose down`, delete `ethereum_data_ephemery`, and run `setup_ephemery.sh` again to get the new genesis.
