// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.4.0/contracts/token/ERC20/ERC20.sol";


contract TriasOnHECO is ERC20 {
    
    address private owner;
    
    constructor (string memory name, string memory symbol, uint256 _initialAmount) public ERC20(name, symbol) {
		_mint(msg.sender, _initialAmount * (1 ether));
		
		owner = msg.sender;
    }
    
    function new_mining(uint256 amount) external {
        require(owner == msg.sender, "Access denied");

        _mint(msg.sender, amount * (1 ether)); 
    }


}

