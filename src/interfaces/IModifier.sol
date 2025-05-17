// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @dev this is the interface that zodiac expects to be implemented by the modifier contract
/// this would be the Zodiac Roles proxy contract enabled on the gnosis safe
interface IModifier {
    function avatar() external view returns (address);

    function target() external view returns (address);
}
