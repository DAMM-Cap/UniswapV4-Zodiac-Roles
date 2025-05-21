// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {CalldataDecoder} from "@univ4-periphery/src/libraries/CalldataDecoder.sol";
import {ICustomCondition} from "./interfaces/ICustomCondition.sol";
import {IModifier} from "./interfaces/IModifier.sol";
import "./Lib.sol";

/// @author DAMM Capital - https://dammcap.finance
contract UniswapV4SweepStructVerifier is ICustomCondition {
    using CalldataDecoder for bytes;
    using Lib for Currency;

    function check(
        address,
        uint256,
        bytes calldata data,
        uint8, // 0 = Call, 1 = DelegateCall
        uint256 location,
        uint256 size,
        bytes12 extraData
    ) external view returns (bool, bytes32) {
        (Currency currency, address sweepTo) =
            bytes(data[location + Lib.ARRAY_LENGTH_OFFSET:location + size]).decodeCurrencyAndAddress();

        if (!currency.checkCurrency0Or1(extraData)) {
            return (false, Lib.INVALID_CURRENCY);
        }

        if (sweepTo != IModifier(msg.sender).avatar()) {
            return (false, Lib.INVALID_RECIPIENT);
        }

        return (true, 0);
    }
}
