// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/KeeperCompatible.sol";
import "./interfaces/IKeeperRegistry.sol";
import "./interfaces/IAggregatorInterface.sol";

// 0x49ccd9ca821efeab2b98c60dc60f518e765ede9a
contract UpKeepAutoTopUp is KeeperCompatibleInterface, Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // If an UpKeep funds are less than this upKeepBalanceThreshold, it will be topped up
    uint256 public linkBalanceThreshold;
    address public registry;
    address usdc;
    uint256[] public upKeepWatchlist;

    error UpKeepAutoTopUp_IdxNotFound();

    /**
    * @notice 
    * @param _usdc 
    * @param _registry 
    * @param _aggregator 
    * @param _router 
    */
    constructor(
        address _usdc,
        address _registry,
        address _aggregator,
        address _router
    ) {
        usdc = _usdc;
        registry = _registry;
        aggregator = _aggregator;
        router = _router;
    }

    modifier onlyKeeperRegistry() {
        require(msg.sender == registry, "!authorized");
        _;
    }

    /**
    * @notice Adds the upKeep with idex _upKeepIdx to the balance topup list
    * @param _upKeepIdx the index of the upkeep to watch
    */
    function addToWatchList(
        uint256 _upKeepIdx
    ) external onlyOwner {
        // Check the balance is above the threshold
        require (getUpKeepBalance(_upKeepIdx) >= linkBalanceThreshold, "!Balance");
        upKeepWatchlist.push(_upKeepIdx);
    }
    
    /**
    * @notice Removed _upKeep idx from the topup list
    * @param _upKeepIdx the index of the upkeep to watch
    */
    function removeFromWatchList(
        uint256 _upKeepIdx
    ) external onlyOwner {
        uint256 len = upKeepWatchlist.length;
        uint256 idx = findUpKeep(_upKeepIdx);
        upKeepWatchlist[idx] = upKeepWatchlist[upKeepWatchlist.length - 1];
        upKeepWatchlist.pop();
    }
    
    /**
    * @notice fund contract with USDC
    * @param _amount amount of USDC to send
    */
    function fund(
        uint256 _amount
    ) external {
        // TODO
    }
    
    /**
    * @notice withdraw USDC from this contract
    * @param _amount amount of USDC to withdraw
    */
    function withdraw(
        uint256 _amount
    ) external onlyOwner {
        // TODO
    }
    
    /**
    * @notice Sweep any ERC20 token in the contract. Only the owner 
    * of this contract can call it.
    * @param _token token to sweep
    */
    function sweep(
        address _token
    ) external onlyOwner {
        // TODO
    }

    function findUpKeep(uint256 _upKeepIdx) public view returns (uint256) {
        for (uint i = 0; i < upKeepWatchlist.length; i++) {
            if (upKeepWatchlist[i] == _upKeepIdx) {
                return i;
            }
        }
        revert UpKeepAutoTopUp_IdxNotFound();
    }

    function getUpKeepBalance(uint256 _upKeepIdx) public view returns (uint256 _balance) {
        ( , , , _balance, , , ) = IKeeperRegistry(registry).getUpkeep(_upKeepIdx);
    }

    function checkUpkeep(bytes calldata /* checkData */) external view override returns (bool _upkeepNeeded, bytes memory _execPayload) {
        for (uint i = 0; i < upKeepWatchlist.length; i++) {
            uint256 upKeepIdx = upKeepWatchlist[i];
            if (getUpKeepBalance(upKeepIdx) < linkBalanceThreshold) {
                // Flag the topup is needed
                _upkeepNeeded = true;
                _execPayload = abi.encode(upKeepIdx);
                break;
            }
        }
    }

    function getPrice() {

    }

    function performUpkeep(bytes calldata data) external override onlyKeeperRegistry {
        uint256 upKeepIdx = abi.decode(data, (uint256));
        require (getUpKeepBalance(upKeepIdx) < linkBalanceThreshold);


        linkPrice = IAggregatorInterface(aggregator).latestAnswer().mul;

        // if (IKeeperProxy(keeperProxy).debtTriggerHysteria()) {
        //     IKeeperProxy(keeperProxy).rebalanceDebt();
        // } else if (IKeeperProxy(keeperProxy).collatTriggerHysteria()) {
        //     IKeeperProxy(keeperProxy).rebalanceCollateral();
        // } else {
        //     revert UpKeepNotNeeded();
        // }
    }
}
