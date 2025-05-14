// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ICustomCondition {
    function check(
        address to,
        uint256 value,
        bytes calldata data,
        uint8 operation, // 0 = Call, 1 = DelegateCall
        uint256 location,
        uint256 size,
        bytes12 extra
    ) external view returns (bool success, bytes32 reason);
}
