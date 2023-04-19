// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

contract Auth {

    event MultisigSet(address oldValue, address newValue);

    event DeployerRenounced(address oldValue);

    address public deployer;

    address public multisig;

    constructor(address _multisig) {
        multisig = _multisig;
        deployer = msg.sender;
    }

    function setMultisig(address _multisig) external {
        require(msg.sender == multisig);
        emit MultisigSet(multisig, _multisig);
        multisig = _multisig;
    }

    function renounceDeployer() external {
        require(msg.sender == deployer);
        emit DeployerRenounced(deployer);
        deployer = address(0);
    }
}
