// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {CalldataDecoder} from "@univ4-periphery/src/libraries/CalldataDecoder.sol";
import {ICustomCondition} from "./interfaces/ICustomCondition.sol";
import "./Lib.sol";

contract UniswapV4SettleAllStructVerifier is ICustomCondition {
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
        (Currency currency, uint256 maxAmount) =
            bytes(data[location + Lib.ARRAY_LENGTH_OFFSET:location + size]).decodeCurrencyAndUint256();

        if (!currency.checkCurrency0Or1(extraData)) {
            return (false, Lib.INVALID_CURRENCY);
        }

        return (true, 0);
    }
}
