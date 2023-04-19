// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

import "./OctantBase.sol";

import {EpochsErrors} from "./Errors.sol";


contract Epochs is OctantBase {

    struct EpochProps {
        uint256 from;
        uint256 fromTs;
        uint256 to;
        uint256 duration;
        uint256 decisionWindow;
    }

    uint256 public start;

    uint256 public epochPropsIndex;

    mapping(uint256 => EpochProps) public epochProps;

    constructor(
        uint256 _start,
        uint256 _epochDuration,
        uint256 _decisionWindow,
        address _auth)
    OctantBase(_auth) {
        start = _start;
        epochProps[0] = EpochProps({from : 1, fromTs: block.timestamp, to : 0, duration : _epochDuration, decisionWindow : _decisionWindow});
    }

    function getCurrentEpoch() public view returns (uint32) {
        require(isStarted(), EpochsErrors.NOT_STARTED);
        EpochProps memory _currentEpochProps = getCurrentEpochProps();
        if (_currentEpochProps.to != 0) {
            return uint32(_currentEpochProps.to);
        }
        return uint32(((block.timestamp - _currentEpochProps.fromTs) / _currentEpochProps.duration) + _currentEpochProps.from);
    }

    function getEpochDuration() external view returns (uint256) {
        EpochProps memory _currentEpochProps = getCurrentEpochProps();
        return _currentEpochProps.duration;
    }

    function getDecisionWindow() external view returns (uint256) {
        EpochProps memory _currentEpochProps = getCurrentEpochProps();
        return _currentEpochProps.decisionWindow;
    }

    function isDecisionWindowOpen() public view returns (bool) {
        require(isStarted(), EpochsErrors.NOT_STARTED);
        uint32 _currentEpoch = getCurrentEpoch();
        if (_currentEpoch == 1) {
            return false;
        }

        EpochProps memory _currentEpochProps = getCurrentEpochProps();
        uint256 moduloEpoch = uint256(
            (block.timestamp - _currentEpochProps.fromTs) % _currentEpochProps.duration
        );
        return moduloEpoch <= _currentEpochProps.decisionWindow;
    }

    function isStarted() public view returns (bool) {
        return block.timestamp >= start;
    }

    function setEpochProps(uint256 _epochDuration, uint256 _decisionWindow) external onlyMultisig {
        require(_epochDuration >= _decisionWindow, EpochsErrors.DECISION_WINDOW_TOO_BIG);
        EpochProps memory _props = getCurrentEpochProps();

        if (_props.to == 0) {
            uint32 _currentEpoch = getCurrentEpoch();
            uint256 _currentEpochEnd = _calculateCurrentEpochEnd(_currentEpoch, _props);
            epochProps[epochPropsIndex].to = _currentEpoch;
            epochProps[epochPropsIndex + 1] = EpochProps({from : _currentEpoch + 1, fromTs: _currentEpochEnd,
            to : 0, duration : _epochDuration, decisionWindow : _decisionWindow});
            epochPropsIndex = epochPropsIndex + 1;

        } else {
            epochProps[epochPropsIndex].duration = _epochDuration;
            epochProps[epochPropsIndex].decisionWindow = _decisionWindow;
        }
    }

    function getCurrentEpochProps() public view returns (EpochProps memory) {
        if(epochProps[epochPropsIndex].fromTs > block.timestamp) {
            return epochProps[epochPropsIndex - 1];
        }
        return epochProps[epochPropsIndex];
    }

    function getCurrentEpochEnd() external view returns (uint256) {
        uint32 _currentEpoch = getCurrentEpoch();
        EpochProps memory _props = getCurrentEpochProps();
        return _calculateCurrentEpochEnd(_currentEpoch, _props);
    }

    function _calculateCurrentEpochEnd(uint32 _currentEpoch, EpochProps memory _props) private pure returns (uint256) {
        return _props.fromTs + _props.duration * (1 + _currentEpoch - _props.from);
    }
}
