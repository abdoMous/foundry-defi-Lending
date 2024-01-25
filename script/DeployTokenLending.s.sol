// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {MyToken} from "../src/MyToken.sol";
import {TokenLending} from "../src/TokenLending.sol";

contract DeployTokenLending is Script {
    function run() external returns (MyToken, TokenLending) {
        vm.startBroadcast();
        // MyToken myToken = new MyToken();
        TokenLending tokenLending = new TokenLending(address(0x900450e3814d7fc7606C56aD537aB225F88d94e7));
        vm.stopBroadcast();

        return (MyToken(0x900450e3814d7fc7606C56aD537aB225F88d94e7), tokenLending);
    }
}
