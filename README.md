# Republic AI Testnet Validator Setup Guide

<img width="1710" height="652" alt="image" src="https://github.com/user-attachments/assets/3a0dc4b0-f9f1-45aa-b4ef-865632dc8ffe" />


## 📌 Important Notes (Read First)

- **Moniker**: Your validator name (e.g., `xyzguide`). Use lowercase letters, numbers, or `-` only — no spaces.
- **Chain ID**: `raitestnet_77701-1`
- **Denom**: `arai` (base unit), `RAI` (human-readable)
- **Decimals**: 18 (e.g., 1 RAI = 1000000000000000000 arai)
- **Min Gas Price**: `250000000arai`
- **Minimum Self-Delegation**: 1 RAI (1000000000000000000 arai) .
- **Testnet Tokens**: Get from faucet (https://points.republicai.io/faucet) or Discord MOD . You need at least 1.1–2 RAI for min delegation + fees (more for higher delegation), but need at least 1k RAI for being in top 100.
- **System Requirements**: Ubuntu 22.04 LTS, 4+ CPU cores (8 recommended), 16GB+ RAM, 500GB+ SSD.

This guide uses **state sync** for faster syncing (recommended).

---

## Step 1: Install Dependencies

Update your system and install required packages:

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl jq nano build-essential git make wget
```

---

## Step 2: Install Republicd Binary

Download the latest version (v0.2.1):

```bash
VERSION="v0.2.1"
curl -L "https://github.com/RepublicAI/networks/releases/download/${VERSION}/republicd-linux-amd64" -o /tmp/republicd
chmod +x /tmp/republicd
sudo mv /tmp/republicd /usr/local/bin/republicd
```

Verify:

```bash
republicd version  # Should show v0.1.0
```

---

## Step 3: Initialize Node

Set your home directory and initialize:

```bash
REPUBLIC_HOME="$HOME/.republicd"
republicd init xyzguide --chain-id raitestnet_77701-1 --home "$REPUBLIC_HOME"
```

Replace `xyzguide` with your moniker.

---

## Step 4: Download Genesis File

```bash
curl -s https://raw.githubusercontent.com/RepublicAI/networks/main/testnet/genesis.json > "$REPUBLIC_HOME/config/genesis.json"
```

---

## Step 5: Configure State Sync (Fast Sync – Recommended)

Get the latest sync parameters:

```bash
SNAP_RPC="https://statesync.republicai.io"

LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height)
BLOCK_HEIGHT=$((LATEST_HEIGHT - 1000))
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)
```

Update config.toml:

```bash
sed -i -E "s|enable *=.*|enable = true|; \
s|rpc_servers *=.*|rpc_servers = \"$SNAP_RPC,$SNAP_RPC\"|; \
s|trust_height *=.*|trust_height = $BLOCK_HEIGHT|; \
s|trust_hash *=.*|trust_hash = \"$TRUST_HASH\"|" \
"$REPUBLIC_HOME/config/config.toml"
```

---

## Step 6: Add Persistent Peers

```bash
PEERS="e281dc6e4ebf5e32fb7e6c4a111c06f02a1d4d62@3.92.139.74:26656,cfb2cb90a241f7e1c076a43954f0ee6d42794d04@54.173.6.183:26656,dc254b98cebd6383ed8cf2e766557e3d240100a9@54.227.57.160:26656"

sed -i -E "s|persistent_peers *=.*|persistent_peers = \"$PEERS\"|" \
"$REPUBLIC_HOME/config/config.toml"
```

---

## Step 7: Set Up Systemd Service (for Auto-Restart)

Create the service file:

```bash
sudo nano /etc/systemd/system/republicd.service
```

Paste this (replace `ubuntu` with your actual user if different):

```ini
[Unit]
Description=Republic AI Testnet Node
After=network-online.target

[Service]
User=ubuntu
WorkingDirectory=/home/ubuntu
ExecStart=/usr/local/bin/republicd start \
  --home /home/ubuntu/.republicd \
  --chain-id raitestnet_77701-1
Restart=always
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
```

Enable and start:

```bash
sudo systemctl daemon-reload
sudo systemctl enable republicd
sudo systemctl start republicd
```

Check logs:

```bash
journalctl -u republicd -f
```

---

## Step 8: Wait for Full Sync

Monitor sync status:

```bash
republicd status | jq '.sync_info'
```

Wait until `"catching_up": false`.
<img width="1898" height="264" alt="image" src="https://github.com/user-attachments/assets/c40a5788-5718-495f-869f-318a88dbbc29" />

---

## Step 9: Create Wallet

Add a new wallet or import one:

```bash
republicd keys add xyzguide  # New wallet - save the mnemonic securely!
# OR import existing
republicd keys add xyzguide --recover
```
<img width="578" height="64" alt="image" src="https://github.com/user-attachments/assets/cf2bab05-854d-4bc2-b70f-6529976fd9a2" />

Check your address:

```bash
republicd keys show xyzguide -a  # e.g., rai1xcr42hlh85kutaqtmyxw2zu8pr3nk5rks6nlp5
```
<img width="604" height="88" alt="image" src="https://github.com/user-attachments/assets/ef30aa7a-4812-4d38-b95b-a35e547efb34" />


Replace `xyzguide` with your moniker.

---

## Step 10: Get Testnet Tokens

- Use the faucet: https://points.republicai.io/faucet (log in with X/Discord/wallet)


Check balance:

```bash
republicd query bank balances $(republicd keys show xyzguide -a)
```

Wait until you have at least 1.1+ RAI.

---

## Step 11: Create Validator

Get pubkey:

```bash
republicd comet show-validator
```

Create `validator.json`:

```bash
nano validator.json
```

Paste (replace `"key"` with your pubkey output):

```json
{
  "pubkey": {"@type":"/cosmos.crypto.ed25519.PubKey","key":"if+Eqq9Fa4pAEB9TZO2peb8b9QpbC9Poq0Z/iifJ/Ok="},
  "amount": "1000000000000000000arai",
  "moniker": "xyzguide",
  "identity": "",
  "website": "",
  "security_contact": "",
  "details": "Republic AI testnet validator - xyzguide",
  "commission-rate": "0.10",
  "commission-max-rate": "0.20",
  "commission-max-change-rate": "0.01",
  "min-self-delegation": "1"
}
```
Replace `xyzguide` with your moniker.

Send transaction:

```bash
republicd tx staking create-validator validator.json \
  --from xyzguide \
  --chain-id raitestnet_77701-1 \
  --gas auto \
  --gas-adjustment 1.5 \
  --gas-prices 1000000000arai \
  --yes
```

Adjust `--gas-prices` if fee error occurs (e.g., 1500000000arai).

---

## Step 12: Verify Validator

Get operator address:

```bash
republicd keys show xyzguide --bech val -a  # e.g., raivaloper1xcr42hlh85kutaqtmyxw2zu8pr3nk5rkh0nz2z
```
Replace `xyzguide` with your moniker.
<img width="1476" height="77" alt="image" src="https://github.com/user-attachments/assets/b5056ac0-bf67-41d4-83a3-e7cb50ff498a" />

Check status:

```bash
republicd query staking validator $(republicd keys show xyzguide --bech val -a)
```

- Status: `BOND_STATUS_BONDED`
- Jailed: `false`

Check the explorer: https://explorer.republicai.io (search for the operator address).

---

## Step 13: Link Validator on Dashboard 

On https://points.republicai.io :

- Use Option 2: Transaction Verification
- Send small tx with memo (your username/referral):

```bash
republicd tx bank send \
  xyzguide \
  $(republicd keys show xyzguide -a) \
  1000000000000000arai \
  --chain-id raitestnet_77701-1 \
  --from xyzguide \
  --note "xyz" \
  --gas auto \
  --gas-adjustment 1.5 \
  --gas-prices 1000000000arai \
  --yes
```
Replace `xyzguide` with your moniker.

change xyz Your username: zoroxeth or @zoroxeth
Your referral code or full URL: 9F674A : 
Below is the example: 
<img width="648" height="243" alt="image" src="https://github.com/user-attachments/assets/44fb3200-4c2a-4711-9363-d07d542ae395" />

- Copy txhash from output
- Paste on website and submit

---

## Useful Commands

- Sync status: `republicd status | jq '.sync_info'`
- Validator info: `republicd query staking validator [operator_addr]`
- Unjail: `republicd tx slashing unjail --from xyzguide --chain-id raitestnet_77701-1 --gas auto --gas-adjustment 1.5 --gas-prices 1000000000arai --yes`
- Delegate more: `republicd tx staking delegate [operator_addr] 1000000000000000000arai --from xyzguide --chain-id raitestnet_77701-1 --gas auto --gas-adjustment 1.5 --gas-prices 1000000000arai --yes`

Replace `xyzguide` with your moniker.

---

## Troubleshooting

- **Sequence mismatch**: Add `--sequence 1` to txs if first tx.
- **Insufficient fee**: Increase `--gas-prices` to 1500000000arai or higher.
- **Sync stuck**: Restart service (`sudo systemctl restart republicd`).
- **Not enough tokens**: Ask in Discord for more.

---

## 👤 Author

* **Handle:** 0xDarkSeidBull
* **Role:** Republic Validator
* **GitHub:** [https://github.com/0xDarkSeidBull](https://github.com/0xDarkSeidBull)
* **Wallet:** `0x3bc6348e1e569e97bd8247b093475a4ac22b9fd4`


  ## If this guide helped you:

⭐ [![Stars](https://img.shields.io/github/stars/0xDarkSeidBull/republic-ai-validator)](https://github.com/0xDarkSeidBull/g0xDarkSeidBull/republic-ai-validator/stargazers)

🧾 [![License](https://img.shields.io/github/license/0xDarkSeidBull/republic-ai-validator)](LICENSE)

🔁 Share with new builders

---
