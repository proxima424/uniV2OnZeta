// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from  "../lib/forge-std/src/Script.sol";
import {DeployTask} from "../src/deployTask.sol";

contract DeploymentScript is Script {

    uint256 public immutable 
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        DeployTask task = new DeployTask();       
    }
}

