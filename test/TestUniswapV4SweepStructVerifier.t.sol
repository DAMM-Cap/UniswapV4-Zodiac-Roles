// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {UniswapV4SweepStructVerifier} from "@src/UniswapV4SweepStructVerifier.sol";
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

contract TestUniswapV4SweepStructVerifier is TestUtils {
    using TestingUtils for bytes;

    UniswapV4SweepStructVerifier verifier;
    MockModifier mockModifier;
    address avatarAddress;

    function setUp() public {
        avatarAddress = makeAddr("avatar");
        verifier = new UniswapV4SweepStructVerifier();
        mockModifier = new MockModifier(avatarAddress, address(this));
    }

    function test_sweep_pair_valid_currency_valid_recipient(Currency currency0, Currency currency1, uint256 dirt)
        public
    {
        // Encode the data as expected by the verifier - sweepTo is the avatar
        bytes memory data = abi.encode(currency0, avatarAddress).dirtyBytes(dirt);

        // Generate extraData from both currencies
        bytes12 extraData = TestingUtils.generateExtraData(currency0, currency1);

        // Call the check function with the mock modifier
        (bool ok, bytes32 reason) =
            callVerifierCheckWithModifier(address(verifier), address(mockModifier), data, extraData);

        // Verify the results
        assertValidCheck(ok, reason);
    }

    function test_sweep_pair_currency1_valid_recipient(Currency currency0, Currency currency1, uint256 dirt) public {
        // Encode the data with currency1 instead of currency0
        bytes memory data = abi.encode(currency1, avatarAddress).dirtyBytes(dirt);

        // Generate extraData from both currencies
        bytes12 extraData = TestingUtils.generateExtraData(currency0, currency1);

        // Call the check function with the mock modifier
        (bool ok, bytes32 reason) =
            callVerifierCheckWithModifier(address(verifier), address(mockModifier), data, extraData);

        // Verify the results
        assertValidCheck(ok, reason);
    }

    function test_sweep_pair_invalid_currency(
        Currency currency0,
        Currency currency1,
        Currency invalidCurrency,
        uint256 dirt
    ) public {
        // Set up assumptions for invalid currency
        assumeInvalidCurrency(invalidCurrency, currency0, currency1);

        // Encode the data with the invalid currency
        bytes memory data = abi.encode(invalidCurrency, avatarAddress).dirtyBytes(dirt);

        // Generate extraData from the valid currencies
        bytes12 extraData = TestingUtils.generateExtraData(currency0, currency1);

        // Call the check function with the mock modifier
        (bool ok, bytes32 reason) =
            callVerifierCheckWithModifier(address(verifier), address(mockModifier), data, extraData);

        // Verify the results
        assertInvalidCheck(ok, reason, Lib.INVALID_CURRENCY);
    }

    function test_sweep_pair_invalid_recipient(
        Currency currency0,
        Currency currency1,
        address invalidRecipient,
        uint256 dirt
    ) public {
        // Set up assumptions for invalid recipient
        assumeInvalidRecipient(invalidRecipient, avatarAddress);

        // Encode the data with a valid currency but invalid recipient
        bytes memory data = abi.encode(currency0, invalidRecipient).dirtyBytes(dirt);

        // Generate extraData from both currencies
        bytes12 extraData = TestingUtils.generateExtraData(currency0, currency1);

        // Call the check function with the mock modifier
        (bool ok, bytes32 reason) =
            callVerifierCheckWithModifier(address(verifier), address(mockModifier), data, extraData);

        // Verify the results
        assertInvalidCheck(ok, reason, Lib.INVALID_RECIPIENT);
    }

    function test_sweep_pair_invalid_currency_and_recipient(
        Currency currency0,
        Currency currency1,
        Currency invalidCurrency,
        address invalidRecipient,
        uint256 dirt
    ) public {
        // Set up assumptions for invalid values
        assumeInvalidCurrency(invalidCurrency, currency0, currency1);
        assumeInvalidRecipient(invalidRecipient, avatarAddress);

        // Encode the data with both invalid currency and recipient
        bytes memory data = abi.encode(invalidCurrency, invalidRecipient).dirtyBytes(dirt);

        // Generate extraData from the valid currencies
        bytes12 extraData = TestingUtils.generateExtraData(currency0, currency1);

        // Call the check function with the mock modifier
        (bool ok, bytes32 reason) =
            callVerifierCheckWithModifier(address(verifier), address(mockModifier), data, extraData);

        // Verify the results - should fail on currency check first
        assertInvalidCheck(ok, reason, Lib.INVALID_CURRENCY);
    }
}
