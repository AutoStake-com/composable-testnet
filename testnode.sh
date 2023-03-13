KEY="mykey"
CHAINID="test-1"
MONIKER="localtestnet"
KEYALGO="secp256k1"
KEYRING="test"
LOGLEVEL="info"
# to trace evm
#TRACE="--trace"
TRACE=""

# validate dependencies are installed
command -v jq > /dev/null 2>&1 || { echo >&2 "jq not installed. More info: https://stedolan.github.io/jq/download/"; exit 1; }

# remove existing daemon
rm -rf ~/.polytope*

polytoped config keyring-backend $KEYRING
polytoped config chain-id $CHAINID

# if $KEY exists it should be deleted
polytoped keys add $KEY --keyring-backend $KEYRING --algo $KEYALGO

# Set moniker and chain-id for Evmos (Moniker can be anything, chain-id must be an integer)
polytoped init $MONIKER --chain-id $CHAINID 

# Allocate genesis accounts (cosmos formatted addresses)
polytoped add-genesis-account $KEY 100000000000000000000000000stake --keyring-backend $KEYRING

# Sign genesis transaction
polytoped gentx $KEY 1000000000000000000000stake --keyring-backend $KEYRING --chain-id $CHAINID

# Collect genesis tx
polytoped collect-gentxs

# Run this to ensure everything worked and that the genesis file is setup correctly
polytoped validate-genesis

if [[ $1 == "pending" ]]; then
  echo "pending mode is on, please wait for the first block committed."
fi

# update request max size so that we can upload the light client
# '' -e is a must have params on mac, if use linux please delete before run
sed -i'' -e 's/max_body_bytes = /max_body_bytes = 1/g' ~/.polytope/config/config.toml

# Start the node (remove the --pruning=nothing flag if historical queries are not needed)
polytoped start --pruning=nothing  --minimum-gas-prices=0.0001stake 
