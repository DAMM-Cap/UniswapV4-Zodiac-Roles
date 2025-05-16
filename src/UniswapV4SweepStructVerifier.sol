// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {CalldataDecoder} from "@univ4-periphery/src/libraries/CalldataDecoder.sol";
import {ICustomCondition} from "./interfaces/ICustomCondition.sol";
import {IModifier} from "./interfaces/IModifier.sol";
import "./Lib.sol";

contract UniswapV4SweepStructVerifier is ICustomCondition {
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
        (Currency currency, address sweepTo) = data.decodeCurrencyAndAddress();

        if (!currency.checkCurrency0Or1(extraData)) {
            return (false, Lib.INVALID_CURRENCY);
        }

        if (sweepTo != IModifier(msg.sender).avatar()) {
            return (false, Lib.INVALID_RECIPIENT);
        }

        return (true, 0);
    }
}
