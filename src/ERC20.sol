// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.18;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract ERC20Token is ERC20, ERC20Permit {
    constructor() ERC20("Prakrit", "pra") ERC20Permit("Prakrit") {}

    function mint(address to, uint256 value) external {
        _mint(to, value);
    }
}
