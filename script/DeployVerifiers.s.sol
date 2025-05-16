// SPDX-License-Identifier: UNLICENSED
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

contract DeployVerifiers is Script {
    function run() external {
        // Load the private key from environment
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PK");

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Deploy all the verifier contracts
        UniswapV4MintStructVerifier mintVerifier = new UniswapV4MintStructVerifier();
        console.log("UniswapV4MintStructVerifier deployed at:", address(mintVerifier));

        UniswapV4TakeAllStructVerifier takeAllVerifier = new UniswapV4TakeAllStructVerifier();
        console.log("UniswapV4TakeAllStructVerifier deployed at:", address(takeAllVerifier));

        UniswapV4SettleAllStructVerifier settleAllVerifier = new UniswapV4SettleAllStructVerifier();
        console.log("UniswapV4SettleAllStructVerifier deployed at:", address(settleAllVerifier));

        UniswapV4SwapExactInSingleStructVerifier swapExactInSingleVerifier =
            new UniswapV4SwapExactInSingleStructVerifier();
        console.log("UniswapV4SwapExactInSingleStructVerifier deployed at:", address(swapExactInSingleVerifier));

        UniswapV4SweepStructVerifier sweepVerifier = new UniswapV4SweepStructVerifier();
        console.log("UniswapV4SweepStructVerifier deployed at:", address(sweepVerifier));

        UniswapV4TakePairStructVerifier takePairVerifier = new UniswapV4TakePairStructVerifier();
        console.log("UniswapV4TakePairStructVerifier deployed at:", address(takePairVerifier));

        UniswapV4DecreaseLiquidityStructVerifier decreaseLiquidityVerifier =
            new UniswapV4DecreaseLiquidityStructVerifier();
        console.log("UniswapV4DecreaseLiquidityStructVerifier deployed at:", address(decreaseLiquidityVerifier));

        UniswapV4SettlePairStructVerifier settlePairVerifier = new UniswapV4SettlePairStructVerifier();
        console.log("UniswapV4SettlePairStructVerifier deployed at:", address(settlePairVerifier));

        vm.stopBroadcast();
    }
}
