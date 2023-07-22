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
