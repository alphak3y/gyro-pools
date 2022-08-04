// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.7.0;

import "@balancer-labs/v2-solidity-utils/contracts/helpers/BalancerErrors.sol";

import "../interfaces/ILocallyPausable.sol";
import "../libraries/GyroErrors.sol";

/**
 * @notice This contract is used to allow a pool to be paused directly
 */
abstract contract LocallyPausable is ILocallyPausable {
    address public pauseManager;

    string internal constant _NOT_PAUSE_MANAGER = "not pause manager";

    constructor(address _pauseManager) {
        _require(_pauseManager != address(0), GyroErrors.ZERO_ADDRESS);
        pauseManager = _pauseManager;
    }

    /// @inheritdoc ILocallyPausable
    function changePauseManager(address _pauseManager) external override {
        address currentPauseManager = pauseManager;
        require(currentPauseManager == msg.sender, _NOT_PAUSE_MANAGER);
        pauseManager = _pauseManager;
        emit PauseManagerChanged(currentPauseManager, _pauseManager);
    }

    /// @inheritdoc ILocallyPausable
    function pause() external override {
        require(pauseManager == msg.sender, _NOT_PAUSE_MANAGER);
        _setPausedState(true);
        emit PausedLocally();
    }

    /// @inheritdoc ILocallyPausable
    function unpause() external override {
        require(pauseManager == msg.sender, _NOT_PAUSE_MANAGER);
        _setPausedState(false);
        emit UnpausedLocally();
    }

    function _setPausedState(bool paused) internal virtual;
}