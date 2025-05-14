// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {UniswapV4SettlePairStructVerifier} from "@src/UniswapV4SettlePairStructVerifier.sol";
import {Test} from "@forge-std/Test.sol";
import {console2} from "@forge-std/console2.sol";
import {Lib} from "@src/Lib.sol";
import {Currency} from "@univ4-core/src/types/Currency.sol";
import {CalldataDecoder} from "@univ4-periphery/src/libraries/CalldataDecoder.sol";

contract TestUniswapV4SettlePairStructVerifier is Test {
    UniswapV4SettlePairStructVerifier verifier;

    function setUp() public {
        verifier = new UniswapV4SettlePairStructVerifier();
    }

    function test_settle_pair_valid_currencies(Currency currency0, Currency currency1) public {
        // Encode the data as expected by the verifier
        bytes memory data = abi.encode(currency0, currency1);
        
        // Generate extraData from both currencies
        bytes6 t0 = Lib.tokenHeader(currency0);
        bytes6 t1 = Lib.tokenHeader(currency1);

        // Pack the two 48-bit slices into a single 96-bit value
        uint96 packed = (uint96(uint48(bytes6(t0))) << 48) | uint96(uint48(bytes6(t1)));
        bytes12 extraData = bytes12(packed);

        // Call the check function
        (bool ok, bytes32 reason) = verifier.check(address(0), 0, data, 0, 0, 0, extraData);

        // Verify the results
        assertTrue(ok);
        assertEq(reason, bytes32(0));
    }

    function test_settle_pair_invalid_currency0(
        Currency validCurrency0,
        Currency validCurrency1,
        Currency invalidCurrency0
    ) public {
        // Ensure the currencies are different
        vm.assume(Currency.unwrap(validCurrency0) != Currency.unwrap(invalidCurrency0));
        
        // Further ensure the token headers are different
        bytes6 validHeader0 = Lib.tokenHeader(validCurrency0);
        bytes6 invalidHeader0 = Lib.tokenHeader(invalidCurrency0);
        vm.assume(validHeader0 != invalidHeader0);

        // Encode the data with the invalid currency0
        bytes memory data = abi.encode(invalidCurrency0, validCurrency1);
        
        // Generate extraData from the valid currencies
        bytes6 t1 = Lib.tokenHeader(validCurrency1);

        // Pack the two 48-bit slices into a single 96-bit value
        uint96 packed = (uint96(uint48(bytes6(validHeader0))) << 48) | uint96(uint48(bytes6(t1)));
        bytes12 extraData = bytes12(packed);

        // Call the check function
        (bool ok, bytes32 reason) = verifier.check(address(0), 0, data, 0, 0, 0, extraData);

        // Verify the results
        assertFalse(ok);
        assertEq(reason, Lib.INVALID_CURRENCY0);
    }

    function test_settle_pair_invalid_currency1(
        Currency validCurrency0,
        Currency validCurrency1,
        Currency invalidCurrency1
    ) public {
        // Ensure the currencies are different
        vm.assume(Currency.unwrap(validCurrency1) != Currency.unwrap(invalidCurrency1));
        
        // Further ensure the token headers are different
        bytes6 validHeader1 = Lib.tokenHeader(validCurrency1);
        bytes6 invalidHeader1 = Lib.tokenHeader(invalidCurrency1);
        vm.assume(validHeader1 != invalidHeader1);

        // Encode the data with the invalid currency1
        bytes memory data = abi.encode(validCurrency0, invalidCurrency1);
        
        // Generate extraData from the valid currencies
        bytes6 t0 = Lib.tokenHeader(validCurrency0);

        // Pack the two 48-bit slices into a single 96-bit value
        uint96 packed = (uint96(uint48(bytes6(t0))) << 48) | uint96(uint48(bytes6(validHeader1)));
        bytes12 extraData = bytes12(packed);

        // Call the check function
        (bool ok, bytes32 reason) = verifier.check(address(0), 0, data, 0, 0, 0, extraData);

        // Verify the results
        assertFalse(ok);
        assertEq(reason, Lib.INVALID_CURRENCY1);
    }

    function test_settle_pair_invalid_both_currencies(
        Currency validCurrency0,
        Currency validCurrency1,
        Currency invalidCurrency0,
        Currency invalidCurrency1
    ) public {
        // Ensure the currencies are different
        vm.assume(Currency.unwrap(validCurrency0) != Currency.unwrap(invalidCurrency0));
        vm.assume(Currency.unwrap(validCurrency1) != Currency.unwrap(invalidCurrency1));
        
        // Further ensure the token headers are different
        bytes6 validHeader0 = Lib.tokenHeader(validCurrency0);
        bytes6 invalidHeader0 = Lib.tokenHeader(invalidCurrency0);
        bytes6 validHeader1 = Lib.tokenHeader(validCurrency1);
        bytes6 invalidHeader1 = Lib.tokenHeader(invalidCurrency1);
        
        vm.assume(validHeader0 != invalidHeader0);
        vm.assume(validHeader1 != invalidHeader1);

        // Encode the data with both invalid currencies
        bytes memory data = abi.encode(invalidCurrency0, invalidCurrency1);
        
        // Generate extraData from the valid currencies
        uint96 packed = (uint96(uint48(bytes6(validHeader0))) << 48) | uint96(uint48(bytes6(validHeader1)));
        bytes12 extraData = bytes12(packed);

        // Call the check function
        (bool ok, bytes32 reason) = verifier.check(address(0), 0, data, 0, 0, 0, extraData);

        // Verify the results
        assertFalse(ok);
        assertEq(reason, Lib.INVALID_CURRENCY0); // The first check that fails determines the error
    }
}
