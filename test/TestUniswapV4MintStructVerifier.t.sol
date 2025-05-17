// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {UniswapV4MintStructVerifier} from "@src/UniswapV4MintStructVerifier.sol";
import {Test} from "@forge-std/Test.sol";
import {IModifier} from "@src/interfaces/IModifier.sol";
import {console2} from "@forge-std/console2.sol";
import {Lib} from "@src/Lib.sol";
import {TestingUtils, TestUtils} from "./TestingUtils.sol";

import {PoolKey} from "@univ4-core/src/types/PoolKey.sol";
import {Currency} from "@univ4-core/src/types/Currency.sol"; // value-type alias --> unwrap gives address

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

contract TestUniswapV4MintStructVerifier is TestUtils, IModifier {
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

        // Generate extraData from both currencies
        bytes12 extraData = TestingUtils.generateExtraData(_config.poolKey.currency0, _config.poolKey.currency1);

        /* ------------------------------------------------------------ *
         *  run the check                                               *
         * ------------------------------------------------------------ */
        MockERC721 mockERC721 = new MockERC721(_erc721Owner);
        UniswapV4MintStructVerifier verifier = new UniswapV4MintStructVerifier();

        // In this test we need to pass the mockERC721 address as the first argument
        (bool ok, bytes32 reason) = verifier.check(address(mockERC721), 1, params, 0, 0, params.length, extraData);

        assertValidCheck(ok, reason);
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

        // Ensure the invalid currency is different from the valid one
        assumeInvalidCurrencySingle(_invalidCurrency, _config.poolKey.currency0);

        // Create extraData with the invalid currency
        bytes12 extraData = TestingUtils.generateExtraData(_invalidCurrency, _config.poolKey.currency1);

        // In this test we needed to create a mockERC721 for the check to work properly
        MockERC721 mockERC721 = new MockERC721(address(this));
        UniswapV4MintStructVerifier verifier = new UniswapV4MintStructVerifier();

        (bool ok, bytes32 reason) = verifier.check(address(mockERC721), 1, params, 0, 0, params.length, extraData);

        assertInvalidCheck(ok, reason, Lib.INVALID_CURRENCY0);
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

        // Ensure the invalid currency is different from the valid one
        assumeInvalidCurrencySingle(_invalidCurrency, _config.poolKey.currency1);

        // Create extraData with the invalid currency
        bytes12 extraData = TestingUtils.generateExtraData(_config.poolKey.currency0, _invalidCurrency);

        // In this test we needed to create a mockERC721 for the check to work properly
        MockERC721 mockERC721 = new MockERC721(address(this));
        UniswapV4MintStructVerifier verifier = new UniswapV4MintStructVerifier();

        (bool ok, bytes32 reason) = verifier.check(address(mockERC721), 1, params, 0, 0, params.length, extraData);

        assertInvalidCheck(ok, reason, Lib.INVALID_CURRENCY1);
    }

    function test_mint_struct_verifier_invalid_owner(
        PositionConfig calldata _config,
        address _invalidOwner,
        uint256 _dirt
    ) public {
        // Ensure the invalid owner is different from the avatar
        assumeInvalidRecipient(_invalidOwner, avatar());

        /* ------------------------------------------------------------ *
         *  build Mint params exactly as the hook/condition expects     *
         * ------------------------------------------------------------ */
        bytes memory params = abi.encode(_config.poolKey, 0, 0, 0, 0, 0, _invalidOwner, "test").dirtyBytes(_dirt);

        // Generate extraData from both currencies
        bytes12 extraData = TestingUtils.generateExtraData(_config.poolKey.currency0, _config.poolKey.currency1);

        // In this test we needed to create a mockERC721 for the check to work properly
        MockERC721 mockERC721 = new MockERC721(address(this));
        UniswapV4MintStructVerifier verifier = new UniswapV4MintStructVerifier();

        (bool ok, bytes32 reason) = verifier.check(address(mockERC721), 1, params, 0, 0, params.length, extraData);

        assertInvalidCheck(ok, reason, Lib.INVALID_OWNER);
    }
}
