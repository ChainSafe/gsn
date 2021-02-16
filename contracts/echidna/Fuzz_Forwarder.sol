// SPDX-License-Identifier:MIT
pragma solidity ^0.6.2;
pragma experimental ABIEncoderV2;

import '../forwarder/Forwarder.sol';


contract Fuzz_Forwarder is Forwarder {
    string public basicRequestType; 
    bytes32 public basicRequestTypeHash;
    string public constant domainSeparatorName = "SomeName";
    string public constant domainSeparatorVersion = "SomeVersion";
    bytes32 public domainHash;
    uint public startingNonce = 10;
    address public deployer;
    address public someone = 0xCAfEcAfeCAfECaFeCaFecaFecaFECafECafeCaFe;
    string public constant failDomainSeparatorName = "FailName";
    string public constant failDomainSeparatorVersion = "FailVersion";
    bytes32 public failHash;

    constructor() public {
        basicRequestType = string(abi.encodePacked("ForwardRequest(", GENERIC_PARAMS, ")"));
        basicRequestTypeHash = keccak256(bytes(basicRequestType));

        domainHash = help_echidna_getDomainHash(domainSeparatorName, domainSeparatorVersion);
        domains[domainHash] = true;
        deployer = msg.sender;
        nonces[deployer] = startingNonce;
        failHash = help_echidna_getDomainHash(failDomainSeparatorName, failDomainSeparatorVersion);
    }

    function help_echidna_getDomainHash(string memory name, string memory version) public view returns(bytes32) {
        uint256 chainId;
         // solhint-disable-next-line no-inline-assembly 
        assembly { chainId := chainid() }

        bytes memory domainValue = abi.encode(
            keccak256(bytes(EIP712_DOMAIN_TYPE)),
            keccak256(bytes(name)),
            keccak256(bytes(version)),
            chainId,
            address(this));

        return keccak256(domainValue);
    }

    function echidna_typeHashes_aways_stays_true() public view returns (bool) {
        return typeHashes[basicRequestTypeHash];
    }

    // To prove that echidna could break invariants.
    function echidna_must_fail_eventually_or_with_seed_2054450532857045780() public view returns (bool) {
        return !domains[failHash];
    }

    function echidna_domains_always_stays_true() public view returns (bool) {
        return domains[domainHash];
    }

    function echidna_nonce_cannot_decrease() public view returns (bool) {
        return nonces[deployer] >= startingNonce;
    }

    function echidna_nonce_only_changeable_with_sig() public view returns (bool) {
        return nonces[someone] == 0;
    }

    // function sanity_fail_all_invariants() public {
    //     typeHashes[basicRequestTypeHash] = false;
    //     domains[domainHash] = false;
    //     nonces[deployer] = 0;
    //     nonces[someone] = 1;
    //     this.registerDomainSeparator(failDomainSeparatorName, failDomainSeparatorVersion);
    // }
}