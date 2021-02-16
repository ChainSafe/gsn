// SPDX-License-Identifier:MIT
pragma solidity ^0.6.2;
pragma experimental ABIEncoderV2;

import '../RelayHub.sol';
import '../forwarder/Forwarder.sol';
import '../BasePaymaster.sol';

contract FakeStakeManager {
    address public owner;
    bool public penalized = false;

    constructor() public {
        owner = msg.sender;
    }

    function isRelayManagerStaked(address, address, uint, uint) public pure returns (bool) {
        return true;
    }

    function penalizeRelayManager(address, address payable, uint256) external {
        if (owner == msg.sender) {
            penalized = true;
        }
    }

    function getStakeInfo(address) external pure returns (IStakeManager.StakeInfo memory) {}
}

contract FakePaymaster is BasePaymaster {
    bool public shouldPassPre = true;
    bool public shouldPassPost = true;

    constructor(address _relayHub, address _forwarder) public {
        relayHub = IRelayHub(_relayHub);
        trustedForwarder = IForwarder(_forwarder);
    }

    function passPre() public {
        shouldPassPre = true;
    }

    function failPre() public {
        shouldPassPre = false;
    }

    function passPost() public {
        shouldPassPost = true;
    }

    function failPost() public {
        shouldPassPost = false;
    }

    function preRelayedCall(
        GsnTypes.RelayRequest calldata,
        bytes calldata,
        bytes calldata,
        uint256
    )
    external override
    returns (bytes memory, bool) {
        require(shouldPassPre, 'Some error');
    }

    function postRelayedCall(
        bytes calldata,
        bool,
        uint256,
        GsnTypes.RelayData calldata
    ) external override {
        require(shouldPassPost, 'Some error');
    }

    function versionPaymaster() external override view returns (string memory) {}
}


contract Fuzz_RelayHub is RelayHub {
    address public someone = 0xCAfEcAfeCAfECaFeCaFecaFecaFECafECafeCaFe;
    address public deployer;
    address payable public paymaster;
    address public initialForwarder;
    address public initialStakeManager;
    address public initialPenalizer;
    uint256 public constant initialMaxWorkerCount = 10;
    uint256 public constant initialGasReserve = 100000;
    uint256 public constant initialPostOverhead = 50000;
    uint256 public constant initialGasOverhead = 150000;
    uint256 public constant initialMaximumRecipientDeposit = 1 ether;
    uint256 public constant initialMinimumUnstakeDelay = 12 hours;
    uint256 public constant initialMinimumStake = 0.1 ether;
    uint256 public constant simulatedDeposit = 0.5 ether;
    bool public deposited = false;

    constructor() public
    RelayHub(
        IStakeManager(address(new FakeStakeManager())),
        someone,
        initialMaxWorkerCount,
        initialGasReserve,
        initialPostOverhead,
        initialGasOverhead,
        initialMaximumRecipientDeposit,
        initialMinimumUnstakeDelay,
        initialMinimumStake
    ) {
        initialForwarder = address(new Forwarder());
        initialStakeManager = address(stakeManager);
        initialPenalizer = penalizer;
        deployer = msg.sender;
        workerToManager[someone] = deployer;
        workerCount[deployer] = 1;
        workerToManager[deployer] = someone;
        workerToManager[address(this)] = someone;
        workerCount[someone] = 2;
        paymaster = payable(new FakePaymaster(address(this), initialForwarder));
        // balances[paymaster] = simulatedDeposit;
    }

    function help_echidna_fail_pre() public {
        FakePaymaster(paymaster).failPre();
    }

    function help_echidna_pass_pre() public {
        FakePaymaster(paymaster).passPre();
    }

    function help_echidna_fail_post() public {
        FakePaymaster(paymaster).failPost();
    }

    function help_echidna_pass_post() public {
        FakePaymaster(paymaster).passPost();
    }

    function help_echidna_depositFor() public payable {
        require(msg.value >= simulatedDeposit);
        deposited = true;
        depositFor(paymaster);
    }

    function help_echidna_construct_RelayRequest() public view returns(GsnTypes.RelayRequest memory result) {
        result.relayData.relayWorker = deployer;
        result.relayData.paymaster = paymaster;
        result.relayData.forwarder = initialForwarder;
        result.relayData.gasPrice = tx.gasprice;
        result.relayData.baseRelayFee = 0.1 ether;
        result.request.data = hex'cafecafe';
        bytes memory litter;
        assembly {
            mstore(litter, 50000)
        }
        result.relayData.paymasterData = litter; // 50Kb of useless data to consume gas.

        return result;
    }

    // function help_echidna_steal_from_paymaster() public {
    //     uint gas = gasleft();
    //     GsnTypes.RelayRequest memory req = help_echidna_construct_RelayRequest();
    //     req.relayData.relayWorker = address(this);
    //     this.relayCall(10000000, req, '', '', gas);
    // }

    function echidna_minimumStake_immutable() public view returns (bool) {
        return minimumStake == initialMinimumStake;
    }

    function echidna_minimumUnstakeDelay_immutable() public view returns (bool) {
        return minimumUnstakeDelay == initialMinimumUnstakeDelay;
    }

    function echidna_maximumRecipientDeposit_immutable() public view returns (bool) {
        return maximumRecipientDeposit == initialMaximumRecipientDeposit;
    }

    function echidna_gasOverhead_immutable() public view returns (bool) {
        return gasOverhead == initialGasOverhead;
    }

    function echidna_postOverhead_immutable() public view returns (bool) {
        return postOverhead == initialPostOverhead;
    }

    function echidna_gasReserve_immutable() public view returns (bool) {
        return gasReserve == initialGasReserve;
    }

    function echidna_maxWorkerCount_immutable() public view returns (bool) {
        return maxWorkerCount == initialMaxWorkerCount;
    }

    function echidna_stakeManager_immutable() public view returns (bool) {
        return address(stakeManager) == initialStakeManager;
    }

    function echidna_penalizer_immutable() public view returns (bool) {
        return penalizer == initialPenalizer;
    }

    function echidna_workerToManager_cannot_be_unset() public view returns (bool) {
        return workerToManager[someone] == deployer;
    }

    function echidna_workerCount_cannot_be_higher_than_limit() public view returns (bool) {
        return workerCount[deployer] <= initialMaxWorkerCount;
    }

    function echidna_penalize_penalizerOnly() public view returns (bool) {
        return !FakeStakeManager(initialStakeManager).penalized();
    }

    // Echidna will be able to break this after: https://github.com/crytic/echidna/pull/596
    function echidna_balance_cannot_be_decreased_illegitimately() public view returns (bool) {
        return this.balanceOf(paymaster) >= simulatedDeposit || !deposited;
    }

    // function sanity_fail_all_invariants() public {
    //     minimumStake = minimumStake / 2;
    //     minimumUnstakeDelay = minimumUnstakeDelay / 2;
    //     maximumRecipientDeposit = maximumRecipientDeposit / 2;
    //     gasOverhead = gasOverhead / 2;
    //     postOverhead = postOverhead / 2;
    //     gasReserve = gasReserve / 2;
    //     maxWorkerCount = maxWorkerCount * 2;
    //     stakeManager = IStakeManager(address(new FakeStakeManager()));
    //     penalizer = deployer;
    //     workerToManager[someone] = someone;
    // }

    // function sanity_fail_all_invariants_step2() public {
    //     stakeManager = IStakeManager(initialStakeManager);
    // }
}