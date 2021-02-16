// SPDX-License-Identifier:MIT
pragma solidity ^0.6.2;
pragma experimental ABIEncoderV2;

import '../BasePaymaster.sol';
import '../forwarder/Forwarder.sol';

contract Stub {
    bool public calledByOwner;
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    function withdraw(uint, address payable) external {
        if (owner == msg.sender) {
            calledByOwner = true;
        }
    }
}


contract Fuzz_BasePaymaster is BasePaymaster {
    address public someone = 0xCAfEcAfeCAfECaFeCaFecaFecaFECafECafeCaFe;
    address public initialRelayHub;
    address public initialForwarder;

    constructor() public {
        transferOwnership(address(this));
        initialForwarder = address(new Forwarder());
        initialRelayHub = address(new Stub());
        relayHub = IRelayHub(initialRelayHub);
        trustedForwarder = IForwarder(initialForwarder);
    }

    function echidna_setHub_onlyOwner() public view returns (bool) {
        return address(relayHub) == initialRelayHub;
    }

    function echidna_setTrustedForwarder_onlyOwner() public view returns (bool) {
        return address(trustedForwarder) == initialForwarder;
    }

    function echidna_withdrawRelayHubDepositTo_onlyOwner() public view returns (bool) {
        return !Stub(initialRelayHub).calledByOwner();
    }

    function preRelayedCall(
        GsnTypes.RelayRequest calldata relayRequest,
        bytes calldata signature,
        bytes calldata approvalData,
        uint256 maxPossibleGas
    )
    external override
    returns (bytes memory context, bool rejectOnRecipientRevert) {}

    function postRelayedCall(
        bytes calldata context,
        bool success,
        uint256 gasUseWithoutPost,
        GsnTypes.RelayData calldata relayData
    ) external override {}

    function versionPaymaster() external override view returns (string memory) {}

    // function sanity_fail_all_invariants() public {
    //     this.transferOwnership(msg.sender);
    // }
}