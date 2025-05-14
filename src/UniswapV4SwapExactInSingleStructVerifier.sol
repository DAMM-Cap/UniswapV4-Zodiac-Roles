// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {CalldataDecoder} from "@univ4-periphery/src/libraries/CalldataDecoder.sol";
import {ICustomCondition} from "./interfaces/ICustomCondition.sol";
import {IV4Router} from "@univ4-periphery/src/interfaces/IV4Router.sol";
import "./Lib.sol";

contract UniswapV4SwapExactInSingleStructVerifier is ICustomCondition {
    using CalldataDecoder for bytes;
    using Lib for Currency;

    /// @notice extraData in combination with token approvals to the position manager
    /// garuantees that only pre-approved tokens can be used to provide liquidity
    function check(
        address,
        uint256,
        bytes calldata data,
        uint8, // 0 = Call, 1 = DelegateCall
        uint256,
        uint256,
        bytes12 extraData
    ) external view returns (bool, bytes32) {
        (IV4Router.ExactInputSingleParams calldata swapParams) = data.decodeSwapExactInSingleParams();

        if (!swapParams.poolKey.currency0.checkCurrency0(extraData)) {
            return (false, Lib.INVALID_CURRENCY0);
        }

        if (!swapParams.poolKey.currency1.checkCurrency1(extraData)) {
            return (false, Lib.INVALID_CURRENCY1);
        }

        return (true, 0);
    }
}
