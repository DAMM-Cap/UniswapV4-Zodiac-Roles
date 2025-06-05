// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {CalldataDecoder} from "@univ4-periphery/src/libraries/CalldataDecoder.sol";
import {ICustomCondition} from "./interfaces/ICustomCondition.sol";
import {IV4Router} from "@univ4-periphery/src/interfaces/IV4Router.sol";
import "./Lib.sol";

/// @author DAMM Capital - https://dammcap.finance
contract UniswapV4SwapExactInSingleStructVerifier is ICustomCondition {
    using CalldataDecoder for bytes;
    using Lib for Currency;

    function decode(bytes calldata input, uint256 location, uint256 size)
        public
        view
        returns (IV4Router.ExactInputSingleParams memory swapParams)
    {
        return bytes(input[location + Lib.ARRAY_LENGTH_OFFSET:location + size]).decodeSwapExactInSingleParams();
    }

    function check(
        address,
        uint256 value,
        bytes calldata data,
        uint8, // 0 = Call, 1 = DelegateCall
        uint256 location,
        uint256 size,
        bytes12 extraData
    ) external view returns (bool, bytes32) {
        try this.decode(data, location, size) returns (IV4Router.ExactInputSingleParams memory swapParams) {
            if (!swapParams.poolKey.currency0.checkCurrency0(extraData)) {
                return (false, Lib.INVALID_CURRENCY0);
            }

            if (!swapParams.poolKey.currency1.checkCurrency1(extraData)) {
                return (false, Lib.INVALID_CURRENCY1);
            }

            if (swapParams.poolKey.currency0.isAddressZero()) {
                if (value != swapParams.amountIn) {
                    return (false, Lib.INVALID_VALUE);
                }
            }
        } catch {
            return (false, Lib.INVALID_ENCODING);
        }

        return (true, 0);
    }
}
