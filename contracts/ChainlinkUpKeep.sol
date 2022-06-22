// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/KeeperCompatible.sol";

interface IResolver {
    function debtTrigger(address strategy) external view returns (bool _canExec, bytes memory _execPayload);
    function collatTrigger(address strategy) external view returns (bool _canExec, bytes memory _execPayload); 
}

interface IKeeperProxy {
    // Strategy Wrappers
    function rebalanceDebt() external;
    function rebalanceCollateral() external;

    // Proxy Keeper Functions
    function collatTriggerHysteria() external view returns (bool _canExec);
    function debtTriggerHysteria() external view returns (bool _canExec);
}


contract ChainlinkUpkeep is KeeperCompatibleInterface {
    address public keeperProxy;

    constructor  (address _keeperProxy) public {
        keeperProxy = _keeperProxy;
    }

    function checkUpkeep(bytes calldata /* checkData */) external view override returns (bool _upkeepNeeded, bytes memory _execPayload) {
        /// first we check debt trigger, if debt rebalance doesn't need to be checked then we check collat trigger
        _upkeepNeeded = IKeeperProxy(keeperProxy).debtTriggerHysteria();
        if (_upkeepNeeded) {
            _execPayload = abi.encodeWithSelector(IKeeperProxy(keeperProxy).rebalanceDebt.selector);
        } else {
            _upkeepNeeded = IKeeperProxy(keeperProxy).collatTriggerHysteria();
            if (_upkeepNeeded) {
                _execPayload = abi.encodeWithSelector(IKeeperProxy(keeperProxy).rebalanceCollateral.selector);
            }
        }
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        if (IKeeperProxy(keeperProxy).debtTriggerHysteria()) {
            IKeeperProxy(keeperProxy).rebalanceDebt();
        } else if (IKeeperProxy(keeperProxy).collatTriggerHysteria()) {
            IKeeperProxy(keeperProxy).rebalanceCollateral();
        }
    }
}