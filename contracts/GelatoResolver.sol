// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

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

interface IVault {
    function strategies(address _strategy) external view returns(uint256 performanceFee, uint256 activation, uint256 debtRatio, uint256 minDebtPerHarvest, uint256 maxDebtPerHarvest, uint256 lastReport, uint256 totalDebt, uint256 totalGain, uint256 totalLoss);
}

contract GelatoResolver is Initializable {
    using SafeMath for uint256;

    address public owner;
    
    function initialize() public initializer {}

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        owner = newOwner;
    }

    function debtTrigger(address keeperProxy) public view returns (bool _canExec, bytes memory _execPayload) {
        _execPayload = abi.encodeWithSelector(IKeeperProxy(keeperProxy).rebalanceDebt.selector);
        _canExec = IKeeperProxy(keeperProxy).collatTriggerHysteria();
    }
    
    function collatTrigger(address keeperProxy) public view returns (bool _canExec, bytes memory _execPayload) {
        _execPayload = abi.encodeWithSelector(IKeeperProxy(keeperProxy).rebalanceCollateral.selector);
        _canExec = IKeeperProxy(keeperProxy).collatTriggerHysteria();
    }
}