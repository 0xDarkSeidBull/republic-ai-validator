# 🚀 Republic AI Testnet Validator Setup Guide (FINAL & COMPLETE)

---

## ⚠️ IMPORTANT — READ FIRST

### 🔴 RULE #1: RUN EVERYTHING AS ROOT

This entire guide **must be executed as the `root` user**.

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

* Do **not** skip steps
* Do **not** run cleanup or `systemctl` commands unless instructed
* Configuration files are strict — mistakes will crash the node

---

## 📝 IMPORTANT NOTE ABOUT MONIKER

Wherever `xyzguide` appears, **replace it with your own moniker / key name**.
Use the **same moniker everywhere**:

* Node initialization
* Wallet keys
* Validator creation
* Transactions

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
| OS                      | Ubuntu 22.04 LTS             |
| Recommended Hardware    | 8 CPU / 16GB RAM / 500GB SSD |

---

## 🔧 Stability Decision (Important)

### ❌ Why State Sync Is Disabled

* RPC endpoints are overloaded
* Light client verification failures
* Snapshot rejections and node crashes

### ✅ Final Decision

**State Sync Disabled → Normal P2P Sync Enabled**
Slower sync, but **100% stable**.

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

Verify:

```bash
republicd version
```

---

## Step 3: Initialize Node

```bash
republicd init xyzguide --chain-id raitestnet_77701-1
```

---

## Step 4: Create `priv_validator_state.json` (MANDATORY)

```bash
mkdir -p /root/.republicd/data

cat <<EOF > /root/.republicd/data/priv_validator_state.json
{
  "height": "0",
  "round": 0,
  "step": 0
}
EOF
```

---

## Step 5: Download Genesis

```bash
curl -s https://raw.githubusercontent.com/RepublicAI/networks/main/testnet/genesis.json \
> /root/.republicd/config/genesis.json
```

---

## Step 6: Disable State Sync

```bash
nano /root/.republicd/config/config.toml
```

Set:

```toml
[statesync]
enable = false
```

---

## Step 7: Add Persistent Peer

```bash
sed -i -E "s|persistent_peers *=.*|persistent_peers = \"6313f892ee50ca0b2d6cc6411ac5207dbf2d164b@95.216.102.220:13356\"|" \
/root/.republicd/config/config.toml
```

---

## Step 8: Fix Mempool Crash (CRITICAL)

Ensure these lines are **not empty**:

```toml
experimental_max_gossip_connections_to_persistent_peers = 4
experimental_max_gossip_connections_to_non_persistent_peers = 4
```

---

## Step 9: P2P Speed Configuration

Ensure **no duplicate keys**:

```toml
[p2p]
send_rate = 5120000
recv_rate = 5120000
```

---

## Step 10: Create Systemd Service

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
  --home /root/.republicd \
  --chain-id raitestnet_77701-1
Restart=always
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
```

```bash
systemctl daemon-reload
systemctl enable republicd
systemctl start republicd
```

---

## Step 11: Wait for Full Sync

```bash
republicd status | jq .sync_info
```

Proceed only when:

```json
"catching_up": false
```

---

## Step 12: Create or Recover Wallet

```bash
republicd keys add xyzguide
# or
republicd keys add xyzguide --recover
```

---

## Step 13: Get Testnet Tokens

👉 [https://points.republicai.io/faucet](https://points.republicai.io/faucet)
Minimum: **1.1+ RAI**

---

## 🚀 Step 14: CREATE VALIDATOR (COMPLETE)

### 1️⃣ Confirm Sync Status

```bash
republicd status | jq .sync_info.catching_up
```

Must return `false`.

---

### 2️⃣ Get Validator PubKey

```bash
republicd comet show-validator
```

---

### 3️⃣ Create `validator.json`

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

### 4️⃣ Send Create-Validator Transaction

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

## Step 15: Verify Validator

```bash
republicd query staking validator \
$(republicd keys show xyzguide --bech val -a)
```

Expected:

* `BOND_STATUS_BONDED`
* `jailed: false`

Explorer: [https://explorer.republicai.io](https://explorer.republicai.io)

---

## Step 16: Link Validator to Dashboard

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


## 👤 Author

* **Handle:** 0xDarkSeidBull
* **Role:** Republic Validator
* **GitHub:** [https://github.com/0xDarkSeidBull](https://github.com/0xDarkSeidBull)
* **Wallet:** `0x3bc6348e1e569e97bd8247b093475a4ac22b9fd4`


  
## If this guide helped you:

⭐ [![Stars](https://img.shields.io/github/stars/0xDarkSeidBull/republic-ai-validator)](https://github.com/0xDarkSeidBull/republic-ai-validator/stargazers)

🧾 [![License](https://img.shields.io/github/license/0xDarkSeidBull/republic-ai-validator)](LICENSE)

🔁 Share with new builders

Submit TX hash on: [https://points.republicai.io](https://points.republicai.io)

---



