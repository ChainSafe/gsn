// SPDX-License-Identifier:MIT
pragma solidity ^0.6.2;
pragma experimental ABIEncoderV2;

import '../BaseRelayRecipient.sol';


contract Fuzz_BaseRelayRecipient is BaseRelayRecipient {
    address public someone = 0xCAfEcAfeCAfECaFeCaFecaFecaFECafECafeCaFe;
    address public deployer;
    bool public msgSenderIsNotModified = true;
    bool public msgDataIsNotModified = true;

    constructor() public {
        trustedForwarder = someone;
        deployer = msg.sender;
    }

    function help_echidna_call_something(address, address) public {
        msgSenderIsNotModified = msg.sender == _msgSender();
        msgDataIsNotModified = keccak256(msg.data) == keccak256(_msgData());
    }

    fallback () external {
        help_echidna_call_something(someone, someone);
    }

    function echidna_msgSender_not_modified() public view returns (bool) {
        return msgSenderIsNotModified;
    }

    function echidna_msgData_not_modified() public view returns (bool) {
        return msgDataIsNotModified;
    }

    function echidna_trustedForwarder_not_modified() public view returns (bool) {
        return trustedForwarder == someone;
    }

    function versionRecipient() external override view returns (string memory) {}

    // function sanity_fail_all_invariants() public {
    //     trustedForwarder = deployer;
    // }
}