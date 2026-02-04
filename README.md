# 🟢 Republic AI Testnet – Validator Setup Guide


---

## 📌 IMPORTANT NOTE (READ FIRST)

> **`<your-moniker>` = your username / validator name**
>
> Examples:
>
> * GitHub username: `alice` → moniker = `alice`
> * Discord name: `gurupedia` → moniker = `gurupedia`
>
> ⚠️ Do **NOT** use spaces.
> ✔️ Use lowercase letters, numbers, or `-`.

---

## 🌐 Network Information

* **Chain ID:** `raitestnet_77701-1`
* **Denom:** `arai` (base), `RAI`
* **Decimals:** 18
* **Min Gas Price:** `250000000arai`

---

## 🖥️ System Requirements

* Ubuntu 22.04 LTS
* 4+ CPU cores (8 recommended for validators)
* 16GB+ RAM
* 500GB+ SSD


---

# 🔹 GUIDE 1: Manual Node Installation (Recommended)

This method is best for **advanced users** and **long-term validators**.

---

## 0️⃣ Install dependencies:

```bash
sudo apt update && sudo apt install -y curl jq
```

## 1️⃣ Install `republicd`

```bash
VERSION="v0.1.0"
curl -L https://media.githubusercontent.com/media/RepublicAI/networks/main/testnet/releases/${VERSION}/republicd-linux-amd64 -o /tmp/republicd
chmod +x /tmp/republicd
sudo mv /tmp/republicd /usr/local/bin/republicd
```

---

## 2️⃣ Initialize Node

```bash
REPUBLIC_HOME="$HOME/.republicd"
republicd init <your-moniker> \
  --chain-id raitestnet_77701-1 \
  --home "$REPUBLIC_HOME"
```

📌 **Note:**
`<your-moniker>` = your username / validator name

---

## 3️⃣ Download Genesis

```bash
curl -s https://raw.githubusercontent.com/RepublicAI/networks/main/testnet/genesis.json \
> "$REPUBLIC_HOME/config/genesis.json"
```

---

## 4️⃣ Configure State Sync (Fast Sync – Recommended)

```bash
SNAP_RPC="https://statesync.republicai.io"

LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height)
BLOCK_HEIGHT=$((LATEST_HEIGHT - 1000))
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)
```

```bash
sed -i -E "s|enable *=.*|enable = true|; \
s|rpc_servers *=.*|rpc_servers = \"$SNAP_RPC,$SNAP_RPC\"|; \
s|trust_height *=.*|trust_height = $BLOCK_HEIGHT|; \
s|trust_hash *=.*|trust_hash = \"$TRUST_HASH\"|" \
"$REPUBLIC_HOME/config/config.toml"
```

---

## 5️⃣ Add Persistent Peers

```bash
PEERS="e281dc6e4ebf5e32fb7e6c4a111c06f02a1d4d62@3.92.139.74:26656,\
cfb2cb90a241f7e1c076a43954f0ee6d42794d04@54.173.6.183:26656,\
dc254b98cebd6383ed8cf2e766557e3d240100a9@54.227.57.160:26656"

sed -i -E "s|persistent_peers *=.*|persistent_peers = \"$PEERS\"|" \
"$REPUBLIC_HOME/config/config.toml"
```

---

## 6️⃣ 🔁 Systemd Service (DO THIS BEFORE VALIDATOR)

> ⚠️ **This step MUST be done before validator creation**

---

### Create Service File

```bash
sudo nano /etc/systemd/system/republicd.service
```

Paste below (replace `ubuntu` if needed):

```ini
[Unit]
Description=Republic Protocol Node
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

---

### Enable & Start Service

```bash
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable republicd
sudo systemctl start republicd
```

---

### Check Logs

```bash
journalctl -u republicd -f
```

---

## 7️⃣ Wait for Full Sync

```bash
republicd status | jq '.sync_info'
```

✅ Required:

```json
"catching_up": false
```

---

## 8️⃣ Create Wallet

```bash
republicd keys add <your-moniker>
```

📌 **Note:**
`<your-moniker>` = your username / validator name

---

## 9️⃣ Create Validator (Activation Step)

```bash
republicd tx staking create-validator \
  --amount=1000000000000000000000arai \
  --pubkey=$(republicd comet show-validator) \
  --moniker="<your-moniker>" \
  --chain-id=raitestnet_77701-1 \
  --commission-rate="0.10" \
  --commission-max-rate="0.20" \
  --commission-max-change-rate="0.01" \
  --min-self-delegation="1" \
  --gas=auto \
  --gas-adjustment=1.5 \
  --gas-prices="250000000arai" \
  --from=<your-moniker>
```

📌 **Note:**
`<your-moniker>` = your username / validator name

🎉 **Validator is now ACTIVE once bonded**

---

# 🛠️ Useful Commands (Manual Guide)

---

## 🔍 Check Sync Status

```bash
republicd status | jq '.sync_info'
```

---

## 👤 Validator Info

```bash
republicd query staking validator \
$(republicd keys show <your-moniker> --bech val -a)
```

📌 **Note:**
`<your-moniker>` = your username / validator name

---

## 🔓 Unjail Validator

```bash
republicd tx slashing unjail \
  --from <your-moniker> \
  --chain-id raitestnet_77701-1 \
  --gas auto \
  --gas-adjustment 1.5 \
  --gas-prices 250000000arai
```

📌 **Note:**
`<your-moniker>` = your username / validator name

---

## 🤝 Delegate Tokens

```bash
republicd tx staking delegate \
<validator-address> <amount>arai \
--from <your-moniker> \
--chain-id raitestnet_77701-1 \
--gas auto \
--gas-adjustment 1.5 \
--gas-prices 250000000arai
```

📌 **Note:**
`<your-moniker>` = your username / validator name

---

# ⚡ GUIDE 2: Single-Command Installation (Fastest)

---

## 📌 Note (Important)

**`your moniker = your username`**
This will be your **public validator name**.

---

## 🖥️ Requirements

* Ubuntu 22.04
* 4+ CPU, 16GB RAM, 500GB SSD

---

## ▶️ Step 1: Run the Command

Paste this in your terminal:

```bash
curl -fsSL https://raw.githubusercontent.com/0xDarkSeidBull/republic-ai-validator/main/install.sh | bash
```

---

## ▶️ Step 2: Enter Your Username

When asked:

```
Enter your moniker:
```

👉 Type **your username** and press **Enter**

---

## ▶️ Step 3: Save Wallet Details

* Set a password
* Save the recovery phrase safely

---

## ▶️ Step 4: Get Faucet Tokens

* Request testnet tokens from the Republic AI faucet
* Wait until tokens arrive

---

## ▶️ Step 5: Press ENTER

After receiving tokens, go back to terminal and press **ENTER**

---

## ▶️ Step 6: Validator Created 🎉

* Validator transaction is sent
* After bonding, your validator becomes **ACTIVE**

---

## 🔁 Recommended (After Setup)

Set up **systemd service** so your node:

* Auto-restarts
* Runs after reboot

---

## ✅ Summary

```text
Run command
→ Enter username
→ Save wallet
→ Get tokens
→ Press ENTER
→ Validator ACTIVE
```

---


