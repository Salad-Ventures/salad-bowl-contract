// SPDX-License-Identifier: MIT
pragma solidity >=0.8.20;

import {IERC20} from "@openzeppelin5/contracts/token/ERC20/IERC20.sol";
import {IERC20Permit} from "@openzeppelin5/contracts/token/ERC20/extensions/IERC20Permit.sol";
import {ContextUpgradeable} from "@openzeppelin5/contracts-upgradeable/utils/ContextUpgradeable.sol";

import {ISaldcoinDelegate} from "./interfaces/ISaldcoinDelegate.sol";

abstract contract SaldcoinDelegatableUpgradeable is ContextUpgradeable {
    error NotDelegatable();

    ISaldcoinDelegate private _delegate;

    function __SaldcoinDelegatable_init(address delegate_) internal onlyInitializing {
        __SaldcoinDelegatable_init_unchained(delegate_);
    }

    function __SaldcoinDelegatable_init_unchained(address delegate_) internal onlyInitializing {
        _delegate = ISaldcoinDelegate(delegate_);
    }

    function delegate() external view returns (address) {
        return address(_delegate);
    }

    function _delegateTransfer(address to, uint256 amount) internal returns (bool) {
        return _delegate.transferFrom(_msgSender(), to, amount);
    }

    function _delegatePermit(bytes calldata _permit) internal {
        (uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) =
            abi.decode(_permit, (uint256, uint256, uint8, bytes32, bytes32));
        try IERC20Permit(_delegate.saldcoin()).permit(_msgSender(), address(_delegate), value, deadline, v, r, s) {}
            catch {}
    }

    modifier onlyDelegatable() {
        if (!_delegate.isAuthorized(_msgSender())) revert NotDelegatable();
        _;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}
