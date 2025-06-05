// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {CalldataDecoder} from "@univ4-periphery/src/libraries/CalldataDecoder.sol";
import {ICustomCondition} from "./interfaces/ICustomCondition.sol";
import {IModifier} from "./interfaces/IModifier.sol";
import "./Lib.sol";

/// @author DAMM Capital - https://dammcap.finance
contract UniswapV4MintStructVerifier is ICustomCondition {
    using CalldataDecoder for bytes;
    using Lib for Currency;

    function decode(bytes calldata input, uint256 location, uint256 size)
        public
        view
        returns (
            PoolKey memory poolKey,
            int24 tickLower,
            int24 tickUpper,
            uint256 liquidity,
            uint128 amount0Max,
            uint128 amount1Max,
            address owner,
            bytes memory hookData
        )
    {
        return bytes(input[location + Lib.ARRAY_LENGTH_OFFSET:location + size]).decodeMintParams();
    }

    function check(
        address,
        uint256,
        bytes calldata data,
        uint8, // 0 = Call, 1 = DelegateCall
        uint256 location,
        uint256 size,
        bytes12 extraData
    ) external view returns (bool, bytes32) {
        try this.decode(data, location, size) returns (
            PoolKey memory poolKey,
            int24 tickLower,
            int24 tickUpper,
            uint256 liquidity,
            uint128 amount0Max,
            uint128 amount1Max,
            address owner,
            bytes memory hookData
        ) {
            if (!poolKey.currency0.checkCurrency0(extraData)) {
                return (false, Lib.INVALID_CURRENCY0);
            }

            if (!poolKey.currency1.checkCurrency1(extraData)) {
                return (false, Lib.INVALID_CURRENCY1);
            }

            if (owner != IModifier(msg.sender).avatar()) {
                return (false, Lib.INVALID_OWNER);
            }
        } catch {
            return (false, Lib.INVALID_ENCODING);
        }

        return (true, 0);
    }
}
