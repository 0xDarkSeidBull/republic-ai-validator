# 🚀 Republic AI Testnet Validator Setup (Stable Method)

⚠️ This guide fixes:

* peer reconnecting issue
* RPC timeouts
* fresh v0.3.0 sync failure

✔ Proven working flow:
**Install v0.1.0 → Sync → Upgrade to v0.2.1 → Upgrade to v0.3.0**

---

# 🔴 STEP 0 — Run as root

```bash
sudo -i
whoami
```

Output must be:

```
root
```

---

# 🧹 STEP 1 — Clean Previous Installation (Fresh Start)

```bash
sudo systemctl stop republicd 2>/dev/null || true
pkill republicd 2>/dev/null || true
rm -rf $HOME/.republic
sudo rm -f /usr/local/bin/republicd
```

---

# 📦 STEP 2 — Install Dependencies

```bash
apt update && apt upgrade -y
apt install curl tar wget clang pkg-config libssl-dev jq build-essential bsdmainutils git make ncdu gcc chrony liblz4-tool -y
```

---

# 🔽 STEP 3 — Install republicd v0.1.0 (IMPORTANT)

```bash
cd $HOME
wget https://github.com/RepublicAI/networks/releases/download/v0.1.0/republicd-linux-amd64 -O republicd
chmod +x republicd
mv republicd /usr/local/bin/republicd
```

Check version:

```bash
republicd version
```

Expected:

```
v0.1.0
```

---

# 🏁 STEP 4 — Initialize Node

```bash
republicd init my-node --chain-id raitestnet_77701-1
```

---

# 🌐 STEP 5 — Download Genesis

```bash
curl -L https://raw.githubusercontent.com/RepublicAI/networks/main/testnet/genesis.json -o $HOME/.republic/config/genesis.json
```

Verify:

```bash
jq . $HOME/.republic/config/genesis.json | head
```

---

# 🔗 STEP 6 — Add Dynamic Working Peers (CRITICAL FIX)

```bash
peers=$(curl -sS https://rpc-t.republic.vinjan-inc.com/net_info | jq -r '.result.peers[] | "\(.node_info.id)@\(.remote_ip):\(.node_info.listen_addr)"' | awk -F ':' '{print $1":"$(NF)}' | paste -sd "," -)

sed -i "s/^persistent_peers *=.*/persistent_peers = \"$peers\"/" $HOME/.republic/config/config.toml
```

Check:

```bash
grep persistent_peers $HOME/.republic/config/config.toml
```

---

# ❌ STEP 7 — Disable State Sync (Use Stable P2P Sync)

```bash
sed -i 's/^enable *=.*/enable = false/' $HOME/.republic/config/config.toml
sed -i 's/^seeds *=.*/seeds = ""/' $HOME/.republic/config/config.toml
```

---

# ▶️ STEP 8 — Start Node (Foreground Test)

```bash
republicd start --chain-id raitestnet_77701-1
```

You should see:

```
Ensure peers...
Added peer...
```

Stop after confirming:

```
CTRL + C
```

---

# ⚙️ STEP 9 — Create Systemd Service

```bash
tee /etc/systemd/system/republicd.service > /dev/null <<EOF
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

---

# 🚀 STEP 10 — Start Service

```bash
systemctl daemon-reload
systemctl enable republicd
systemctl start republicd
```

Logs:

```bash
journalctl -u republicd -f -o cat
```

---

# 📊 STEP 11 — Check Sync Progress

```bash
republicd status | jq '.sync_info'
```

Wait until:

Must be `150k-200k height` then upgrade to v0.2.1

---

# 🔄 STEP 12 — Upgrade to v0.2.1 (After Sync Starts)

```bash
sudo systemctl stop republicd

wget https://github.com/RepublicAI/networks/releases/download/v0.2.1/republicd-linux-amd64 -O republicd
chmod +x republicd
sudo mv republicd /usr/local/bin/republicd
```

Check logs:

```bash
journalctl -u republicd -f -o cat
```

Wait until:

Must be `326250 height` then upgrade to v0.3.0



---

# 🔼 STEP 13 — Upgrade to v0.3.0 (Final Version)

```bash
sudo systemctl stop republicd

wget https://github.com/RepublicAI/networks/releases/download/v0.3.0/republicd-linux-amd64 -O republicd
chmod +x republicd
sudo mv republicd /usr/local/bin/republicd

republicd version
```


Must be `v0.3.0`



---

# 📈 STEP 14 — Final Sync Check

```bash
republicd status | jq '.sync_info'
```

Must be `false`



# 🔐 NEXT STEPS (After Sync)

Create wallet:

```bash
republicd keys add my-node
```

Recover wallet:

```bash
republicd keys add my-node --recover
```

Create validator after full sync.

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



