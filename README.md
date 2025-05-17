
# UniswapV4 Zodiac Permission Helpers

Custom verification contracts for Zodiac Roles V2 (v2.1) that enable precise permission control for Uniswap V4 interactions.

## Overview

These contracts solve specific limitations in the current Zodiac Roles implementation that prevented proper handling of Uniswap V4 permissions. The implementation was not possible using the zodiac js SDK due to these limitations. These verifier contracts function as calldata struct decoders to enable fine-grained transaction verification.

## Usage

Run tests with:
```
forge test --via-ir
```

## Technical Caveats [IMPORTANT]

### Calldata Offset

Verifiers offset calldata inputs by 0x20 (one word) to skip the bytes array length field. This is necessary because Zodiac passes encoded structs as bytes arrays rather than direct ABI-encoded structs.

In our testing framework:
- "Dirty" refers to the bytes array with length
- "Clean" refers to the data with the first word trimmed

### Token Key System

The `extraData` field passes metadata to Zodiac verifiers as a key identifying the token pair:
- Format: `bytes12` defined by `abi.encodePacked(token0.head(6), token1.head(6))`
- Note: This key system has potential for collisions
- Security: Safe as long as the underlying Gnosis Safe has only pre-approved trusted tokens to the permit2, universal router, and position manager

## Deployments

### Arbitrum
Refer to `/broadcast/DeployVerifiers.s.sol/42161/run-latest.json`

## Audits
None completed yet

## License
MIT

Developed by DAMM Capital team
