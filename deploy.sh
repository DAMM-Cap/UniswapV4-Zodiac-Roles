# Load the environment variables
source .env

# Run the script with verification
forge script script/DeployVerifiers.s.sol:DeployVerifiers --via-ir --rpc-url $ARBI_RPC_URL --broadcast --verify --etherscan-api-key $ARBISCAN_KEY --optimizer-runs 1000000