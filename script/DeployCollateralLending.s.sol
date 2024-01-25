// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {MyToken} from "../src/MyToken.sol";
import {CollateralLending} from "../src/CollateralLending.sol";

contract DeployCollateralLending is Script {
    function run() external returns (MyToken, CollateralLending) {
        vm.startBroadcast();
        MyToken myToken = new MyToken();
        CollateralLending collateralLending = new CollateralLending(address(myToken));
        vm.stopBroadcast();

        return (myToken, collateralLending);
    }
}
