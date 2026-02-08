Got it 👍
Below is the **same guide rewritten in clean, professional English only** — no Hinglish, no slang.
This is **final, stable, and safe to share publicly**.

---

# 🚀 Republic AI Testnet Validator Setup Guide

### ✅ FINAL • STABLE • ROOT-ONLY • NO STATE-SYNC • NO CRASH

---

## ⚠️ IMPORTANT — READ FIRST

### 🔴 RULE #1: RUN EVERYTHING AS ROOT

This entire guide **must** be executed as the `root` user.

```bash
sudo -i
whoami
```

✔ Output must be:

```
root
```

If you do not run as root, you will face permission errors, systemd failures, or silent node exits.

---

### 🔴 RULE #2: FOLLOW STEPS IN ORDER

* Do **not** skip steps
* Do **not** run cleanup or systemctl commands unless instructed
* Configuration files are strict — mistakes will crash the node

---

## 📌 Network & System Information

| Item                    | Value                        |
| ----------------------- | ---------------------------- |
| Chain ID                | `raitestnet_77701-1`         |
| Base Denom              | `arai`                       |
| Display Denom           | `RAI`                        |
| Decimals                | 18                           |
| Minimum Gas Price       | `250000000arai`              |
| Minimum Self-Delegation | `1 RAI`                      |
| Top 100 Validators      | ~1000+ RAI                   |
| Operating System        | Ubuntu 22.04 LTS             |
| Recommended Hardware    | 8 CPU / 16GB RAM / 500GB SSD |

---

## 🔧 Why This Guide Is Stable (Read Once)

### ❌ Why State Sync Was Disabled

* RPC endpoints were overloaded
* Light client verification failed
* Snapshots were repeatedly rejected

### ✅ Final Decision

> **State Sync Disabled → Normal P2P Sync Enabled**

Normal P2P sync is slower, but **completely stable** and does not crash.

---

## Step 1: Install Dependencies

```bash
apt update && apt upgrade -y
apt install -y curl jq nano build-essential git make wget screen
```

---

## Step 2: Install `republicd` Binary

```bash
VERSION="v0.1.0"
curl -L "https://media.githubusercontent.com/media/RepublicAI/networks/main/testnet/releases/${VERSION}/republicd-linux-amd64" -o /tmp/republicd
chmod +x /tmp/republicd
mv /tmp/republicd /usr/local/bin/republicd
```

Verify installation:

```bash
republicd version
```

---

## Step 3: Initialize the Node

⚠️ This step **creates the `.republicd` directory**

```bash
republicd init <your-moniker> --chain-id raitestnet_77701-1
```

Replace `<your-moniker>` everywhere with your chosen validator name.

---

## Step 3.1: Create `priv_validator_state.json` (MANDATORY)

🚨 This is the **most common cause of silent node crashes**.

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

Without this file, the node may exit without any error message.

---

## Step 4: Download Genesis File

```bash
curl -s https://raw.githubusercontent.com/RepublicAI/networks/main/testnet/genesis.json > /root/.republicd/config/genesis.json
```

---

## Step 5: Disable State Sync (FINAL)

Edit the configuration:

```bash
nano /root/.republicd/config/config.toml
```

Set **exactly**:

```toml
[statesync]
enable = false
```

---

## Step 6: Add a Verified Persistent Peer

```bash
sed -i -E "s|persistent_peers *=.*|persistent_peers = \"6313f892ee50ca0b2d6cc6411ac5207dbf2d164b@95.216.102.220:13356\"|" \
/root/.republicd/config/config.toml
```

---

## Step 7: Fix Mempool Crash (CRITICAL)

Open the config file:

```bash
nano /root/.republicd/config/config.toml
```

Ensure these values are **set and not empty**:

```toml
experimental_max_gossip_connections_to_persistent_peers = 4
experimental_max_gossip_connections_to_non_persistent_peers = 4
```

Empty values will prevent the node from starting.

---

## Step 8: P2P Speed Configuration (NO DUPLICATES)

⚠️ `send_rate` and `recv_rate` must appear **only once**, inside `[p2p]`.

```toml
[p2p]
send_rate = 5120000
recv_rate = 5120000
```

If these keys appear anywhere else in the file, **delete the duplicates**.
Duplicate TOML keys will crash the node.

---

## Step 9: Create Systemd Service

```bash
nano /etc/systemd/system/republicd.service
```

Paste:

```ini
[Unit]
Description=Republic AI Testnet Node
After=network-online.target

[Service]
User=root
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

Enable and start:

```bash
systemctl daemon-reload
systemctl enable republicd
systemctl start republicd
```

View logs:

```bash
journalctl -u republicd -f
```

---

## Step 10: Optional Peer Reset (Recommended if Sync Slows)

```bash
systemctl stop republicd
rm -f /root/.republicd/config/addrbook.json
systemctl start republicd
```

This removes dead peers and forces fresh peer discovery.

---

## Step 11: Wait for Full Sync

```bash
republicd status | jq .sync_info
```

Wait until:

```json
"catching_up": false
```

Sync may be slow, but it will complete successfully.

---

## Step 12: Create or Recover Wallet

```bash
republicd keys add <your-moniker>
# OR
republicd keys add <your-moniker> --recover
```

---

## Step 13: Get Testnet Tokens

Faucet:
👉 [https://points.republicai.io/faucet](https://points.republicai.io/faucet)

Minimum required: **1.1+ RAI**

---

## Step 14: Create Validator

Get validator pubkey:

```bash
republicd comet show-validator
```

Create `validator.json` and submit the transaction as usual.

---


## Step 13: Verify Validator Status

Check your validator status:

```bash
republicd query staking validator $(republicd keys show xyzguide --bech val -a)
```

### Confirm the following fields:

* `status: BOND_STATUS_BONDED`
* `jailed: false`

You can also verify your validator on the explorer:
👉 [https://explorer.republicai.io](https://explorer.republicai.io)

---

## Step 14: Link Validator to Republic AI Dashboard

To link your validator with the Republic AI dashboard, send a **self-transfer transaction with a memo**.

### Send memo transaction:

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

🔹 Replace `YOUR_REFER_CODE` with your actual referral or dashboard code.

### Final Step

* Copy the **transaction hash**
* Submit it on:
  👉 [https://points.republicai.io](https://points.republicai.io)

---

## 🛠 Useful Commands

### Check Sync Status

```bash
republicd status | jq '.sync_info'
```

### Restart the Node

```bash
sudo systemctl restart republicd
```

### Unjail Validator (If Jailed)

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

### ✅ Final Notes

* Always ensure the node is fully synced before creating or managing a validator
* Do not unjail unless your node is **fully caught up**
* Keep sufficient balance for gas fees


