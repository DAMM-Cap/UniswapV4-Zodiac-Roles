// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Lib} from "@src/Lib.sol";
import {Currency} from "@univ4-core/src/types/Currency.sol";
import {Test, console2} from "@forge-std/Test.sol";
import {ICustomCondition} from "@src/interfaces/ICustomCondition.sol";

library TestingUtils {
    /// @dev UniswapV4 payloads are composed of bytes[]. In solidity, the first word of a bytes type is a
    /// uint256 that determines its length. Even though the bytes[] elements are abi.encoded structs,
    /// Zodiac still passes them to the verifiers prefixed with their length.
    /// expected: abi.encode(struct) returns bytes type without the length prefix.
    /// reality: zodiac passes abi.encodePacked(length, abi.encode(struct));
    /// @notice this function is used to simulate this type of bytes packing for testing purposes.
    function dirtyBytes(bytes memory clean, uint256 dirt) internal pure returns (bytes memory dirty) {
        dirty = abi.encodePacked(dirt, clean);
    }

    function dirtyBytes(bytes memory clean) internal pure returns (bytes memory dirty) {
        dirty = abi.encodePacked(uint256(1), clean);
    }

    /// @notice Generate extraData from two currencies for Uniswap V4 verifiers
    /// @param currency0 The first currency
    /// @param currency1 The second currency
    /// @return extraData Packed 12-byte extraData for the verifier
    function generateExtraData(Currency currency0, Currency currency1) internal pure returns (bytes12 extraData) {
        bytes6 t0 = Lib.tokenHeader(currency0);
        bytes6 t1 = Lib.tokenHeader(currency1);

        // Pack the two 48-bit slices into a single 96-bit value
        uint96 packed = (uint96(uint48(bytes6(t0))) << 48) | uint96(uint48(bytes6(t1)));
        extraData = bytes12(packed);
    }
}

abstract contract TestUtils is Test {
    function assertValidCheck(bool ok, bytes32 reason) internal pure {
        assertTrue(ok);
        assertEq(reason, bytes32(0));
    }

    function assertInvalidCheck(bool ok, bytes32 reason, bytes32 expectedError) internal pure {
        assertFalse(ok);
        assertEq(reason, expectedError);
    }

    function assumeInvalidCurrency(Currency invalidCurrency, Currency validCurrency0, Currency validCurrency1)
        internal
        pure
    {
        vm.assume(Currency.unwrap(invalidCurrency) != Currency.unwrap(validCurrency0));
        vm.assume(Currency.unwrap(invalidCurrency) != Currency.unwrap(validCurrency1));

        // Further ensure the token headers are different for a robust test
        bytes6 invalidHeader = Lib.tokenHeader(invalidCurrency);
        bytes6 t0 = Lib.tokenHeader(validCurrency0);
        bytes6 t1 = Lib.tokenHeader(validCurrency1);

        vm.assume(invalidHeader != t0);
        vm.assume(invalidHeader != t1);
    }

    function assumeInvalidCurrencySingle(Currency invalidCurrency, Currency validCurrency) internal pure {
        vm.assume(Currency.unwrap(invalidCurrency) != Currency.unwrap(validCurrency));

        // Further ensure the token headers are different for a robust test
        bytes6 invalidHeader = Lib.tokenHeader(invalidCurrency);
        bytes6 validHeader = Lib.tokenHeader(validCurrency);
        vm.assume(invalidHeader != validHeader);
    }

    function assumeInvalidRecipient(address invalidRecipient, address validRecipient) internal pure {
        vm.assume(invalidRecipient != validRecipient);
        vm.assume(invalidRecipient != address(0));
    }

    function callVerifierCheck(address verifier, bytes memory data, bytes12 extraData)
        internal
        view
        returns (bool ok, bytes32 reason)
    {
        (ok, reason) = ICustomCondition(verifier).check(address(0), 0, data, 0, 0, data.length, extraData);
    }

    function callVerifierCheck(
        address verifier,
        bytes memory data,
        bytes12 extraData,
        uint8 mode,
        uint256 location,
        uint256 size
    ) internal returns (bool ok, bytes32 reason) {
        (ok, reason) = ICustomCondition(verifier).check(address(0), 0, data, mode, location, size, extraData);
    }

    function callVerifierCheckWithModifier(
        address verifier,
        address modifierAddress,
        bytes memory data,
        bytes12 extraData
    ) internal returns (bool ok, bytes32 reason) {
        // Set msg.sender to the modifier before making the call
        vm.prank(modifierAddress);

        (ok, reason) = ICustomCondition(verifier).check(address(0), 0, data, 0, 0, data.length, extraData);
    }
}
