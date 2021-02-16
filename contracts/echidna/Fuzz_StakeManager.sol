// SPDX-License-Identifier:MIT
pragma solidity ^0.6.2;
pragma experimental ABIEncoderV2;

import '../StakeManager.sol';

contract FakeStaker {
    StakeManager public stakeManager;
    constructor(address _stakeManager) public {
        stakeManager = StakeManager(_stakeManager);
    }

    function stakeForAddress(address relayManager, uint256 unstakeDelay) external payable {
        stakeManager.stakeForAddress(relayManager, unstakeDelay);
    }

    function unlockStake(address relayManager) external {
        stakeManager.unlockStake(relayManager);
    }

    function authorizeHubByOwner(address relayManager, address relayHub) external {
        stakeManager.authorizeHubByOwner(relayManager, relayHub);
    }

    function unauthorizeHubByOwner(address relayManager, address relayHub) external {
        stakeManager.unauthorizeHubByOwner(relayManager, relayHub);
    }

    receive () external payable {}
}


contract Fuzz_StakeManager is StakeManager {
    address payable public someone = 0xCAfEcAfeCAfECaFeCaFecaFecaFECafECafeCaFe;
    address payable public someoneElse = 0x1111111111111111111111111111111111111111;
    address payable public someoneElse2 = 0x1111111111111111111111111111111111111112;
    address payable public deployer;
    FakeStaker public staker;
    address payable public stakerManager = 0x1111111111111111111111111111111111111113;
    uint256 public constant initialUnstakeDelay = 1000;
    uint256 public constant simulatedDeposit = 0.5 ether;
    bool public deposited = false;

    constructor() public {
        deployer = msg.sender;
        stakes[someone].owner = deployer;
        stakes[someoneElse].owner = someoneElse2;
        stakes[someoneElse].stake = simulatedDeposit;
        staker = new FakeStaker(address(this));
        stakes[stakerManager].owner = payable(staker);
        stakes[stakerManager].unstakeDelay = initialUnstakeDelay;
    }

    function help_echidna_stakeForAddress(address relayManager, uint256 unstakeDelay) external payable {
        staker.stakeForAddress(relayManager, unstakeDelay);
    }

    function help_echidna_unlockStake(address relayManager) external {
        staker.unlockStake(relayManager);
    }

    function help_echidna_authorizeHubByOwner(address relayManager, address relayHub) external {
        staker.authorizeHubByOwner(relayManager, relayHub);
    }

    function help_echidna_unauthorizeHubByOwner(address relayManager, address relayHub) external {
        staker.unauthorizeHubByOwner(relayManager, relayHub);
    }

    function help_echidna_stakeForAddress_rm(uint256 unstakeDelay) external payable {
        staker.stakeForAddress(stakerManager, unstakeDelay);
    }

    function help_echidna_unlockStake_rm() external {
        staker.unlockStake(stakerManager);
    }

    function help_echidna_authorizeHubByOwner_rm(address relayHub) external {
        staker.authorizeHubByOwner(stakerManager, relayHub);
    }

    function help_echidna_unauthorizeHubByOwner_rm(address relayHub) external {
        staker.unauthorizeHubByOwner(stakerManager, relayHub);
    }

    function echidna_manager_and_owner_always_different() public view returns (bool) {
        return (stakes[someone].owner != someone || stakes[someone].owner == address(0))
            && (stakes[deployer].owner != deployer || stakes[deployer].owner == address(0));
    }

    function echidna_stake_sum_always_lower_than_balance() public view returns (bool) {
        return stakes[someone].stake + stakes[deployer].stake + stakes[address(this)].stake <= address(this).balance;
    }

    function echidna_stake_cannot_decrease_without_hub_or_owner() public view returns (bool) {
        return stakes[someoneElse].stake == simulatedDeposit;
    }

    function echidna_owner_immutable_without_withdraw() public view returns (bool) {
        return stakes[stakerManager].owner == address(staker);
    }

    function echidna_unstakeDelay_cannot_decrease_without_withdraw() public view returns (bool) {
        return stakes[stakerManager].unstakeDelay >= initialUnstakeDelay;
    }

    // function sanity_fail_all_invariants() public {
    //     stakes[someone].owner = someone;
    //     stakes[someone].stake = 100 ether;
    //     stakes[someoneElse].stake = 1;
    //     stakes[stakerManager].owner = someoneElse;
    //     stakes[stakerManager].unstakeDelay = 1;
    // }
}