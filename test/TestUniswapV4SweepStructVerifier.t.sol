// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {UniswapV4SweepStructVerifier} from "@src/UniswapV4SweepStructVerifier.sol";
import {Test} from "@forge-std/Test.sol";
import {IModifier} from "@src/interfaces/IModifier.sol";
import {console2} from "@forge-std/console2.sol";
import {Lib} from "@src/Lib.sol";
import {Currency} from "@univ4-core/src/types/Currency.sol";
import {CalldataDecoder} from "@univ4-periphery/src/libraries/CalldataDecoder.sol";

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

contract TestUniswapV4SweepStructVerifier is Test {
    UniswapV4SweepStructVerifier verifier;
    MockModifier mockModifier;
    address avatarAddress;

    function setUp() public {
        avatarAddress = makeAddr("avatar");
        verifier = new UniswapV4SweepStructVerifier();
        mockModifier = new MockModifier(avatarAddress, address(this));
    }

    function test_sweep_pair_valid_currency_valid_recipient(Currency currency0, Currency currency1) public {
        // Encode the data as expected by the verifier - sweepTo is the avatar
        bytes memory data = abi.encode(currency0, avatarAddress);

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

    function test_sweep_pair_currency1_valid_recipient(Currency currency0, Currency currency1) public {
        // Encode the data with currency1 instead of currency0
        bytes memory data = abi.encode(currency1, avatarAddress);

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

    function test_sweep_pair_invalid_currency(Currency currency0, Currency currency1, Currency invalidCurrency)
        public
    {
        // Assume the invalid currency is different from both currency0 and currency1
        vm.assume(Currency.unwrap(invalidCurrency) != Currency.unwrap(currency0));
        vm.assume(Currency.unwrap(invalidCurrency) != Currency.unwrap(currency1));

        // Further ensure the token headers are different for a robust test
        bytes6 invalidHeader = Lib.tokenHeader(invalidCurrency);
        bytes6 t0 = Lib.tokenHeader(currency0);
        bytes6 t1 = Lib.tokenHeader(currency1);

        vm.assume(invalidHeader != t0);
        vm.assume(invalidHeader != t1);

        // Encode the data with the invalid currency
        bytes memory data = abi.encode(invalidCurrency, avatarAddress);

        // Generate extraData from the valid currencies
        uint96 packed = (uint96(uint48(bytes6(t0))) << 48) | uint96(uint48(bytes6(t1)));
        bytes12 extraData = bytes12(packed);

        // Use vm.prank to set msg.sender to the mock modifier
        vm.prank(address(mockModifier));

        // Call the check function
        (bool ok, bytes32 reason) = verifier.check(address(0), 0, data, 0, 0, data.length, extraData);

        // Verify the results
        assertFalse(ok);
        assertEq(reason, Lib.INVALID_CURRENCY);
    }

    function test_sweep_pair_invalid_recipient(Currency currency0, Currency currency1, address invalidRecipient)
        public
    {
        // Ensure the recipient is not the avatar
        vm.assume(invalidRecipient != avatarAddress);
        vm.assume(invalidRecipient != address(0));

        // Encode the data with a valid currency but invalid recipient
        bytes memory data = abi.encode(currency0, invalidRecipient);

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

    function test_sweep_pair_invalid_currency_and_recipient(
        Currency currency0,
        Currency currency1,
        Currency invalidCurrency,
        address invalidRecipient
    ) public {
        // Set up assumptions for invalid values
        vm.assume(Currency.unwrap(invalidCurrency) != Currency.unwrap(currency0));
        vm.assume(Currency.unwrap(invalidCurrency) != Currency.unwrap(currency1));
        vm.assume(invalidRecipient != avatarAddress);
        vm.assume(invalidRecipient != address(0));

        // Further ensure the token headers are different
        bytes6 invalidHeader = Lib.tokenHeader(invalidCurrency);
        bytes6 t0 = Lib.tokenHeader(currency0);
        bytes6 t1 = Lib.tokenHeader(currency1);

        vm.assume(invalidHeader != t0);
        vm.assume(invalidHeader != t1);

        // Encode the data with both invalid currency and recipient
        bytes memory data = abi.encode(invalidCurrency, invalidRecipient);

        // Generate extraData from the valid currencies
        uint96 packed = (uint96(uint48(bytes6(t0))) << 48) | uint96(uint48(bytes6(t1)));
        bytes12 extraData = bytes12(packed);

        // Use vm.prank to set msg.sender to the mock modifier
        vm.prank(address(mockModifier));

        // Call the check function
        (bool ok, bytes32 reason) = verifier.check(address(0), 0, data, 0, 0, data.length, extraData);

        // Verify the results - should fail on currency check first
        assertFalse(ok);
        assertEq(reason, Lib.INVALID_CURRENCY);
    }
}
