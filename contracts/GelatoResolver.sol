// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelinupgradeable/contracts/proxy/utils/Initializable.sol";

interface IKeeperProxy {
    // Strategy Functions
    function calcDebtRatio() external view returns (uint256);
    function calcCollateral() external view returns (uint256);
    function rebalanceDebt() external;
    function rebalanceCollateral() external;

    // Proxy Keeper Functions
    function collatTriggerHysteria() external view returns (bool _canExec);
    function debtTriggerHysteria() external view returns (bool _canExec);
}

contract GelatoResolver is Initializable {
    using SafeMath for uint256;

    function debtTrigger(address keeperProxy) public view returns (bool _canExec, bytes memory _execPayload) {
        _execPayload = abi.encodeWithSelector(IKeeperProxy(keeperProxy).rebalanceDebt.selector);
        _canExec = IKeeperProxy(keeperProxy).debtTriggerHysteria();
    }
    
    function collatTrigger(address keeperProxy) public view returns (bool _canExec, bytes memory _execPayload) {
        _execPayload = abi.encodeWithSelector(IKeeperProxy(keeperProxy).rebalanceCollateral.selector);
        _canExec = IKeeperProxy(keeperProxy).collatTriggerHysteria();
    }
}