// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {CalldataDecoder} from "@univ4-periphery/src/libraries/CalldataDecoder.sol";
import {ICustomCondition} from "./interfaces/ICustomCondition.sol";
import "./Lib.sol";

/// @author DAMM Capital - https://dammcap.finance
contract UniswapV4TakeAllStructVerifier is ICustomCondition {
    using CalldataDecoder for bytes;
    using Lib for Currency;

    function decode(bytes calldata input, uint256 location, uint256 size)
        public
        view
        returns (Currency currency, uint256 minAmount)
    {
        return bytes(input[location + Lib.ARRAY_LENGTH_OFFSET:location + size]).decodeCurrencyAndUint256();
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
        try this.decode(data, location, size) returns (Currency currency, uint256 minAmount) {
            if (!currency.checkCurrency0Or1(extraData)) {
                return (false, Lib.INVALID_CURRENCY);
            }
        } catch {
            return (false, Lib.INVALID_ENCODING);
        }

        return (true, 0);
    }
}
