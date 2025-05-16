// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {UniswapV4DecreaseLiquidityStructVerifier} from "@src/UniswapV4DecreaseLiquidityStructVerifier.sol";
import {Test} from "@forge-std/Test.sol";
import {IModifier} from "@src/interfaces/IModifier.sol";
import {IERC721} from "@src/UniswapV4DecreaseLiquidityStructVerifier.sol";
import {console2} from "@forge-std/console2.sol";
import {Lib} from "@src/Lib.sol";

/* ─────────────────────────── mock ERC-721 ────────────────────── */
contract MockERC721 {
    mapping(uint256 => address) public owners;

    function setOwner(uint256 tokenId, address owner) external {
        owners[tokenId] = owner;
    }

    function ownerOf(uint256 tokenId) external view returns (address) {
        return owners[tokenId];
    }
}

contract MockModifier is IModifier {
    address public _avatar;
    address public _target;

    constructor(address avatar_, address target_) {
        _avatar = avatar_;
        _target = target_;
    }

    function avatar() external view returns (address) {
        return _avatar;
    }

    function target() external view returns (address) {
        return _target;
    }
}

contract TestUniswapV4DecreaseLiquidityStructVerifier is Test {
    UniswapV4DecreaseLiquidityStructVerifier verifier;
    MockERC721 mockERC721;
    MockModifier mockModifier;
    address avatarAddress;

    function setUp() public {
        avatarAddress = makeAddr("avatar");
        verifier = new UniswapV4DecreaseLiquidityStructVerifier();
        mockERC721 = new MockERC721();
        mockModifier = new MockModifier(avatarAddress, address(this));
    }

    function test_decrease_liquidity_invalid_token_owner(address randomOwner) public {
        vm.assume(randomOwner != avatarAddress);
        vm.assume(randomOwner != address(0));

        // Setup token ownership with random owner (not the avatar)
        uint256 tokenId = 456;
        mockERC721.setOwner(tokenId, randomOwner);

        // Encode the decrease liquidity params
        uint256 liquidity = 2000;
        uint128 amount0Min = 1000;
        uint128 amount1Min = 1200;
        bytes memory hookData = "test";

        bytes memory data = abi.encode(tokenId, liquidity, amount0Min, amount1Min, hookData);

        // Use vm.prank to set msg.sender to the mock modifier
        vm.prank(address(mockModifier));

        // Call the check function
        (bool ok, bytes32 reason) = verifier.check(
            address(mockERC721),
            0,
            data,
            0,
            0,
            data.length,
            bytes12(0) // extraData not used in this verifier
        );

        // Verify the results
        assertFalse(ok);
        assertEq(reason, Lib.INVALID_TOKEN_ID);
    }

    function test_decrease_liquidity_fuzz_token_id(uint256 tokenId, uint256 liquidity) public {
        // Setup token ownership
        mockERC721.setOwner(tokenId, avatarAddress);

        // Encode the decrease liquidity params
        uint128 amount0Min = 500;
        uint128 amount1Min = 600;
        bytes memory hookData = "test";

        bytes memory data = abi.encode(tokenId, liquidity, amount0Min, amount1Min, hookData);

        // Use vm.prank to set msg.sender to the mock modifier
        vm.prank(address(mockModifier));

        // Call the check function
        (bool ok, bytes32 reason) = verifier.check(
            address(mockERC721),
            0,
            data,
            0,
            0,
            data.length,
            bytes12(0) // extraData not used in this verifier
        );

        // Verify the results
        assertTrue(ok);
        assertEq(reason, bytes32(0));
    }
}
