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

/**
 *          ___           ___       ___       ___
 *         /\  \         /\__\     /\__\     /\  \
 *        /::\  \       /:/  /    /:/  /    /::\  \
 *       /:/\:\  \     /:/  /    /:/  /    /:/\:\  \
 *      /::\~\:\  \   /:/  /    /:/  /    /:/  \:\  \
 *     /:/\:\ \:\__\ /:/__/    /:/__/    /:/__/ \:\__\
 *     \/__\:\/:/  / \:\  \    \:\  \    \:\  \ /:/  /
 *          \::/  /   \:\  \    \:\  \    \:\  /:/  /
 *          /:/  /     \:\  \    \:\  \    \:\/:/  /
 *         /:/  /       \:\__\    \:\__\    \::/  /
 *         \/__/         \/__/     \/__/     \/__/
 */

/// @title Allo
/// @notice The Allo contract
/// @author allo-team
contract Allo is Transfer, Initializable, Ownable, AccessControl {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @notice Custom errors
    error UNAUTHORIZED();
error NOT_ENOUGH_FUNDS();
