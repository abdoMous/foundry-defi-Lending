// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MyToken is ERC20 {
    uint256 public constant INITIALY_SUPPLY = 1000 ether;

    constructor() ERC20("MyToken", "MTK") {
        _mint(msg.sender, INITIALY_SUPPLY);
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}
