#!/usr/bin/env bash
set -e

echo "======================================"
echo " Republic AI Testnet Validator Setup"
echo "======================================"
echo ""

read -p "Enter your moniker: " MONIKER

VERSION="v0.1.0"
CHAIN_ID="raitestnet_77701-1"
HOME_DIR="$HOME/.republicd"
SNAP_RPC="https://statesync.republicai.io"

sudo apt update -y
sudo apt install -y curl jq

echo "➡ Installing republicd..."
curl -L https://media.githubusercontent.com/media/RepublicAI/networks/main/testnet/releases/${VERSION}/republicd-linux-amd64 -o /tmp/republicd
chmod +x /tmp/republicd
sudo mv /tmp/republicd /usr/local/bin/republicd

echo "➡ Initializing node..."
republicd init "$MONIKER" --chain-id $CHAIN_ID --home $HOME_DIR

echo "➡ Downloading genesis..."
curl -s https://raw.githubusercontent.com/RepublicAI/networks/main/testnet/genesis.json \
  > $HOME_DIR/config/genesis.json

echo "➡ Configuring state sync..."
LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height)
TRUST_HEIGHT=$((LATEST_HEIGHT - 1000))
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$TRUST_HEIGHT" | jq -r .result.block_id.hash)

sed -i -E "s|enable *=.*|enable = true|; \
s|rpc_servers *=.*|rpc_servers = \"$SNAP_RPC,$SNAP_RPC\"|; \
s|trust_height *=.*|trust_height = $TRUST_HEIGHT|; \
s|trust_hash *=.*|trust_hash = \"$TRUST_HASH\"|" \
$HOME_DIR/config/config.toml

echo "➡ Adding peers..."
PEERS="e281dc6e4ebf5e32fb7e6c4a111c06f02a1d4d62@3.92.139.74:26656,cfb2cb90a241f7e1c076a43954f0ee6d42794d04@54.173.6.183:26656,dc254b98cebd6383ed8cf2e766557e3d240100a9@54.227.57.160:26656"
sed -i -E "s|persistent_peers *=.*|persistent_peers = \"$PEERS\"|" \
$HOME_DIR/config/config.toml

echo "➡ Creating wallet..."
republicd keys add "$MONIKER"

echo ""
echo "⚠️  Send faucet tokens to your wallet now."
echo "Press ENTER once tokens are received."
read

echo "➡ Creating validator..."
republicd tx staking create-validator \
  --amount=1000000000000000000000arai \
  --pubkey=$(republicd comet show-validator --home $HOME_DIR) \
  --moniker="$MONIKER" \
  --chain-id=$CHAIN_ID \
  --commission-rate="0.10" \
  --commission-max-rate="0.20" \
  --commission-max-change-rate="0.01" \
  --min-self-delegation="1" \
  --gas=auto \
  --gas-adjustment=1.5 \
  --gas-prices="250000000arai" \
  --from="$MONIKER"

echo ""
echo "✅ Validator creation transaction sent!"
echo "🚀 Welcome to Republic AI Testnet, $MONIKER"
