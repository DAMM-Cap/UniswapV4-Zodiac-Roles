// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {UniswapV4MintStructVerifier} from "@src/UniswapV4MintStructVerifier.sol";
import {Test} from "@forge-std/Test.sol";
import {IModifier} from "@src/interfaces/IModifier.sol";
import {console2} from "@forge-std/console2.sol";
import "@src/Lib.sol";
import "./TestingUtils.sol";

import "@univ4-core/src/types/PoolKey.sol";
import "@univ4-core/src/types/Currency.sol"; // value-type alias --> unwrap gives address

/* ─────────────────────────── mock ERC-721 ────────────────────── */

contract MockERC721 {
    address public owner;

    constructor(address _owner) {
        owner = _owner;
    }

    function ownerOf(uint256) external view returns (address) {
        return owner;
    }
}

contract TestUniswapV4MintStructVerifier is Test, IModifier {
    using TestingUtils for bytes;

    /* ─────────── stubs to satisfy IModifier ─────────── */
    function avatar() public view returns (address) {
        return address(this);
    }

    function target() public view returns (address) {
        return address(this);
    }

    /* ─────────── struct used by PoolManager.mint() ─────────── */
    struct PositionConfig {
        PoolKey poolKey;
        int24 tickLower;
        int24 tickUpper;
    }

    function test_mint_struct_verifier(
        PositionConfig calldata _config,
        uint256 _liquidity,
        uint128 _amount0Max,
        uint128 _amount1Max,
        address _erc721Owner,
        bytes calldata _hookData,
        uint256 _dirt
    ) public {
        /* ------------------------------------------------------------ *
         *  build Mint params exactly as the hook/condition expects     *
         * ------------------------------------------------------------ */
        bytes memory params = abi.encode(
            _config.poolKey,
            _config.tickLower,
            _config.tickUpper,
            _liquidity,
            _amount0Max,
            _amount1Max,
            avatar(),
            _hookData
        ) // owner
            .dirtyBytes(_dirt);

        bytes6 t0 = Lib.tokenHeader(_config.poolKey.currency0);
        bytes6 t1 = Lib.tokenHeader(_config.poolKey.currency1);

        // pack the two 48-bit slices into a single 96-bit value
        uint96 packed = (uint96(uint48(bytes6(t0))) << 48) | uint96(uint48(bytes6(t1)));
        bytes12 extraData = bytes12(packed);

        /* ------------------------------------------------------------ *
         *  run the check                                               *
         * ------------------------------------------------------------ */
        MockERC721 mockERC721 = new MockERC721(_erc721Owner);
        UniswapV4MintStructVerifier verifier = new UniswapV4MintStructVerifier();

        (bool ok, bytes32 reason) = verifier.check(address(mockERC721), 1, params, 0, 0, params.length, extraData);

        assertTrue(ok);
        assertEq(reason, bytes32(0));
    }

    function test_mint_struct_verifier_invalid_currency0(
        PositionConfig calldata _config,
        Currency _invalidCurrency,
        uint256 _dirt
    ) public {
        /* ------------------------------------------------------------ *
         *  build Mint params exactly as the hook/condition expects     *
         * ------------------------------------------------------------ */
        bytes memory params = abi.encode(_config.poolKey, 0, 0, 0, 0, 0, avatar(), "test") // owner
            .dirtyBytes(_dirt);

        bytes6 t0 = Lib.tokenHeader(_invalidCurrency);
        bytes6 t1 = Lib.tokenHeader(_config.poolKey.currency1);

        vm.assume(t0 != Lib.tokenHeader(_config.poolKey.currency0));

        // pack the two 48-bit slices into a single 96-bit value
        uint96 packed = (uint96(uint48(bytes6(t0))) << 48) | uint96(uint48(bytes6(t1)));
        bytes12 extraData = bytes12(packed);

        MockERC721 mockERC721 = new MockERC721(address(this));
        UniswapV4MintStructVerifier verifier = new UniswapV4MintStructVerifier();

        (bool ok, bytes32 reason) = verifier.check(address(mockERC721), 1, params, 0, 0, params.length, extraData);

        assertFalse(ok);
        assertEq(reason, Lib.INVALID_CURRENCY0);
    }

    function test_mint_struct_verifier_invalid_currency1(
        PositionConfig calldata _config,
        Currency _invalidCurrency,
        uint256 _dirt
    ) public {
        /* ------------------------------------------------------------ *
         *  build Mint params exactly as the hook/condition expects     *
         * ------------------------------------------------------------ */
        bytes memory params = abi.encode(_config.poolKey, 0, 0, 0, 0, 0, avatar(), "test") // owner
            .dirtyBytes(_dirt);

        bytes6 t0 = Lib.tokenHeader(_config.poolKey.currency0);
        bytes6 t1 = Lib.tokenHeader(_invalidCurrency);

        vm.assume(t1 != Lib.tokenHeader(_config.poolKey.currency1));

        // pack the two 48-bit slices into a single 96-bit value
        uint96 packed = (uint96(uint48(bytes6(t0))) << 48) | uint96(uint48(bytes6(t1)));
        bytes12 extraData = bytes12(packed);

        MockERC721 mockERC721 = new MockERC721(address(this));
        UniswapV4MintStructVerifier verifier = new UniswapV4MintStructVerifier();

        (bool ok, bytes32 reason) = verifier.check(address(mockERC721), 1, params, 0, 0, params.length, extraData);

        assertFalse(ok);
        assertEq(reason, Lib.INVALID_CURRENCY1);
    }

    function test_mint_struct_verifier_invalid_owner(
        PositionConfig calldata _config,
        address _invalidOwner,
        uint256 _dirt
    ) public {
        vm.assume(_invalidOwner != avatar());
        /* ------------------------------------------------------------ *
         *  build Mint params exactly as the hook/condition expects     *
         * ------------------------------------------------------------ */
        bytes memory params = abi.encode(_config.poolKey, 0, 0, 0, 0, 0, _invalidOwner, "test").dirtyBytes(_dirt);

        MockERC721 mockERC721 = new MockERC721(address(this));
        UniswapV4MintStructVerifier verifier = new UniswapV4MintStructVerifier();

        bytes6 t0 = Lib.tokenHeader(_config.poolKey.currency0);
        bytes6 t1 = Lib.tokenHeader(_config.poolKey.currency1);

        // pack the two 48-bit slices into a single 96-bit value
        uint96 packed = (uint96(uint48(bytes6(t0))) << 48) | uint96(uint48(bytes6(t1)));
        bytes12 extraData = bytes12(packed);

        (bool ok, bytes32 reason) = verifier.check(address(mockERC721), 1, params, 0, 0, params.length, extraData);

        assertFalse(ok);
        assertEq(reason, Lib.INVALID_OWNER);
    }
}
