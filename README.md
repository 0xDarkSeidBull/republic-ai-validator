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
sudo apt update && sudo apt upgrade -y
sudo apt install curl tar wget clang pkg-config libssl-dev jq build-essential bsdmainutils git make ncdu gcc chrony liblz4-tool -y
```

---

# Step 2: Install republicd

```bash
wget https://github.com/RepublicAI/networks/releases/download/v0.3.0/republicd-linux-amd64 -O republicd
chmod +x republicd
sudo mv republicd /usr/local/bin/
republicd version
```

Expected::

```bash
v0.3.0
```

---

# Step 3: Initialize Node

```bash
republicd init xyzguide --chain-id raitestnet_77701-1
```



# Step 4: Download Genesis

```bash
curl -L https://raw.githubusercontent.com/RepublicAI/networks/main/testnet/genesis.json -o $HOME/.republic/config/genesis.json
```


```bash
jq . $HOME/.republic/config/genesis.json | head
```
---

# Step  5. Set Working Dynamic Peers (Most Important Fix)

```bash
peers=$(curl -sS https://rpc-t.republic.vinjan-inc.com/net_info | jq -r '.result.peers[] | "\(.node_info.id)@\(.remote_ip):\(.node_info.listen_addr)"' | awk -F ':' '{print $1":"$(NF)}' | paste -sd "," -)

sed -i "s/^persistent_peers *=.*/persistent_peers = \"$peers\"/" $HOME/.republic/config/config.toml
```

Check

```bash
grep persistent_peers $HOME/.republic/config/config.toml
```

---

# Step 6. Disable State Sync (normal sync mode)


```bash
sed -i 's/^enable *=.*/enable = false/' $HOME/.republic/config/config.toml
sed -i 's/^seeds *=.*/seeds = ""/' $HOME/.republic/config/config.toml
```



---

# Step 7. Start Node (Foreground Test)

```bash
republicd start --chain-id raitestnet_77701-1
```

You should see:

```bash
Ensure peers...
Reconnecting to peer...
```



---

# Step 9 Stop Node (After Confirming Sync Works)

(This stops foreground process only)

---

# Step 10Run Node as Background Service (Permanent)


Create systemd service
```bash
sudo tee /etc/systemd/system/republicd.service > /dev/null <<EOF
[Unit]
Description=Republic Protocol Node
After=network-online.target

[Service]
User=root
WorkingDirectory=/root
ExecStart=/usr/local/bin/republicd start --chain-id raitestnet_77701-1
Restart=always
RestartSec=5
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF
```

Enable + Start Service

```bash
sudo systemctl daemon-reload
sudo systemctl enable republicd
sudo systemctl start republicd
```

---

# 🔴 View Live Logs (Safe CTRL+C)

```bash
journalctl -u republicd -f -o cat
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
republicd status | jq '.sync_info'
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
  --gas-prices 1000000000arai \
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
  --gas-prices 1000000000arai \
  --yes
```

Submit TX hash:
👉 [https://points.republicai.io](https://points.republicai.io)

---


## v0.3.0 upgrade command


**Step 1: Stop the node**

If using systemd:

```bash
sudo systemctl stop republicd
```

If running manually:

```bash
pkill republicd
```

Confirm stopped:

```bash
ps aux | grep republicd
```

**Step 2: Download Latest Version**

To auto-get latest release:

```bash
VERSION=$(curl -s https://api.github.com/repos/RepublicAI/networks/releases/latest | jq -r .tag_name)
ARCH=$(uname -m | sed 's/x86_64/amd64/' | sed 's/aarch64/arm64/')

curl -L "https://github.com/RepublicAI/networks/releases/download/${VERSION}/republicd-linux-${ARCH}" -o republicd
chmod +x republicd
```

OR if you specifically want v0.3.0:
```bash
curl -L https://github.com/RepublicAI/networks/releases/download/v0.3.0/republicd-linux-amd64 -o republicd
chmod +x republicd
```

**Step3: Replace Old Binary**

Backup old binary first (important):

```bash
sudo mv /usr/local/bin/republicd /usr/local/bin/republicd_backup
```

Move new one:

```bash
sudo mv republicd /usr/local/bin/republicd
```

Confirm version:

```bash
republicd version
```

**Step4: Start Node Again**

If using systemd:

```bash
sudo systemctl start republicd
```

If manual:

```bash
republicd start --home $HOME/.republic --chain-id raitestnet_77701-1
```

**Step5: Check Status**

```bash
republicd status | jq .sync_info
```

OR

```journalctl -u republicd -f
```


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

```bash
cat /root/.republic/config/priv_validator_key.json
```

### 🔴 3. Remove Old Validator Key

```bash
rm /root/.republic/config/priv_validator_key.json
```

### 🔴 4. Generate New Validator Key (without deleting data)



Then start node once to auto-create new key:

```bash
systemctl start republicd
```

```bash
republicd comet show-validator --home /root/.republic 2>/dev/null || true
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



