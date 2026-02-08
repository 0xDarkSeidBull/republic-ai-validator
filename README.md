

---

# 🚀 Republic AI Testnet Validator Setup Guide (FINAL + STABLE)

---

## 📌 Important Notes (Read First)

* **Moniker**: Lowercase letters, numbers, and `-` only (no spaces)
* **Chain ID**: `raitestnet_77701-1`
* **Denom**: `arai` (base unit), `RAI` (display unit)
* **Decimals**: 18
* **Minimum Gas Price**: `250000000arai`
* **Minimum Self-Delegation**: `1 RAI`
* **Top 100 Validators**: Approximately **1000+ RAI** required
* **Operating System**: Ubuntu 22.04 LTS
* **Recommended System Requirements**:

  * CPU: 8 cores
  * RAM: 16GB or more
  * SSD: 500GB or more

---

## 🔧 What We Fixed & Why (IMPORTANT – READ ONCE)

### ❌ Why State Sync Failed

* Testnet RPC endpoints were overloaded
* Light client header verification failed
* Snapshots were repeatedly rejected

### ✅ Final Decision

> **State Sync DISABLED → Normal P2P Sync ENABLED (Slower but 100% Stable)**

This guide uses **normal P2P synchronization**, not fast state sync.

---

## Step 1: Install Dependencies

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl jq nano build-essential git make wget screen
```

---

## Step 2: Install `republicd` Binary

```bash
VERSION="v0.1.0"
curl -L "https://media.githubusercontent.com/media/RepublicAI/networks/main/testnet/releases/${VERSION}/republicd-linux-amd64" -o /tmp/republicd
chmod +x /tmp/republicd
sudo mv /tmp/republicd /usr/local/bin/republicd
```

Verify installation:

```bash
republicd version
```

---

## Step 3: Initialize the Node

```bash
REPUBLIC_HOME="$HOME/.republicd"
republicd init xyzguide --chain-id raitestnet_77701-1 --home "$REPUBLIC_HOME"
```

🔁 Replace `xyzguide` with your own moniker everywhere.

---

## Step 3.1: Create Missing Validator State File (MANDATORY)

### ❗ Critical Fix — Main Reason for Node Crashes

```bash
mkdir -p /root/.republicd/data

cat <<EOF > /root/.republicd/data/priv_validator_state.json
{
  "height": "0",
  "round": 0,
  "step": 0
}
EOF

chown -R root:root /root/.republicd
```

👉 Without this file, the node will **exit silently on startup**.

---

## Step 4: Download Genesis File

```bash
curl -s https://raw.githubusercontent.com/RepublicAI/networks/main/testnet/genesis.json > "$REPUBLIC_HOME/config/genesis.json"
```

---



## Step 4A: 🔑 Trust Height & Trust Hash — FULL WORKED EXAMPLE (195432)

This section explains **exactly how to calculate the trust height and trust hash**, using a real example.

---
Find BLOCK

```
SNAP_RPC="https://rpc.republicai.io"
```

### Example Context

Assume the latest block height on the network is:

```text
195432
```

---

## Step 1️⃣: Confirm the Latest Block Height

Fetch the latest block height from a working RPC endpoint.

```bash
LATEST_HEIGHT=195432
```

This means:

> The current latest block on the chain is **195432**.

---

## Step 2️⃣: Choose the Trust Height (MOST IMPORTANT)

**Rule of thumb:**

> Always choose a trust height **500–2000 blocks behind** the latest height.

We choose:

```text
Trust Height = 195432 − 1000
```

### Calculation

```text
195432 - 1000 = 194432
```

✅ **Final trust height:**

```text
194432
```

This height is recent enough to be valid, but old enough to be stable.

---

## Step 3️⃣: Fetch the Trust Hash for That Height

Now fetch the **block hash at the trust height** using the RPC.

```bash
curl -s "https://rpc.republicai.io/block?height=194432" | jq -r .result.block_id.hash
```

### Example output:

```text
26CBC5D61EABE30E19FFB0673079EE241681339A7FE880B4DFFF577150726A2E
```

👉 This value is your **trust hash**.

---

## Step 4️⃣: Final Values (Used in `config.toml`)

You now have the two required values:

```text
trust_height = 194432
trust_hash   = 26CBC5D61EABE30E19FFB0673079EE241681339A7FE880B4DFFF577150726A2E
```

These values are normally used for state sync verification.

---

## Step 5: Disable State Sync (FINAL FIX)

Due to testnet instability, **state sync is intentionally disabled** in the final configuration.
The trust height and hash are kept **only for transparency and reference**.

Open the configuration file:

```bash
nano $HOME/.republicd/config/config.toml
```

### 🔽 Locate the `[statesync]` section and set **exactly**:

```toml
[statesync]
enable = false
rpc_servers = "https://rpc.republicai.io,https://rest.republicai.io"
trust_height = 194432
trust_hash = "26CBC5D61EABE30E19FFB0673079EE241681339A7FE880B4DFFF577150726A2E"
trust_period = "168h0m0s"
```






## Step 6: Add a Working Persistent Peer (TESTED)

```bash
sed -i -E "s|persistent_peers *=.*|persistent_peers = \"6313f892ee50ca0b2d6cc6411ac5207dbf2d164b@95.216.102.220:13356\"|" \
$HOME/.republicd/config/config.toml
```

👉 This peer has been **live-tested and confirmed stable**.

---

## Step 7: Fix Mempool Crash (MOST IMPORTANT)

```bash
nano $HOME/.republicd/config/config.toml
```

### 🔍 Search (Ctrl + W) and fix the following:

❌ Before:

```toml
experimental_max_gossip_connections_to_persistent_peers =
experimental_max_gossip_connections_to_non_persistent_peers =
```

✅ Replace with:

```toml
experimental_max_gossip_connections_to_persistent_peers = 4
experimental_max_gossip_connections_to_non_persistent_peers = 4
```

⚠️ If skipped, the node **will not start**.

---

## Step 8: Create Systemd Service

```bash
sudo nano /etc/systemd/system/republicd.service
```

Paste the following:

```ini
[Unit]
Description=Republic AI Testnet Node
After=network-online.target

[Service]
Environment=HOME=/root
WorkingDirectory=/root
ExecStart=/usr/local/bin/republicd start \
  --home /root/.republicd \
  --chain-id raitestnet_77701-1
Restart=always
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
```

Enable and start the service:

```bash
sudo systemctl daemon-reload
sudo systemctl enable republicd
sudo systemctl start republicd
```

View logs:

```bash
journalctl -u republicd -f
```

---

## Step 9: Wait for Full Sync

```bash
republicd status | jq '.sync_info'
```

Wait until:

```json
"catching_up": false
```

⏳ This may take time, but **it will complete successfully**.

---

## Step 10: Create or Import Wallet

```bash
republicd keys add xyzguide
# OR
republicd keys add xyzguide --recover
```

Check wallet address:

```bash
republicd keys show xyzguide -a
```

---

## Step 11: Get Testnet Tokens

* Faucet: [https://points.republicai.io/faucet](https://points.republicai.io/faucet)
* Minimum required: **1.1+ RAI**

Check balance:

```bash
republicd query bank balances $(republicd keys show xyzguide -a)
```

---

## Step 12: Create Validator

Get validator public key:

```bash
republicd comet show-validator
```

Create validator file:

```bash
nano validator.json
```

```json
{
  "pubkey": {"@type":"/cosmos.crypto.ed25519.PubKey","key":"PUT_YOUR_KEY"},
  "amount": "1000000000000000000arai",
  "moniker": "xyzguide",
  "identity": "",
  "website": "",
  "security_contact": "",
  "details": "Republic AI testnet validator",
  "commission-rate": "0.10",
  "commission-max-rate": "0.20",
  "commission-max-change-rate": "0.01",
  "min-self-delegation": "1"
}
```

Submit transaction:

```bash
republicd tx staking create-validator validator.json \
  --from xyzguide \
  --chain-id raitestnet_77701-1 \
  --gas auto \
  --gas-adjustment 1.5 \
  --gas-prices 1000000000arai \
  --yes
```

---

## Step 13: Verify Validator

```bash
republicd query staking validator $(republicd keys show xyzguide --bech val -a)
```

Confirm:

* `BOND_STATUS_BONDED`
* `jailed: false`

Explorer: [https://explorer.republicai.io](https://explorer.republicai.io)

---

## Step 14: Link Validator on Dashboard

Send a memo transaction:

```bash
republicd tx bank send \
  xyzguide \
  $(republicd keys show xyzguide -a) \
  1000000000000000arai \
  --chain-id raitestnet_77701-1 \
  --from xyzguide \
  --note "YOUR_REFER_CODE" \
  --gas auto \
  --gas-adjustment 1.5 \
  --gas-prices 1000000000arai \
  --yes
```

Submit the transaction hash on:
👉 [https://points.republicai.io](https://points.republicai.io)

---

## 🛠 Useful Commands

* Sync status:

```bash
republicd status | jq '.sync_info'
```

* Restart node:

```bash
sudo systemctl restart republicd
```

* Unjail validator:

```bash
republicd tx slashing unjail \
--from xyzguide \
--chain-id raitestnet_77701-1 \
--gas auto \
--gas-adjustment 1.5 \
--gas-prices 1000000000arai \
--yes
```

---


