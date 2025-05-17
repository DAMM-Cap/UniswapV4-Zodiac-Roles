// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Lib} from "@src/Lib.sol";
import {Currency} from "@univ4-core/src/types/Currency.sol";
import {console2} from "@forge-std/console2.sol";
import {Test} from "@forge-std/Test.sol";

contract LibTest is Test {
    function test_check_currency0(Currency currency0, Currency currency1) external pure {
        bytes6 t0 = Lib.tokenHeader(currency0);
        bytes6 t1 = Lib.tokenHeader(currency1);

        // pack the two 48-bit slices into a single 96-bit value
        uint96 packed = (uint96(uint48(bytes6(t0))) << 48) | uint96(uint48(bytes6(t1)));
        bytes12 extraData = bytes12(packed);

        bool ok = Lib.checkCurrency0(currency0, extraData);
        assertEq(ok, true);
    }

    function test_check_currency1(Currency currency0, Currency currency1) external pure {
        bytes6 t0 = Lib.tokenHeader(currency0);
        bytes6 t1 = Lib.tokenHeader(currency1);

        uint96 packed = (uint96(uint48(bytes6(t0))) << 48) | uint96(uint48(bytes6(t1)));
        bytes12 extraData = bytes12(packed);

        bool ok = Lib.checkCurrency1(currency1, extraData);
        assertEq(ok, true);
    }

    function test_check_currency0_or_1(Currency currency0, Currency currency1) external pure {
        bytes6 t0 = Lib.tokenHeader(currency0);
        bytes6 t1 = Lib.tokenHeader(currency1);

        uint96 packed = (uint96(uint48(bytes6(t0))) << 48) | uint96(uint48(bytes6(t1)));
        bytes12 extraData = bytes12(packed);

        bool ok = Lib.checkCurrency0Or1(currency0, extraData);
        assertEq(ok, true);

        ok = Lib.checkCurrency0Or1(currency1, extraData);
        assertEq(ok, true);
    }

    function test_check_currency_invalid(Currency currency0, Currency currency1) external pure {
        vm.assume(Currency.unwrap(currency0) != Currency.unwrap(currency1));

        bytes6 t0 = Lib.tokenHeader(currency0);
        bytes6 t1 = Lib.tokenHeader(currency1);

        vm.assume(t1 != t0);

        /// notice we flipped the order of the tokens
        uint96 packed = (uint96(uint48(bytes6(t1))) << 48) | uint96(uint48(bytes6(t0)));
        bytes12 extraData = bytes12(packed);

        bool ok = Lib.checkCurrency0(currency0, extraData);
        assertEq(ok, false);

        ok = Lib.checkCurrency1(currency1, extraData);
        assertEq(ok, false);
    }
}
