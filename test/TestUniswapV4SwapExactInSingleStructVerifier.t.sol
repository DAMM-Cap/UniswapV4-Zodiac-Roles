// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {UniswapV4SwapExactInSingleStructVerifier} from "@src/UniswapV4SwapExactInSingleStructVerifier.sol";
import {Test} from "@forge-std/Test.sol";
import {console2} from "@forge-std/console2.sol";
import {Lib} from "@src/Lib.sol";
import {Currency} from "@univ4-core/src/types/Currency.sol";
import {PoolKey} from "@univ4-core/src/types/PoolKey.sol";
import {IV4Router} from "@univ4-periphery/src/interfaces/IV4Router.sol";
import {CalldataDecoder} from "@univ4-periphery/src/libraries/CalldataDecoder.sol";
import {IHooks} from "@univ4-core/src/interfaces/IHooks.sol";
import {TestingUtils, TestUtils} from "./TestingUtils.sol";

contract TestUniswapV4SwapExactInSingleStructVerifier is TestUtils {
    using TestingUtils for bytes;

    UniswapV4SwapExactInSingleStructVerifier verifier;

    function setUp() public {
        verifier = new UniswapV4SwapExactInSingleStructVerifier(10_000);
    }

    function test_swap_exact_in_single_valid_currencies(Currency currency0, Currency currency1, uint256 dirt) public {
        vm.assume(Currency.unwrap(currency0) != Currency.unwrap(currency1));
        vm.assume(Currency.unwrap(currency0) < Currency.unwrap(currency1));

        // Create a pool key with the currencies
        PoolKey memory poolKey =
            PoolKey({currency0: currency0, currency1: currency1, fee: 8, tickSpacing: 1, hooks: IHooks(address(0))});

        IV4Router.ExactInputSingleParams memory mockExactInputParams = IV4Router.ExactInputSingleParams({
            poolKey: poolKey,
            zeroForOne: true,
            amountIn: 1000,
            amountOutMinimum: 500,
            hookData: bytes("")
        });

        // Generate extraData from the same currencies
        bytes12 extraData = TestingUtils.generateExtraData(currency0, currency1);

        bytes memory payload = abi.encode(mockExactInputParams).dirtyBytes(dirt);

        // Call the check function
        uint256 value = currency0.isAddressZero() ? 1000 : 0;
        (bool ok, bytes32 reason) = callVerifierCheck(address(verifier), payload, extraData, value);

        // Verify the results
        assertValidCheck(ok, reason);
    }

    function test_swap_exact_in_single_invalid_fee(Currency currency0, Currency currency1, uint24 fee, uint256 dirt)
        public
    {
        vm.assume(Currency.unwrap(currency0) != Currency.unwrap(currency1));
        vm.assume(Currency.unwrap(currency0) < Currency.unwrap(currency1));

        vm.assume(fee > 0);
        vm.assume(fee < 10_000);

        verifier = new UniswapV4SwapExactInSingleStructVerifier(fee);

        // Create a pool key with the currencies
        PoolKey memory poolKey = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: fee + 1,
            tickSpacing: 1,
            hooks: IHooks(address(0))
        });

        IV4Router.ExactInputSingleParams memory mockExactInputParams = IV4Router.ExactInputSingleParams({
            poolKey: poolKey,
            zeroForOne: true,
            amountIn: 1000,
            amountOutMinimum: 500,
            hookData: bytes("")
        });

        bytes memory payload = abi.encode(mockExactInputParams).dirtyBytes(dirt);

        // Generate extraData from the same currencies
        bytes12 extraData = TestingUtils.generateExtraData(currency0, currency1);

        // Call the check function
        uint256 value = currency0.isAddressZero() ? 1000 : 0;
        (bool ok, bytes32 reason) = callVerifierCheck(address(verifier), payload, extraData, value);

        // Verify the results
        assertInvalidCheck(ok, reason, Lib.INVALID_FEE);
    }

    function test_swap_exact_in_single_valid_currencies_exact() public {
        Currency currency0 = Currency.wrap(address(0xaf88d065e77c8cC2239327C5EDb3A432268e5831));
        Currency currency1 = Currency.wrap(address(0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9));

        // Generate extraData from the same currencies
        bytes12 extraData = TestingUtils.generateExtraData(currency0, currency1);

        bytes memory mockExactInputParams =
            hex"3593564c000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000682781ab00000000000000000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000340000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000003060c0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000001e0000000000000000000000000000000000000000000000000000000000000024000000000000000000000000000000000000000000000000000000000000001600000000000000000000000000000000000000000000000000000000000000020000000000000000000000000af88d065e77c8cc2239327c5edb3a432268e5831000000000000000000000000fd086bc7cd5c481dcc9c85ebe478a1c0b69fcbb900000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000199db30000000000000000000000000000000000000000000000000000000000191822000000000000000000000000000000000000000000000000000000000000012000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000040000000000000000000000000af88d065e77c8cc2239327c5edb3a432268e58310000000000000000000000000000000000000000000000000000000000199db30000000000000000000000000000000000000000000000000000000000000040000000000000000000000000fd086bc7cd5c481dcc9c85ebe478a1c0b69fcbb90000000000000000000000000000000000000000000000000000000000191822";

        // Call the check function
        (bool ok, bytes32 reason) = callVerifierCheck(address(verifier), mockExactInputParams, extraData, 0, 516, 384);

        // Verify the results
        assertValidCheck(ok, reason);
    }

    function test_swap_exact_in_single_currency0_is_address_zero_value_check() public {
        // currency0 is zero address
        Currency currency0 = Currency.wrap(address(0));
        Currency currency1 = Currency.wrap(address(0x1234));
        uint128 amountIn = 1234;
        uint128 amountOutMinimum = 567;
        PoolKey memory poolKey =
            PoolKey({currency0: currency0, currency1: currency1, fee: 8, tickSpacing: 1, hooks: IHooks(address(0))});
        IV4Router.ExactInputSingleParams memory params = IV4Router.ExactInputSingleParams({
            poolKey: poolKey,
            zeroForOne: true,
            amountIn: amountIn,
            amountOutMinimum: amountOutMinimum,
            hookData: bytes("")
        });
        bytes memory payload = abi.encode(params).dirtyBytes(0);
        bytes12 extraData = TestingUtils.generateExtraData(currency0, currency1);

        // Should pass when value == amountIn
        (bool ok, bytes32 reason) = verifier.check(address(0), amountIn, payload, 0, 0, payload.length, extraData);
        assertValidCheck(ok, reason);

        // Should fail when value != amountIn
        (ok, reason) = verifier.check(address(0), amountIn + 1, payload, 0, 0, payload.length, extraData);
        assertInvalidCheck(ok, reason, Lib.INVALID_VALUE);
    }
}
