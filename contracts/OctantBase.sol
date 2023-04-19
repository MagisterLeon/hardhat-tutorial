// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

import "./Auth.sol";
import {CommonErrors} from "./Errors.sol";

abstract contract OctantBase {

    Auth auth;

    constructor(address _auth) {
        auth = Auth(_auth);
    }

    function getMultisig() internal view returns (address) {
        return auth.multisig();
    }

    modifier onlyMultisig() {
        require(msg.sender == auth.multisig(), CommonErrors.UNAUTHORIZED_CALLER);
        _;
    }

    modifier onlyDeployer() {
        require(msg.sender == auth.deployer(), CommonErrors.UNAUTHORIZED_CALLER);
        _;
    }
}
