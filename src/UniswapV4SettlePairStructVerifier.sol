// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {CalldataDecoder} from "@univ4-periphery/src/libraries/CalldataDecoder.sol";
import {ICustomCondition} from "./interfaces/ICustomCondition.sol";
import "./Lib.sol";

/// @author DAMM Capital - https://dammcap.finance
contract UniswapV4SettlePairStructVerifier is ICustomCondition {
    using CalldataDecoder for bytes;
    using Lib for Currency;

    function decode(bytes calldata input, uint256 location, uint256 size)
        public
        view
        returns (Currency currency0, Currency currency1)
    {
        return bytes(input[location + Lib.ARRAY_LENGTH_OFFSET:location + size]).decodeCurrencyPair();
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
        try this.decode(data, location, size) returns (Currency currency0, Currency currency1) {
            if (!currency0.checkCurrency0(extraData)) {
                return (false, Lib.INVALID_CURRENCY0);
            }

            if (!currency1.checkCurrency1(extraData)) {
                return (false, Lib.INVALID_CURRENCY1);
            }
        } catch {
            return (false, Lib.INVALID_ENCODING);
        }

        return (true, 0);
    }
}
