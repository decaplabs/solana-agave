#!/bin/bash

# Save this as test.sh and run: chmod +x test.sh && ./test.sh

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Setting up Solana Counter test...${NC}"

# Get the program ID (you'll need to update this after deployment)
PROGRAM_ID="DByqoBhZByfbFzWZALUEEYFDMB6r78DwdwmVT9ahhp95"

# Create a new keypair for the counter account
echo -e "${GREEN}Creating counter account keypair...${NC}"
solana-keygen new --no-bip39-passphrase -o counter-keypair.json --force

COUNTER_PUBKEY=$(solana-keygen pubkey counter-keypair.json)
echo "Counter account: $COUNTER_PUBKEY"

# Create the counter account
echo -e "${GREEN}Creating counter account...${NC}"
solana create-account $COUNTER_PUBKEY 8 $PROGRAM_ID --from counter-keypair.json

# Initialize counter (instruction 0)
echo -e "${GREEN}Initializing counter...${NC}"
solana program call $PROGRAM_ID initialize $COUNTER_PUBKEY

# Increment counter (instruction 1)
echo -e "${GREEN}Incrementing counter...${NC}"
solana program call $PROGRAM_ID increment $COUNTER_PUBKEY
solana program call $PROGRAM_ID increment $COUNTER_PUBKEY
solana program call $PROGRAM_ID increment $COUNTER_PUBKEY

# Check account data
echo -e "${GREEN}Counter account data:${NC}"
solana account $COUNTER_PUBKEY

echo -e "${BLUE}Test complete!${NC}"