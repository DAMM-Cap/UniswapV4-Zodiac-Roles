// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {UniswapV4TakeAllStructVerifier} from "@src/UniswapV4TakeAllStructVerifier.sol";
import {Test} from "@forge-std/Test.sol";
import {console2} from "@forge-std/console2.sol";
import {Lib} from "@src/Lib.sol";
import {Currency} from "@univ4-core/src/types/Currency.sol";
import {CalldataDecoder} from "@univ4-periphery/src/libraries/CalldataDecoder.sol";
import {TestingUtils, TestUtils} from "./TestingUtils.sol";

contract TestUniswapV4TakeAllStructVerifier is TestUtils {
    using TestingUtils for bytes;

    UniswapV4TakeAllStructVerifier verifier;

    function setUp() public {
        verifier = new UniswapV4TakeAllStructVerifier();
    }

    function test_takeall_struct_verifier_currency0(
        Currency currency0,
        Currency currency1,
        uint256 minAmount,
        uint256 dirt
    ) public {
        // Encode the data as expected by the verifier
        bytes memory data = abi.encode(currency0, minAmount).dirtyBytes(dirt);

        // Generate extraData from both currencies
        bytes12 extraData = TestingUtils.generateExtraData(currency0, currency1);

        // Call the check function
        (bool ok, bytes32 reason) = callVerifierCheck(address(verifier), data, extraData);

        // Verify the results
        assertValidCheck(ok, reason);
    }

    function test_takeall_struct_verifier_currency1(
        Currency currency0,
        Currency currency1,
        uint256 minAmount,
        uint256 dirt
    ) public {
        // Encode the data but with currency1 instead of currency0
        bytes memory data = abi.encode(currency1, minAmount).dirtyBytes(dirt);

        // Generate extraData from both currencies
        bytes12 extraData = TestingUtils.generateExtraData(currency0, currency1);

        // Call the check function
        (bool ok, bytes32 reason) = callVerifierCheck(address(verifier), data, extraData);

        // Verify the results
        assertValidCheck(ok, reason);
    }

    function test_takeall_struct_verifier_invalid_currency(
        Currency currency0,
        Currency currency1,
        Currency invalidCurrency,
        uint256 minAmount,
        uint256 dirt
    ) public {
        // Set up assumptions for invalid currency
        assumeInvalidCurrency(invalidCurrency, currency0, currency1);

        // Encode the data with the invalid currency
        bytes memory data = abi.encode(invalidCurrency, minAmount).dirtyBytes(dirt);

        // Generate extraData from the valid currencies
        bytes12 extraData = TestingUtils.generateExtraData(currency0, currency1);

        // Call the check function
        (bool ok, bytes32 reason) = callVerifierCheck(address(verifier), data, extraData);

        // Verify the results
        assertInvalidCheck(ok, reason, Lib.INVALID_CURRENCY);
    }
}
