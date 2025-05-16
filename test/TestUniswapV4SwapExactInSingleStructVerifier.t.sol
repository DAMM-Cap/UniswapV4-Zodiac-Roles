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

contract TestUniswapV4SwapExactInSingleStructVerifier is Test {
    UniswapV4SwapExactInSingleStructVerifier verifier;

    function setUp() public {
        verifier = new UniswapV4SwapExactInSingleStructVerifier();
    }

    function test_swap_exact_in_single_valid_currencies(Currency currency0, Currency currency1) public {
        vm.assume(Currency.unwrap(currency0) != Currency.unwrap(currency1));
        vm.assume(Currency.unwrap(currency0) < Currency.unwrap(currency1));

        // Create a pool key with the currencies
        PoolKey memory poolKey =
            PoolKey({currency0: currency0, currency1: currency1, fee: 0, tickSpacing: 0, hooks: IHooks(address(0))});

        IV4Router.ExactInputSingleParams memory mockExactInputParams = IV4Router.ExactInputSingleParams({
            poolKey: poolKey,
            zeroForOne: true,
            amountIn: 1000,
            amountOutMinimum: 500,
            hookData: bytes("")
        });

        // Generate extraData from the same currencies
        bytes6 t0 = Lib.tokenHeader(currency0);
        bytes6 t1 = Lib.tokenHeader(currency1);

        // Pack the two 48-bit slices into a single 96-bit value
        uint96 packed = (uint96(uint48(bytes6(t0))) << 48) | uint96(uint48(bytes6(t1)));
        bytes12 extraData = bytes12(packed);

        // Call the check function
        (bool ok, bytes32 reason) = verifier.check(
            address(0), 0, abi.encode(mockExactInputParams), 0, 0, abi.encode(mockExactInputParams).length, extraData
        );

        // Verify the results
        assertTrue(ok);
        assertEq(reason, bytes32(0));
    }
}
