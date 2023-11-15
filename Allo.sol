pragma solidity 0.8.19;

import "@openzeppelin-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {AccessControl} from "@openzeppelin/access/AccessControl.sol";

import "@solady/auth/Ownable.sol";

import {Metadata} from "./libraries/Metadata.sol";
import {Clone} from "./libraries/Clone.sol";
import {Transfer} from "./libraries/Transfer.sol";
import {IStrategy} from "../strategies/IStrategy.sol";
import {Registry} from "./Registry.sol";

/// @title Allo
/// @notice The Allo contract
/// @author allo-team
contract Allo is Transfer, Initializable, Ownable, AccessControl {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @notice Custom errors
    error UNAUTHORIZED();
error NOT_ENOUGH_FUNDS();
   error NOT_APPROVED_STRATEGY();
 error IS_APPROVED_STRATEGY();
    error MISMATCH();
  error ZERO_ADDRESS();
 error INVALID_FEE();

    /// @notice Struct to hold details of an Pool
   struct Pool {
        bytes32 identityId;
IStrategy strategy;
        address token;
uint256 amount;
        Metadata metadata;
 bytes32 managerRole;
        bytes32 adminRole;
    }

    /// @notice Fee denominator
    uint256 public constant FEE_DENOMINATOR = 1e18;

    /// ==========================
    /// === Storage Variables ====
 /// ==========================

    /// @notice Fee percentage
  /// @dev 1e18 = 100%, 1e17 = 10%, 1e16 = 1%, 1e15 = 0.1%
    uint256 public feePercentage;

    /// @notice Base fee
    uint256 public baseFee;

    /// @notice Incremental index
    uint256 private _poolIndex;

    /// @notice Allo treasury
    address payable public treasury;

    /// @notice Registry of pool creators
    Registry public registry;

    /// @notice msg.sender -> nonce for cloning strategies
  mapping(address => uint256) private _nonces;

    /// @notice Pool.id -> Pool
mapping(uint256 => Pool) public pools;

    /// @notice Strategy -> bool
    mapping(address => bool) public approvedStrategies;

    /// @notice Reward for catching fee skirting (1e18 = 100%)
 uint256 public feeSkirtingBountyPercentage;

    /// ======================
  /// === Storage Variables ====
 /// ==========================

    /// @notice Fee percentage
 /// @dev 1e18 = 100%, 1e17 = 10%, 1e16 = 1%, 1e15 = 0.1%
 uint256 public feePercentage;

    /// @notice Base fee
 uint256 public baseFee;

    /// @notice Incremental index
 uint256 private _poolIndex;

    /// @notice Allo treasury
 address payable public treasury;

    /// @notice Registry of pool creators
    Registry public registry;

    /// @notice msg.sender -> nonce for cloning strategies
    mapping(address => uint256) private _nonces;

    /// @notice Pool.id -> Pool
   mapping(uint256 => Pool) public pools;

    /// @notice Strategy -> bool
mapping(address => bool) public approvedStrategies;

    /// @notice Reward for catching fee skirting (1e18 = 100%)
    uint256 public feeSkirtingBountyPercentage;

    /// ======================
    /// ======= Events =======
    /// ======================

    event PoolCreated(
        uint256 indexed poolId,
   bytes32 indexed identityId,
        IStrategy strategy,
address token,
 uint256 amount,
        Metadata metadata
    );

    event PoolMetadataUpdated(uint256 indexed poolId, Metadata metadata);

    event PoolFunded(uint256 indexed poolId, uint256 amount, uint256 fee);

    event BaseFeePaid(uint256 indexed poolId, uint256 amount);

    event PoolClosed(uint256 indexed poolId);

    event PoolTotalFundingDecreased(uint256 indexed poolId, uint256 prevAmount, uint256 newAmount);

    event TreasuryUpdated(address treasury);

    event FeePercentageUpdated(uint256 feePercentage);

    event BaseFeeUpdated(uint256 baseFee);

    event RegistryUpdated(address registry);

    event StrategyApproved(address strategy);

    event StrategyRemoved(address strategy);

    /// ====================================
    /// =========== Intializer =============
 /// ====================================

    /// @notice Initializes the contract after an upgrade
    /// @dev During upgrade -> an higher version should be passed to reinitializer
   /// @param _registry The address of the registry
    /// @param _treasury The address of the treasury
  /// @param _feePercentage The fee percentage
 /// @param _baseFee The base fee
    function initialize(address _registry, address payable _treasury, uint256 _feePercentage, uint256 _baseFee)
     public
        reinitializer(1)
    {
        _initializeOwner(msg.sender);

        registry = Registry(_registry);
 treasury = _treasury;
        feePercentage = _feePercentage;
baseFee = _baseFee;

        emit RegistryUpdated(_registry);
  emit TreasuryUpdated(_treasury);
        emit FeePercentageUpdated(_feePercentage);
 emit BaseFeeUpdated(_baseFee);
    }

    /// ====================================
    /// =========== Modifier ===============
    /// ====================================

    modifier onlyPoolManager(uint256 _poolId) {
 if (!_isPoolManager(_poolId, msg.sender)) {
            revert UNAUTHORIZED();
  }
        _;
    }

    modifier onlyPoolAdmin(uint256 _poolId) {
 if (!_isPoolAdmin(_poolId, msg.sender)) {
            revert UNAUTHORIZED();
        }
        _;
    }

    /// ====================================
    /// ==== External/Public Functions =====
    /// ====================================

    /// @notice Creates a new pool (with custom strategy)
 /// @param _identityId The identityId of the pool
    /// @param _strategy The address of strategy
 /// @param _initStrategyData The data to initialize the strategy
 /// @param _token The address of the token
    /// @param _amount The amount of the token
 /// @param _metadata The metadata of the pool
    /// @param _managers The managers of the pool
 function createPoolWithCustomStrategy(
        bytes32 _identityId,
        address _strategy,
        bytes memory _initStrategyData,
address _token,
        uint256 _amount,
Metadata memory _metadata,
        address[] memory _managers
 ) external payable returns (uint256 poolId) {
   if (_strategy == address(0)) {
            revert ZERO_ADDRESS();
        }
        if (_isApprovedStrategy(_strategy)) {
    revert IS_APPROVED_STRATEGY();
        }

        return _createPool(_identityId, IStrategy(_strategy), _initStrategyData, _token, _amount, _metadata, _managers);
 }

    /// @notice Creates a new pool (by cloning an approved strategies)
  /// @param _identityId The identityId of the pool
    /// @param _initStrategyData The data to initialize the strategy
    /// @param _token The address of the token
    /// @param _amount The amount of the token
 /// @param _metadata The metadata of the pool
 /// @param _managers The managers of the pool
    function createPoolWithCustomStrategy(
    bytes32 _identityId,
        address _strategy,
        bytes memory _initStrategyData,
address _token,
        uint256 _amount,
   Metadata memory _metadata,
 address[] memory _managers
    ) external payable returns (uint256 poolId) {
        if (_strategy == address(0)) {
     revert ZERO_ADDRESS();
        }
        if (_isApprovedStrategy(_strategy)) {
     revert IS_APPROVED_STRATEGY();
        }

        return _createPool(_identityId, IStrategy(_strategy), _initStrategyData, _token, _amount, _metadata, _managers);
  }

    /// @notice Creates a new pool (by cloning an approved strategies)
 /// @param _identityId The identityId of the pool
    /// @param _initStrategyData The data to initialize the strategy
  /// @param _token The address of the token
  /// @param _amount The amount of the token
 /// @param _metadata The metadata of the pool
 /// @param _managers The managers of the pool
  function createPoolWithCustomStrategy(
        bytes32 _identityId,
 address _strategy,
        bytes memory _initStrategyData,
address _token,
        uint256 _amount,
   Metadata memory _metadata,
        address[] memory _managers
    ) external payable returns (uint256 poolId) {
   if (_strategy == address(0)) {
            revert ZERO_ADDRESS();
  if (_isApprovedStrategy(_strategy)) {
            revert IS_APPROVED_STRATEGY();
        }

        return _createPool(_identityId, IStrategy(_strategy), _initStrategyData, _token, _amount, _metadata, _managers);
