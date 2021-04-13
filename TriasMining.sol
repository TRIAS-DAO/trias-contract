// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/*
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.3.0/contracts/math/SafeMath.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.3.0/contracts/token/ERC20/IERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/v3.3.0/contracts/proxy/Initializable.sol";
*/

import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";


contract miningTrias is Initializable {
    using SafeMath for uint256;

    event stake_LPToken(address sender, uint256 amount);
    event unStake_LPToken(address sender);
    event claim_Earning(address sender);
    
    struct StakeInfo {
        uint256 amount;
        uint256 stakeTime;
        uint256 earning;
    }
    

    address _trias;
    address _mining;
    address _LPToken;
    
    mapping(address => StakeInfo) public accountsLPInfo;
    
    uint256 totalLPAmount;

    //constructor (address trias, address LPToken, address mining) public  {
    function initialize(address trias, address LPToken, address mining) public initializer {
        require(trias != address(0), "trias address required");
        require(LPToken != address(0), "LPToken address required");
        require(mining != address(0), "mining account address required");

        _trias  = trias;
        _mining = mining;
        _LPToken = LPToken;
    }
    
    function lpMiningNumbersPerSecond(uint256 amount, uint256 totalAmount) internal pure returns (uint256)  {
        uint price;
        
        if (totalAmount.div(amount) > 200)  { // < 0.5%
            price = 1 ether;
            return price.div(10).div(1 hours);
        } else if (totalAmount.div(amount) > 100) {
            price = 2 ether;
            return price.div(10).div(1 hours);
        } else if (totalAmount.div(amount) > 20) {
            price = 4 ether;
            return price.div(10).div(1 hours);
        } else if (totalAmount.div(amount) > 10) {
            price = 2 ether;
            return price.div(10).div(1 hours);
        } else {
            price = 1 ether;
            return price.div(10).div(1 hours);
        }
    }
    
    function getAccountLPEarning(address account) internal view returns (uint256) {
        uint256 ammount;
        uint256 valueInSecond;
        uint256 timeLong;
        ammount = accountsLPInfo[msg.sender].amount;
        valueInSecond = lpMiningNumbersPerSecond(ammount, totalLPAmount);
        timeLong = now.sub(accountsLPInfo[account].stakeTime);
        if (timeLong > 1 days) {
            timeLong = 1 days;
        }
        
        // stake金额 * 占比 * (stake 时长 / 最大stake时长) * 收益率
        uint256 result = valueInSecond.mul(ammount).mul(ammount).mul(timeLong).div(totalLPAmount).div(1 days).div(1 ether);
        return result;
    }
    
    function updateAccountLPEarning(address account) internal {
        uint256 oldEarning = accountsLPInfo[account].earning;
        uint256 newEarning = getAccountLPEarning(account);
        
        accountsLPInfo[account].earning = oldEarning.add(newEarning);
        accountsLPInfo[account].stakeTime = now;
    }
    
    function stakeLPToken(uint256 amount) external {
        require(amount > 0, "Amount should be bigger than 0!");
        
        bool success = IERC20(_LPToken).transferFrom(msg.sender, address(this), amount);
        require(success, "transferFrom failed");
        
        if (accountsLPInfo[msg.sender].stakeTime != 0) {
            updateAccountLPEarning(msg.sender);
        }
    
        accountsLPInfo[msg.sender].stakeTime = now;
        accountsLPInfo[msg.sender].amount = accountsLPInfo[msg.sender].amount.add(amount);
        
        totalLPAmount = totalLPAmount.add(amount);

        emit stake_LPToken(msg.sender, amount);
    }
    
    function unStakeLPToken() external {
        require(accountsLPInfo[msg.sender].amount != 0, "This account has not staked LP Token yet!");
 
 
        updateAccountLPEarning(msg.sender);
            
        uint256 amount = accountsLPInfo[msg.sender].amount;

		accountsLPInfo[msg.sender].stakeTime = 0;
        accountsLPInfo[msg.sender].amount = 0;

        totalLPAmount = totalLPAmount.sub(amount);

        bool success = IERC20(_LPToken).transfer(msg.sender, amount);
        require(success, "transfer failed");

        emit unStake_LPToken(msg.sender);
    }
    
    function claimEarning() external {
        uint256 earning = 0;
        
        if (accountsLPInfo[msg.sender].stakeTime != 0) {
            updateAccountLPEarning(msg.sender);
            earning = accountsLPInfo[msg.sender].earning;
            
            accountsLPInfo[msg.sender].earning = 0;
        } else {
            earning = accountsLPInfo[msg.sender].earning;
            accountsLPInfo[msg.sender].earning = 0;
        }
        
        if (earning > 0) {
            bool success = IERC20(_trias).transferFrom(_mining, msg.sender, earning);
            require(success, "transferFrom failed");

            emit claim_Earning(msg.sender);
        }
    }

	function getEarning() public view returns (uint256) {
		uint256 totalEarning = 0;
	    uint256 lpOldEarning;
	    uint256 lpNewEarning;
	    
	    lpOldEarning = accountsLPInfo[msg.sender].earning;
	    totalEarning = totalEarning.add(lpOldEarning);
	    
	    
	    if (accountsLPInfo[msg.sender].stakeTime != 0) {
	        lpNewEarning = getAccountLPEarning(msg.sender);
	        totalEarning = totalEarning.add(lpNewEarning);
	    }
	    
        return totalEarning;
	}
}
 

