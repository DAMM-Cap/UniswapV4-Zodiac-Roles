
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
- Format: `bytes12` defined by `abi.encodePacked(keccack256(token0).head(6), keccack256(token1).head(6))`
- Note: This key system has potential for collisions
- Security: Safe as long as the underlying Gnosis Safe has only pre-approved trusted tokens to the permit2, universal router, and position manager

## Deployments

### Arbitrum

| Verifier | Address |
|----------|---------|
| Position Mint Verifier | `0xA0B62aCD2fD69720744d03d5E11b021D715BEc04` |
| Take All Verifier | `0x16e75e91aa5C9c0976d48bd36035A71f2E54A18c` |
| Settle All Verifier | `0x66ABaaC16293a9d2a291f3C7A88d8B1b65953752` |
| Swap Exact In Single Verifier | `0xB21d73547b40438bA661Dd4B6EA99cF938F67Af8` |
| Swap Exact Out Single Verifier | `0xc3f0bC7CfFec898EC5aD9d40e4f7eA80d9641B7B` |
| Sweep Verifier | `0xc6af34fE57e4293D58eA2ad3D68b3f8BaA43A5D4` |
| Take Pair Verifier | `0x78a8bBa010bb4E0EC0A3A50049C77cFd3abEA495` |
| Decrease Liquidity Verifier | `0x34fA7F29A69989cdA0822f3F65F2aA47e3C80f3A` |
| Settle Pair Verifier | `0x83a502479931508f977321615BA7e6F2AA933Cf1` |

## Audits

- [Certora DAMM Security Assessment Report](./audits/Certora%20DAMM%20Security%20Assessment%20Report.pdf) - Security assessment completed by Certora

## License
MIT

Developed by DAMM Capital team
