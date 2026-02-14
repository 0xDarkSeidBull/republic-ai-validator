# 🚀 Republic AI Testnet Validator Setup Guide 

---

## ⚠️ IMPORTANT — READ FIRST

### 🔴 RULE #1: RUN EVERYTHING AS ROOT

```bash
sudo -i
whoami
```

✔ Output must be:

```
root
```

---

### 🔴 RULE #2: FOLLOW STEPS IN ORDER

* Do NOT skip steps
* Do NOT manually create config files unless told
* Wrong config edits = instant node crash

---

## 🧠 CRITICAL PATH NOTE

This binary uses default home:

```
/root/.republic
```

❌ NOT `.republicd`

All paths below use `/root/.republic`.

---

## 📝 IMPORTANT NOTE ABOUT MONIKER

Replace `xyzguide` with your own moniker everywhere:

* Node init
* Wallet keys
* Validator creation
* Transactions

---

## 📌 Network & System Info

| Item                | Value                |
| ------------------- | -------------------- |
| Chain ID            | `raitestnet_77701-1` |
| Base Denom          | `arai`               |
| Min Gas Price       | `250000000arai`      |
| Min Self Delegation | `1 RAI`              |
| OS                  | Ubuntu 22.04         |
| Hardware            | 8 CPU / 16GB RAM     |

---

# 🔧 Stability Decision

State Sync disabled → unstable RPC
We use **normal P2P sync (stable)**

---

# Step 1: Install Dependencies

```bash
apt update && apt upgrade -y
apt install -y curl jq nano build-essential git make wget screen
```

---

# Step 2: Install republicd

```bash
VERSION="v0.1.0"
curl -L "https://media.githubusercontent.com/media/RepublicAI/networks/main/testnet/releases/${VERSION}/republicd-linux-amd64" -o /usr/local/bin/republicd
chmod +x /usr/local/bin/republicd
republicd version
```

---

# Step 3: Initialize Node

```bash
republicd init xyzguide --chain-id raitestnet_77701-1
```

Creates:

```
/root/.republic/config
/root/.republic/data
```

---

# Step 4: Download Genesis

```bash
curl -L https://raw.githubusercontent.com/RepublicAI/networks/main/testnet/genesis.json \
-o /root/.republic/config/genesis.json
```

---

# Step 5: Create Validator State (MANDATORY)

```bash
mkdir -p /root/.republic/data
cat <<EOF > /root/.republic/data/priv_validator_state.json
{
  "height": "0",
  "round": 0,
  "step": 0
}
EOF
```

---

# Step 6: Disable State Sync

```bash
nano /root/.republic/config/config.toml
```

Set:

```toml
[statesync]
enable = false
```

---

# Step 7: Add Persistent Peer

```bash
sed -i -E 's|persistent_peers *=.*|persistent_peers = "6313f892ee50ca0b2d6cc6411ac5207dbf2d164b@95.216.102.220:13356"|' /root/.republic/config/config.toml
```

---

# Step 8: Fix Mempool Crash (CRITICAL)

Inside `config.toml` ensure EXACT integers (no quotes):

```toml
experimental_max_gossip_connections_to_persistent_peers = 4
experimental_max_gossip_connections_to_non_persistent_peers = 4
```

---

# Step 9: P2P Speed Config

Ensure only ONE `[p2p]` section:

```toml
[p2p]
send_rate = 5120000
recv_rate = 5120000
```

---

# Step 10: Create Systemd Service

```bash
nano /etc/systemd/system/republicd.service
```

```ini
[Unit]
Description=Republic AI Testnet Node
After=network-online.target

[Service]
User=root
Environment=HOME=/root
WorkingDirectory=/root
ExecStart=/usr/local/bin/republicd start \
  --home /root/.republic \
  --chain-id raitestnet_77701-1
Restart=always
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
```

Start node:

```bash
systemctl daemon-reload
systemctl enable republicd
systemctl start republicd
```

---

# 🔴 NEW: Monitor Live Logs (IMPORTANT)

```bash
journalctl -u republicd -f
```

You should see:

```
Starting Peer service
Added peer
Executed block
```

---

# Step 11: Check Sync Status

```bash
republicd status | jq .sync_info
```

Wait until:

```json
"catching_up": false
```

---

# Step 12: Create / Recover Wallet

```bash
republicd keys add xyzguide
# OR
republicd keys add xyzguide --recover
```

---

# Step 13: Get Faucet Tokens

👉 [https://points.republicai.io/faucet](https://points.republicai.io/faucet)
Minimum: **1.1+ RAI**

---

# 🚀 Step 14: Create Validator

## Confirm Sync

```bash
republicd status | jq .sync_info.catching_up
```

Must be `false`

---

## Get Validator PubKey

```bash
republicd comet show-validator
```

---

## Create validator.json

```bash
nano validator.json
```

```json
{
  "pubkey": {
    "@type": "/cosmos.crypto.ed25519.PubKey",
    "key": "PASTE_YOUR_PUBKEY_HERE"
  },
  "amount": "1000000000000000000arai",
  "moniker": "xyzguide",
  "identity": "",
  "website": "",
  "security_contact": "",
  "details": "Republic AI Testnet Validator",
  "commission-rate": "0.10",
  "commission-max-rate": "0.20",
  "commission-max-change-rate": "0.01",
  "min-self-delegation": "1"
}
```

---

## Create Validator TX

```bash
republicd tx staking create-validator validator.json \
  --from xyzguide \
  --chain-id raitestnet_77701-1 \
  --gas auto \
  --gas-adjustment 1.5 \
  --gas-prices 250000000arai \
  --yes
```

---

# Step 15: Verify Validator

```bash
republicd query staking validator \
$(republicd keys show xyzguide --bech val -a)
```

Expected:

```
BOND_STATUS_BONDED
jailed: false
```

Explorer: [https://explorer.republicai.io](https://explorer.republicai.io)

---

# Step 16: Link Validator to Dashboard

```bash
republicd tx bank send \
  xyzguide \
  $(republicd keys show xyzguide -a) \
  1000000000000000arai \
  --chain-id raitestnet_77701-1 \
  --from xyzguide \
  --note "YOUR_REF_CODE" \
  --gas auto \
  --gas-adjustment 1.5 \
  --gas-prices 250000000arai \
  --yes
```

Submit TX hash:
👉 [https://points.republicai.io](https://points.republicai.io)

---

---
## 🔑 OPTIONAL: Rotate Node Key (Generate New Peer ID)

If running a fresh validator identity on the same synced node, rotate node key to generate a new peer ID.
Chain data & sync will remain intact.

> VPS IP cannot be changed. This only regenerates P2P identity.

### 🔴 1. Show & Save Current Peer ID (copy to notepad)

```bash
echo "Current Peer ID:"
republicd comet show-node-id --home /root/.republic
```

### 🔴 2. Stop Node

```bash
systemctl stop republicd
```

### 🔴 3. Backup Node Key

```bash
cp /root/.republic/config/node_key.json /root/node_key.backup.json
```

### 🔴 4. Remove Old Node Key

```bash
rm /root/.republic/config/node_key.json
```

### 🔴 5. Regenerate New Peer ID

```bash
systemctl start republicd
sleep 5
systemctl stop republicd
systemctl start republicd
```

### 🔴 6. Verify New Peer ID (save again)

```bash
echo "New Peer ID:"
republicd comet show-node-id --home /root/.republic
```

✔ Node remains synced
✔ Chain data untouched
✔ New peer identity generated

---

# 📋 ONE COMMAND: Dump Important IDs (Save to Notepad)

This command prints wallet address, validator address, peer ID, and keeps private keys **local only** (not uploading anywhere).
User can copy & save manually.

```bash
echo "===== NODE & WALLET INFO =====" && \
echo "Wallet Address:" && republicd keys show xyzguide -a && \
echo "Validator Address:" && republicd keys show xyzguide --bech val -a && \
echo "Peer ID:" && republicd comet show-node-id --home /root/.republic && \
echo "Node Moniker:" && grep -i moniker /root/.republic/config/config.toml
```

> ⚠️ Never share private keys publicly. Save them securely offline.

## ♻️ OPTIONAL: Run Another Validator (Keep Node Synced)

If you want to run a new validator on the same synced node, follow these safe steps.
This will change only the validator identity — chain data & sync will remain intact.

### 🔴 1. Stop Node

```bash
systemctl stop republicd
```

### 🔴 2. Backup Old Validator Key (IMPORTANT)

```bash
cp /root/.republic/config/priv_validator_key.json /root/old_priv_validator_key.json.bak
```

### 🔴 3. Remove Old Validator Key

```bash
rm /root/.republic/config/priv_validator_key.json
```

### 🔴 4. Generate New Validator Key (without deleting data)

```bash
republicd comet show-validator --home /root/.republic 2>/dev/null || true
```

Then start node once to auto-create new key:

```bash
systemctl start republicd
sleep 5
systemctl stop republicd
```

(New `priv_validator_key.json` will be created automatically)

### 🔴 5. Start Node Again

```bash
systemctl start republicd
journalctl -u republicd -f
```

### 🔴 6. Confirm Sync Still OK

```bash
republicd status | jq .sync_info.catching_up
```

✔ Must be `false`

### 🔴 7. Get New PubKey

```bash
republicd comet show-validator
```

### 🔴 8. Create New Validator TX

Use the new pubkey inside `validator.json` and run the create-validator transaction again.

✔ Node will remain fully synced
✔ Only validator identity will change



## 👤 Author

Handle: **0xDarkSeidBull**

Role: Republic Validator

GitHub: [https://github.com/0xDarkSeidBull](https://github.com/0xDarkSeidBull)

Wallet: `0x3bc6348e1e569e97bd8247b093475a4ac22b9fd4`

---


## If this guide helped you:

⭐ [![Stars](https://img.shields.io/github/stars/0xDarkSeidBull/republic-ai-validator)](https://github.com/0xDarkSeidBull/republic-ai-validator/stargazers)

🧾 [![License](https://img.shields.io/github/license/0xDarkSeidBull/republic-ai-validator)](LICENSE)

🔁 Share with new builders


---



