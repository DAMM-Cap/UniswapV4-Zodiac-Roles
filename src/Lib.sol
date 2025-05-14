// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@univ4-core/src/types/PoolKey.sol";

library Lib {
    bytes32 constant INVALID_CURRENCY0 = keccak256("INVALID_CURRENCY0");
    bytes32 constant INVALID_CURRENCY1 = keccak256("INVALID_CURRENCY1");
    bytes32 constant INVALID_CURRENCY = keccak256("INVALID_CURRENCY");
    bytes32 constant INVALID_OWNER = keccak256("INVALID_OWNER");
    bytes32 constant INVALID_RECIPIENT = keccak256("INVALID_RECIPIENT");
    bytes32 constant INVALID_TOKEN_ID = keccak256("INVALID_TOKEN_ID");
    bytes32 constant INVALID_ACTIONS_LENGTH = keccak256("INVALID_ACTIONS_LENGTH");

    function tokenHeader(Currency currency) internal pure returns (bytes6) {
        return bytes6(bytes20(Currency.unwrap(currency)));
    }

    /// @dev `extraData` == abi.encodePacked(token0.header(6), token1.header(6))
    function checkCurrency(Currency currency, bytes12 extraData, bool isToken0) internal pure returns (bool ok) {
        bytes6 tokenHeader = tokenHeader(currency);
        bytes6 comp = isToken0 ? bytes6(extraData) : bytes6(extraData << 48);
        assembly ("memory-safe") {
            ok := eq(tokenHeader, comp)
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
