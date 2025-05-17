// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {UniswapV4TakePairStructVerifier} from "@src/UniswapV4TakePairStructVerifier.sol";
import {Test} from "@forge-std/Test.sol";
import {IModifier} from "@src/interfaces/IModifier.sol";
import {console2} from "@forge-std/console2.sol";
import {Lib} from "@src/Lib.sol";
import {Currency} from "@univ4-core/src/types/Currency.sol";
import {CalldataDecoder} from "@univ4-periphery/src/libraries/CalldataDecoder.sol";
import {TestingUtils, TestUtils} from "./TestingUtils.sol";

contract MockModifier is IModifier {
    address public _avatar;
    address public _target;

    constructor(address avatar_, address target_) {
        _avatar = avatar_;
        _target = target_;
    }

    function avatar() external view returns (address) {
        return _avatar;
    }

    function target() external view returns (address) {
        return _target;
    }
}

contract TestUniswapV4TakePairStructVerifier is TestUtils {
    using TestingUtils for bytes;

    UniswapV4TakePairStructVerifier verifier;
    MockModifier mockModifier;
    address avatarAddress;

    function setUp() public {
        avatarAddress = makeAddr("avatar");
        verifier = new UniswapV4TakePairStructVerifier();
        mockModifier = new MockModifier(avatarAddress, address(this));
    }

    function test_take_pair_valid_parameters(Currency currency0, Currency currency1, uint256 dirt) public {
        // Encode the data with both currencies and the avatar as recipient
        bytes memory data = abi.encode(currency0, currency1, avatarAddress).dirtyBytes(dirt);

        // Generate extraData from both currencies
        bytes12 extraData = TestingUtils.generateExtraData(currency0, currency1);

        // Call the check function with the mock modifier
        (bool ok, bytes32 reason) =
            callVerifierCheckWithModifier(address(verifier), address(mockModifier), data, extraData);

        // Verify the results
        assertValidCheck(ok, reason);
    }

    function test_take_pair_invalid_currency0(
        Currency validCurrency0,
        Currency validCurrency1,
        Currency invalidCurrency0,
        uint256 dirt
    ) public {
        // Set up assumptions for invalid currency0
        assumeInvalidCurrencySingle(invalidCurrency0, validCurrency0);

        // Encode the data with invalid currency0, valid currency1, and valid recipient
        bytes memory data = abi.encode(invalidCurrency0, validCurrency1, avatarAddress).dirtyBytes(dirt);

        // Generate extraData from the valid currencies
        bytes12 extraData = TestingUtils.generateExtraData(validCurrency0, validCurrency1);

        // Call the check function with the mock modifier
        (bool ok, bytes32 reason) =
            callVerifierCheckWithModifier(address(verifier), address(mockModifier), data, extraData);

        // Verify the results
        assertInvalidCheck(ok, reason, Lib.INVALID_CURRENCY0);
    }

    function test_take_pair_invalid_currency1(
        Currency validCurrency0,
        Currency validCurrency1,
        Currency invalidCurrency1,
        uint256 dirt
    ) public {
        // Set up assumptions for invalid currency1
        assumeInvalidCurrencySingle(invalidCurrency1, validCurrency1);

        // Encode the data with valid currency0, invalid currency1, and valid recipient
        bytes memory data = abi.encode(validCurrency0, invalidCurrency1, avatarAddress).dirtyBytes(dirt);

        // Generate extraData from the valid currencies
        bytes12 extraData = TestingUtils.generateExtraData(validCurrency0, validCurrency1);

        // Call the check function with the mock modifier
        (bool ok, bytes32 reason) =
            callVerifierCheckWithModifier(address(verifier), address(mockModifier), data, extraData);

        // Verify the results
        assertInvalidCheck(ok, reason, Lib.INVALID_CURRENCY1);
    }

    function test_take_pair_invalid_recipient(
        Currency currency0,
        Currency currency1,
        address invalidRecipient,
        uint256 dirt
    ) public {
        // Set up assumptions for invalid recipient
        assumeInvalidRecipient(invalidRecipient, avatarAddress);

        // Encode the data with valid currencies but invalid recipient
        bytes memory data = abi.encode(currency0, currency1, invalidRecipient).dirtyBytes(dirt);

        // Generate extraData from both currencies
        bytes12 extraData = TestingUtils.generateExtraData(currency0, currency1);

        // Call the check function with the mock modifier
        (bool ok, bytes32 reason) =
            callVerifierCheckWithModifier(address(verifier), address(mockModifier), data, extraData);

        // Verify the results
        assertInvalidCheck(ok, reason, Lib.INVALID_RECIPIENT);
    }

    function test_take_pair_multiple_invalid_parameters(
        Currency validCurrency0,
        Currency validCurrency1,
        Currency invalidCurrency0,
        Currency invalidCurrency1,
        address invalidRecipient,
        uint256 dirt
    ) public {
        // Set up assumptions for invalid values
        assumeInvalidCurrencySingle(invalidCurrency0, validCurrency0);
        assumeInvalidCurrencySingle(invalidCurrency1, validCurrency1);
        assumeInvalidRecipient(invalidRecipient, avatarAddress);

        // Encode the data with all invalid parameters
        bytes memory data = abi.encode(invalidCurrency0, invalidCurrency1, invalidRecipient).dirtyBytes(dirt);

        // Generate extraData from the valid currencies
        bytes12 extraData = TestingUtils.generateExtraData(validCurrency0, validCurrency1);

        // Call the check function with the mock modifier
        (bool ok, bytes32 reason) =
            callVerifierCheckWithModifier(address(verifier), address(mockModifier), data, extraData);

        // Verify the results - should fail on the first check (currency0)
        assertInvalidCheck(ok, reason, Lib.INVALID_CURRENCY0);
    }
}
