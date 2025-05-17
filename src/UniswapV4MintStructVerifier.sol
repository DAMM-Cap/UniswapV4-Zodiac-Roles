// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {CalldataDecoder} from "@univ4-periphery/src/libraries/CalldataDecoder.sol";
import {ICustomCondition} from "./interfaces/ICustomCondition.sol";
import {IModifier} from "./interfaces/IModifier.sol";
import "./Lib.sol";

contract UniswapV4MintStructVerifier is ICustomCondition {
    using CalldataDecoder for bytes;
    using Lib for Currency;

    /// @notice extraData in combination with token approvals to the position manager
    /// garuantees that only pre-approved tokens can be used to provide liquidity
    function check(
        address,
        uint256,
        bytes calldata data,
        uint8, // 0 = Call, 1 = DelegateCall
        uint256 location,
        uint256 size,
        bytes12 extraData
    ) external view returns (bool, bytes32) {
        (
            PoolKey calldata poolKey,
            int24 tickLower,
            int24 tickUpper,
            uint256 liquidity,
            uint128 amount0Max,
            uint128 amount1Max,
            address owner,
            bytes calldata hookData
        ) = bytes(data[location + Lib.ARRAY_LENGTH_OFFSET:location + size]).decodeMintParams();

        if (!poolKey.currency0.checkCurrency0(extraData)) {
            return (false, Lib.INVALID_CURRENCY0);
        }

        if (!poolKey.currency1.checkCurrency1(extraData)) {
            return (false, Lib.INVALID_CURRENCY1);
        }

        if (owner != IModifier(msg.sender).avatar()) {
            return (false, Lib.INVALID_OWNER);
        }

        return (true, 0);
    }
}
