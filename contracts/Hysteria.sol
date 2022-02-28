// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

interface IStrat {
    function calcDebtRatio() external view returns (uint256);
    function debtLower() external view returns (uint256);
    function debtUpper() external view returns (uint256);
    function calcCollateral() external view returns (uint256);
    function collatLower() external view returns (uint256);
    function collatUpper() external view returns (uint256);
    function vault() external view returns (address);
    function rebalanceDebt() external;
    function rebalanceCollateral() external;
}

interface IVault {
    function strategies(address _strategy) external view returns(uint256 performanceFee, uint256 activation, uint256 debtRatio, uint256 minDebtPerHarvest, uint256 maxDebtPerHarvest, uint256 lastReport, uint256 totalDebt, uint256 totalGain, uint256 totalLoss);
}

contract Hysteria is Initializable {
    using SafeMath for uint256;

    address public owner;
    uint256 public hysteriaDebt;
    uint256 public hysteriaCollateral;
    
    function initialize(
        uint256 _hysteriaDebt,
        uint256 _hysteriaCollateral
    ) public initializer {
        hysteriaDebt = _hysteriaDebt;
        hysteriaCollateral = _hysteriaCollateral;
    }

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

    function isInactive(address strategy) public view returns (bool) {
        address vault = IStrat(strategy).vault();
        ( , , uint256 debtRatio, , , , , ,) = IVault(vault).strategies(strategy);
        return (debtRatio == 0);
    }

    function updateHysteria(uint256 _hysteriaDebt,uint256 _hysteriaCollateral) external onlyOwner {
        hysteriaDebt = _hysteriaDebt;
        hysteriaCollateral = _hysteriaCollateral;        
    }

    function debtTrigger(address strategy) public view returns (bool _canExec, bytes memory _execPayload) {
        _execPayload = abi.encodeWithSelector(IStrat(strategy).rebalanceDebt.selector);
        if (!isInactive(strategy)) {
            uint256 debtRatio = IStrat(strategy).calcDebtRatio();
            _canExec = (debtRatio > (IStrat(strategy).debtUpper().add(hysteriaDebt)) || debtRatio < IStrat(strategy).debtLower().sub(hysteriaDebt));           
        }
    }
    
    function collatTrigger(address strategy) public view returns (bool _canExec, bytes memory _execPayload) {
        _execPayload = abi.encodeWithSelector(IStrat(strategy).rebalanceDebt.selector);
        if (!isInactive(strategy)) {
            uint256 collatRatio = IStrat(strategy).calcCollateral();
            _canExec = (collatRatio > IStrat(strategy).collatUpper().add(hysteriaCollateral) || collatRatio < IStrat(strategy).collatLower().sub(hysteriaCollateral));
        }
    }
}