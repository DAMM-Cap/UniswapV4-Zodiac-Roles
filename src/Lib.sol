// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@univ4-core/src/types/PoolKey.sol";

/// @author DAMM Capital - https://dammcap.finance
library Lib {
    /// 0x534d0a748652e5f56e4f1a8c9a5a4b8f77782b58576f9f6f572df5cdc7c297c3
    bytes32 constant INVALID_CURRENCY0 = keccak256("INVALID_CURRENCY0");
    /// 0x39b746d7aa77a02cd857c0a94433deb0eab651e88bd0a7998b3655ab1319fc21
    bytes32 constant INVALID_CURRENCY1 = keccak256("INVALID_CURRENCY1");
    /// 0x65cddd280d831926c5d6063232e731cc33cf84fb6230760a9c0735be6381b1a0
    bytes32 constant INVALID_CURRENCY = keccak256("INVALID_CURRENCY");
    /// 0xa30e2b4f22d955e30086ae3aef0adfd87eec9d0d3f055d6aa9af61f522dda886
    bytes32 constant INVALID_OWNER = keccak256("INVALID_OWNER");
    /// 0x5e7bf34c5f9e77c6f415365fc02ea1195419ccebda18d14265f0c098f3687483
    bytes32 constant INVALID_RECIPIENT = keccak256("INVALID_RECIPIENT");
    /// 0x806fc2f0c528614f6371ca4d5621d8076cd90c51a2211198fdc62e3aba768436
    bytes32 constant INVALID_TOKEN_ID = keccak256("INVALID_TOKEN_ID");
    /// 0xf38185948b9759248e56ec02128912506b4a23870d442e59ae3f857bcd81896c
    bytes32 constant INVALID_VALUE = keccak256("INVALID_VALUE");

    uint256 constant ARRAY_LENGTH_OFFSET = 0x20;

    function tokenHeader(Currency currency) internal pure returns (bytes6) {
        return bytes6(bytes20(Currency.unwrap(currency)));
    }

    /// @dev `extraData` == abi.encodePacked(token0.header(6), token1.header(6))
    function checkCurrency(Currency currency, bytes12 extraData, bool isToken0) internal pure returns (bool ok) {
        bytes6 currencyHeader = tokenHeader(currency);
        bytes6 comp = isToken0 ? bytes6(extraData) : bytes6(extraData << 48);
        assembly ("memory-safe") {
            ok := eq(currencyHeader, comp)
        }
    }

    function checkCurrency0(Currency currency, bytes12 extraData) internal pure returns (bool ok) {
        return checkCurrency(currency, extraData, true);
    }

    function checkCurrency1(Currency currency, bytes12 extraData) internal pure returns (bool ok) {
        return checkCurrency(currency, extraData, false);
    }

    function checkCurrency0Or1(Currency currency, bytes12 extraData) internal pure returns (bool ok) {
        return checkCurrency(currency, extraData, true) || checkCurrency(currency, extraData, false);
    }
}
