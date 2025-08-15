// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/UniswapV4MintStructVerifier.sol";
import "../src/UniswapV4TakeAllStructVerifier.sol";
import "../src/UniswapV4SettleAllStructVerifier.sol";
import "../src/UniswapV4SwapExactInSingleStructVerifier.sol";
import "../src/UniswapV4SweepStructVerifier.sol";
import "../src/UniswapV4TakePairStructVerifier.sol";
import "../src/UniswapV4DecreaseLiquidityStructVerifier.sol";
import "../src/UniswapV4SettlePairStructVerifier.sol";
import "../src/UniswapV4SwapExactOutSingleStructVerifier.sol";
import "./ISingletonFactory.sol";

contract DeployVerifiers is Script {
    uint24 public constant MAX_FEE = 10_000;
    address public constant SINGLETON_FACTORY = 0xce0042B868300000d44A59004Da54A005ffdcf9f;
    bytes32 public constant SALT = 0x0000000000000000000000000000000000000000000000000000000000000069;

    bool public constant USE_SINGLETON_FACTORY = true;

    function run() external {
        // Load the private key from environment
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PK");

        console.log("Using singleton factory:", USE_SINGLETON_FACTORY);
        console.log("Max fee:", MAX_FEE);
        console.log("Singleton factory:", SINGLETON_FACTORY);
        console.log("Salt:");
        console.logBytes32(SALT);

        if (USE_SINGLETON_FACTORY) {
            if (address(SINGLETON_FACTORY).code.length == 0) {
                revert("Singleton factory not deployed");
            }
        }

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        if (USE_SINGLETON_FACTORY) {
            ISingletonFactory factory = ISingletonFactory(SINGLETON_FACTORY);

            address mintVerifier = factory.deploy(
                abi.encodePacked(type(UniswapV4MintStructVerifier).creationCode, abi.encode(MAX_FEE)), SALT
            );
            console.log("UniswapV4MintStructVerifier deployed at:", mintVerifier);

            address takeAllVerifier =
                factory.deploy(abi.encodePacked(type(UniswapV4TakeAllStructVerifier).creationCode), SALT);
            console.log("UniswapV4TakeAllStructVerifier deployed at:", takeAllVerifier);

            address settleAllVerifier =
                factory.deploy(abi.encodePacked(type(UniswapV4SettleAllStructVerifier).creationCode), SALT);
            console.log("UniswapV4SettleAllStructVerifier deployed at:", settleAllVerifier);

            address swapExactInSingleVerifier = factory.deploy(
                abi.encodePacked(type(UniswapV4SwapExactInSingleStructVerifier).creationCode, abi.encode(MAX_FEE)), SALT
            );
            console.log("UniswapV4SwapExactInSingleStructVerifier deployed at:", swapExactInSingleVerifier);

            address swapExactOutSingleVerifier = factory.deploy(
                abi.encodePacked(type(UniswapV4SwapExactOutSingleStructVerifier).creationCode, abi.encode(MAX_FEE)),
                SALT
            );
            console.log("UniswapV4SwapExactOutSingleStructVerifier deployed at:", swapExactOutSingleVerifier);

            address sweepVerifier =
                factory.deploy(abi.encodePacked(type(UniswapV4SweepStructVerifier).creationCode), SALT);
            console.log("UniswapV4SweepStructVerifier deployed at:", sweepVerifier);

            address takePairVerifier =
                factory.deploy(abi.encodePacked(type(UniswapV4TakePairStructVerifier).creationCode), SALT);
            console.log("UniswapV4TakePairStructVerifier deployed at:", address(takePairVerifier));

            address decreaseLiquidityVerifier =
                factory.deploy(abi.encodePacked(type(UniswapV4DecreaseLiquidityStructVerifier).creationCode), SALT);
            console.log("UniswapV4DecreaseLiquidityStructVerifier deployed at:", decreaseLiquidityVerifier);

            address settlePairVerifier =
                factory.deploy(abi.encodePacked(type(UniswapV4SettlePairStructVerifier).creationCode), SALT);
            console.log("UniswapV4SettlePairStructVerifier deployed at:", settlePairVerifier);
        } else {
            // Deploy all the verifier contracts
            UniswapV4MintStructVerifier mintVerifier = new UniswapV4MintStructVerifier{salt: SALT}(MAX_FEE);
            console.log("UniswapV4MintStructVerifier deployed at:", address(mintVerifier));

            UniswapV4TakeAllStructVerifier takeAllVerifier = new UniswapV4TakeAllStructVerifier{salt: SALT}();
            console.log("UniswapV4TakeAllStructVerifier deployed at:", address(takeAllVerifier));

            UniswapV4SettleAllStructVerifier settleAllVerifier = new UniswapV4SettleAllStructVerifier{salt: SALT}();
            console.log("UniswapV4SettleAllStructVerifier deployed at:", address(settleAllVerifier));

            UniswapV4SwapExactInSingleStructVerifier swapExactInSingleVerifier =
                new UniswapV4SwapExactInSingleStructVerifier{salt: SALT}(MAX_FEE);
            console.log("UniswapV4SwapExactInSingleStructVerifier deployed at:", address(swapExactInSingleVerifier));

            UniswapV4SwapExactOutSingleStructVerifier swapExactOutSingleVerifier =
                new UniswapV4SwapExactOutSingleStructVerifier{salt: SALT}(MAX_FEE);
            console.log("UniswapV4SwapExactOutSingleStructVerifier deployed at:", address(swapExactOutSingleVerifier));

            UniswapV4SweepStructVerifier sweepVerifier = new UniswapV4SweepStructVerifier{salt: SALT}();
            console.log("UniswapV4SweepStructVerifier deployed at:", address(sweepVerifier));

            UniswapV4TakePairStructVerifier takePairVerifier = new UniswapV4TakePairStructVerifier{salt: SALT}();
            console.log("UniswapV4TakePairStructVerifier deployed at:", address(takePairVerifier));

            UniswapV4DecreaseLiquidityStructVerifier decreaseLiquidityVerifier =
                new UniswapV4DecreaseLiquidityStructVerifier{salt: SALT}();
            console.log("UniswapV4DecreaseLiquidityStructVerifier deployed at:", address(decreaseLiquidityVerifier));

            UniswapV4SettlePairStructVerifier settlePairVerifier = new UniswapV4SettlePairStructVerifier{salt: SALT}();
            console.log("UniswapV4SettlePairStructVerifier deployed at:", address(settlePairVerifier));
        }
        vm.stopBroadcast();
    }
}
