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
