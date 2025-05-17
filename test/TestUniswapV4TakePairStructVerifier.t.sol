// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {UniswapV4TakePairStructVerifier} from "@src/UniswapV4TakePairStructVerifier.sol";
import {Test} from "@forge-std/Test.sol";
import {IModifier} from "@src/interfaces/IModifier.sol";
import {console2} from "@forge-std/console2.sol";
import {Lib} from "@src/Lib.sol";
import {Currency} from "@univ4-core/src/types/Currency.sol";
import {CalldataDecoder} from "@univ4-periphery/src/libraries/CalldataDecoder.sol";
import "./TestingUtils.sol";

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

contract TestUniswapV4TakePairStructVerifier is Test {
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
        bytes6 t0 = Lib.tokenHeader(currency0);
        bytes6 t1 = Lib.tokenHeader(currency1);

        // Pack the two 48-bit slices into a single 96-bit value
        uint96 packed = (uint96(uint48(bytes6(t0))) << 48) | uint96(uint48(bytes6(t1)));
        bytes12 extraData = bytes12(packed);

        // Use vm.prank to set msg.sender to the mock modifier
        vm.prank(address(mockModifier));

        // Call the check function
        (bool ok, bytes32 reason) = verifier.check(address(0), 0, data, 0, 0, data.length, extraData);

        // Verify the results
        assertTrue(ok);
        assertEq(reason, bytes32(0));
    }

    function test_take_pair_invalid_currency0(
        Currency validCurrency0,
        Currency validCurrency1,
        Currency invalidCurrency0,
        uint256 dirt
    ) public {
        // Ensure the currencies are different
        vm.assume(Currency.unwrap(validCurrency0) != Currency.unwrap(invalidCurrency0));

        // Further ensure the token headers are different
        bytes6 validHeader0 = Lib.tokenHeader(validCurrency0);
        bytes6 invalidHeader0 = Lib.tokenHeader(invalidCurrency0);
        vm.assume(validHeader0 != invalidHeader0);

        // Encode the data with invalid currency0, valid currency1, and valid recipient
        bytes memory data = abi.encode(invalidCurrency0, validCurrency1, avatarAddress).dirtyBytes(dirt);

        // Generate extraData from the valid currencies
        bytes6 t1 = Lib.tokenHeader(validCurrency1);

        // Pack the two 48-bit slices into a single 96-bit value
        uint96 packed = (uint96(uint48(bytes6(validHeader0))) << 48) | uint96(uint48(bytes6(t1)));
        bytes12 extraData = bytes12(packed);

        // Use vm.prank to set msg.sender to the mock modifier
        vm.prank(address(mockModifier));

        // Call the check function
        (bool ok, bytes32 reason) = verifier.check(address(0), 0, data, 0, 0, data.length, extraData);

        // Verify the results
        assertFalse(ok);
        assertEq(reason, Lib.INVALID_CURRENCY0);
    }

    function test_take_pair_invalid_currency1(
        Currency validCurrency0,
        Currency validCurrency1,
        Currency invalidCurrency1,
        uint256 dirt
    ) public {
        // Ensure the currencies are different
        vm.assume(Currency.unwrap(validCurrency1) != Currency.unwrap(invalidCurrency1));

        // Further ensure the token headers are different
        bytes6 validHeader1 = Lib.tokenHeader(validCurrency1);
        bytes6 invalidHeader1 = Lib.tokenHeader(invalidCurrency1);
        vm.assume(validHeader1 != invalidHeader1);

        // Encode the data with valid currency0, invalid currency1, and valid recipient
        bytes memory data = abi.encode(validCurrency0, invalidCurrency1, avatarAddress).dirtyBytes(dirt);

        // Generate extraData from the valid currencies
        bytes6 t0 = Lib.tokenHeader(validCurrency0);

        // Pack the two 48-bit slices into a single 96-bit value
        uint96 packed = (uint96(uint48(bytes6(t0))) << 48) | uint96(uint48(bytes6(validHeader1)));
        bytes12 extraData = bytes12(packed);

        // Use vm.prank to set msg.sender to the mock modifier
        vm.prank(address(mockModifier));

        // Call the check function
        (bool ok, bytes32 reason) = verifier.check(address(0), 0, data, 0, 0, data.length, extraData);

        // Verify the results
        assertFalse(ok);
        assertEq(reason, Lib.INVALID_CURRENCY1);
    }

    function test_take_pair_invalid_recipient(
        Currency currency0,
        Currency currency1,
        address invalidRecipient,
        uint256 dirt
    ) public {
        // Ensure the recipient is not the avatar
        vm.assume(invalidRecipient != avatarAddress);
        vm.assume(invalidRecipient != address(0));

        // Encode the data with valid currencies but invalid recipient
        bytes memory data = abi.encode(currency0, currency1, invalidRecipient).dirtyBytes(dirt);

        // Generate extraData from both currencies
        bytes6 t0 = Lib.tokenHeader(currency0);
        bytes6 t1 = Lib.tokenHeader(currency1);

        // Pack the two 48-bit slices into a single 96-bit value
        uint96 packed = (uint96(uint48(bytes6(t0))) << 48) | uint96(uint48(bytes6(t1)));
        bytes12 extraData = bytes12(packed);

        // Use vm.prank to set msg.sender to the mock modifier
        vm.prank(address(mockModifier));

        // Call the check function
        (bool ok, bytes32 reason) = verifier.check(address(0), 0, data, 0, 0, data.length, extraData);

        // Verify the results
        assertFalse(ok);
        assertEq(reason, Lib.INVALID_RECIPIENT);
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
        vm.assume(Currency.unwrap(validCurrency0) != Currency.unwrap(invalidCurrency0));
        vm.assume(Currency.unwrap(validCurrency1) != Currency.unwrap(invalidCurrency1));
        vm.assume(invalidRecipient != avatarAddress);
        vm.assume(invalidRecipient != address(0));

        // Further ensure the token headers are different
        bytes6 validHeader0 = Lib.tokenHeader(validCurrency0);
        bytes6 invalidHeader0 = Lib.tokenHeader(invalidCurrency0);
        bytes6 validHeader1 = Lib.tokenHeader(validCurrency1);
        bytes6 invalidHeader1 = Lib.tokenHeader(invalidCurrency1);

        vm.assume(validHeader0 != invalidHeader0);
        vm.assume(validHeader1 != invalidHeader1);

        // Encode the data with all invalid parameters
        bytes memory data = abi.encode(invalidCurrency0, invalidCurrency1, invalidRecipient).dirtyBytes(dirt);

        // Generate extraData from the valid currencies
        uint96 packed = (uint96(uint48(bytes6(validHeader0))) << 48) | uint96(uint48(bytes6(validHeader1)));
        bytes12 extraData = bytes12(packed);

        // Use vm.prank to set msg.sender to the mock modifier
        vm.prank(address(mockModifier));

        // Call the check function
        (bool ok, bytes32 reason) = verifier.check(address(0), 0, data, 0, 0, data.length, extraData);

        // Verify the results - should fail on the first check (currency0)
        assertFalse(ok);
        assertEq(reason, Lib.INVALID_CURRENCY0);
    }
}
