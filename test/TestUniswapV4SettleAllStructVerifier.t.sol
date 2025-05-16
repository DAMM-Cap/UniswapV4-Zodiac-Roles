// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {UniswapV4SettleAllStructVerifier} from "@src/UniswapV4SettleAllStructVerifier.sol";
import {Test} from "@forge-std/Test.sol";
import {console2} from "@forge-std/console2.sol";
import {Lib} from "@src/Lib.sol";
import {Currency} from "@univ4-core/src/types/Currency.sol";
import {CalldataDecoder} from "@univ4-periphery/src/libraries/CalldataDecoder.sol";

contract TestUniswapV4SettleAllStructVerifier is Test {
    UniswapV4SettleAllStructVerifier verifier;

    function setUp() public {
        verifier = new UniswapV4SettleAllStructVerifier();
    }

    function test_settleall_struct_verifier_currency0(Currency currency0, Currency currency1, uint256 maxAmount)
        public
    {
        // Encode the data as expected by the verifier
        bytes memory data = abi.encode(currency0, maxAmount);

        // Generate extraData from both currencies
        bytes6 t0 = Lib.tokenHeader(currency0);
        bytes6 t1 = Lib.tokenHeader(currency1);

        // Pack the two 48-bit slices into a single 96-bit value
        uint96 packed = (uint96(uint48(bytes6(t0))) << 48) | uint96(uint48(bytes6(t1)));
        bytes12 extraData = bytes12(packed);

        // Call the check function
        (bool ok, bytes32 reason) = verifier.check(address(0), 0, data, 0, 0, data.length, extraData);

        // Verify the results
        assertTrue(ok);
        assertEq(reason, bytes32(0));
    }

    function test_settleall_struct_verifier_currency1(Currency currency0, Currency currency1, uint256 maxAmount)
        public
    {
        // Encode the data but with currency1 instead of currency0
        bytes memory data = abi.encode(currency1, maxAmount);

        // Generate extraData from both currencies
        bytes6 t0 = Lib.tokenHeader(currency0);
        bytes6 t1 = Lib.tokenHeader(currency1);

        // Pack the two 48-bit slices into a single 96-bit value
        uint96 packed = (uint96(uint48(bytes6(t0))) << 48) | uint96(uint48(bytes6(t1)));
        bytes12 extraData = bytes12(packed);

        // Call the check function
        (bool ok, bytes32 reason) = verifier.check(address(0), 0, data, 0, 0, data.length, extraData);

        // Verify the results
        assertTrue(ok);
        assertEq(reason, bytes32(0));
    }

    function test_settleall_struct_verifier_invalid_currency(
        Currency currency0,
        Currency currency1,
        Currency invalidCurrency,
        uint256 maxAmount
    ) public {
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
        bytes memory data = abi.encode(invalidCurrency, maxAmount);

        // Generate extraData from the valid currencies
        uint96 packed = (uint96(uint48(bytes6(t0))) << 48) | uint96(uint48(bytes6(t1)));
        bytes12 extraData = bytes12(packed);

        // Call the check function
        (bool ok, bytes32 reason) = verifier.check(address(0), 0, data, 0, 0, data.length, extraData);

        // Verify the results
        assertFalse(ok);
        assertEq(reason, Lib.INVALID_CURRENCY);
    }
}
