// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IModifier {
    function avatar() external view returns (address);

    function target() external view returns (address);
}
