// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {AdvancedLending} from "../src/AdvancedLending.sol";
import {MyToken} from "../src/MyToken.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";

contract DeployAdvancedLending is Script {
    uint8 public constant DECIMALS = 8;
    int256 public constant MTK_ETH_PEICE = 2;

    function run() external returns (MyToken, MockV3Aggregator, AdvancedLending) {
        vm.startBroadcast();
        MockV3Aggregator mtkEthPriceFeed = new MockV3Aggregator(DECIMALS, MTK_ETH_PEICE);
        MyToken myToken = new MyToken();
        AdvancedLending advancedLending = new AdvancedLending(address(myToken), address(mtkEthPriceFeed));
        vm.stopBroadcast();

        return (myToken, mtkEthPriceFeed, advancedLending);
    }
}
