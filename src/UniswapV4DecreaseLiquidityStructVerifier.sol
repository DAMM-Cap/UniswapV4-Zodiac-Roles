// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {CalldataDecoder} from "@univ4-periphery/src/libraries/CalldataDecoder.sol";
import {ICustomCondition} from "./interfaces/ICustomCondition.sol";
import {IModifier} from "./interfaces/IModifier.sol";
import "./Lib.sol";

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

/// @author DAMM Capital - https://dammcap.finance
contract UniswapV4DecreaseLiquidityStructVerifier is ICustomCondition {
    using CalldataDecoder for bytes;
    using Lib for Currency;

    function check(
        address to,
        uint256,
        bytes calldata data,
        uint8, // 0 = Call, 1 = DelegateCall
        uint256 location,
        uint256 size,
        bytes12 extraData
    ) external view returns (bool, bytes32) {
        (uint256 tokenId, uint256 liquidity, uint128 amount0Min, uint128 amount1Min, bytes calldata hookData) =
            bytes(data[location + Lib.ARRAY_LENGTH_OFFSET:location + size]).decodeModifyLiquidityParams();
        /// check if tokenId is owned by avatar using ERC721
        if (IERC721(to).ownerOf(tokenId) != IModifier(msg.sender).avatar()) {
            return (false, Lib.INVALID_TOKEN_ID);
        }

        return (true, 0);
    }
}
