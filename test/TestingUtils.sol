// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

library TestingUtils {
    /// @dev UniswapV4 payloads are composed of bytes[]. In solidity, the first word of a bytes type is a
    /// uint256 that determines its length. Even though the bytes[] elements are abi.encoded structs,
    /// Zodiac still passes them to the verifiers prefixed with their length.
    /// expected: abi.encode(struct) returns bytes type without the length prefix.
    /// reality: zodiac passes abi.encodePacked(length, abi.encode(struct));
    /// @notice this function is used to simulate this type of bytes packing for testing purposes.
    function dirtyBytes(bytes memory clean, uint256 dirt) internal view returns (bytes memory dirty) {
        dirty = abi.encodePacked(dirt, clean);
    }

    function dirtyBytes(bytes memory clean) internal view returns (bytes memory dirty) {
        dirty = abi.encodePacked(uint256(1), clean);
    }
}
