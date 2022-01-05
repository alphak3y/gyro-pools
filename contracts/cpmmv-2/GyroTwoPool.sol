// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "@balancer-labs/v2-solidity-utils/contracts/math/FixedPoint.sol";

import "@balancer-labs/v2-pool-weighted/contracts/WeightedOracleMath.sol";
import "@balancer-labs/v2-pool-weighted/contracts/WeightedPoolUserDataHelpers.sol";
import "@balancer-labs/v2-pool-weighted/contracts/WeightedPool2TokensMiscData.sol";

import "./ExtensibleWeightedPool2Tokens.sol";
import "./Gyro2PoolErrors.sol";
import "./GyroTwoMath.sol";

contract GyroTwoPool is ExtensibleWeightedPool2Tokens {
    using FixedPoint for uint256;
    using WeightedPoolUserDataHelpers for bytes;
    using WeightedPool2TokensMiscData for bytes32;

    uint256 private _sqrtAlpha;
    uint256 private _sqrtBeta;

    struct GyroParams {
        IVault vault;
        string name;
        string symbol;
        IERC20 token0;
        IERC20 token1;
        uint256 normalizedWeight0; // A: For now we leave it, unclear if we will need it
        uint256 normalizedWeight1; // A: For now we leave it, unclear if we will need it
        uint256 sqrtAlpha; // A: Should already be upscaled
        uint256 sqrtBeta; // A: Should already be upscaled. Could be passed as an array[](2)
        uint256 swapFeePercentage;
        uint256 pauseWindowDuration;
        uint256 bufferPeriodDuration;
        bool oracleEnabled;
        address owner;
    }

    constructor(GyroParams memory params)
        ExtensibleWeightedPool2Tokens(
            NewPoolParams(
                params.vault,
                params.name,
                params.symbol,
                params.token0,
                params.token1,
                params.normalizedWeight0,
                params.normalizedWeight1,
                params.swapFeePercentage,
                params.pauseWindowDuration,
                params.bufferPeriodDuration,
                params.oracleEnabled,
                params.owner
            )
        )
    {
        _require(
            params.sqrtAlpha < params.sqrtBeta,
            Gyro2PoolErrors.SQRT_PARAMS_WRONG
        );
        _sqrtAlpha = params.sqrtAlpha;
        _sqrtBeta = params.sqrtBeta;
    }

    // Returns sqrtAlpha and sqrtBeta

    function getSqrtParameters() external view returns (uint256[] memory) {
        return _sqrtParameters();
    }

    function _sqrtParameters()
        internal
        view
        virtual
        returns (uint256[] memory)
    {
        uint256[] memory virtualParameters = new uint256[](2);
        virtualParameters[0] = _sqrtParameters(true);
        virtualParameters[1] = _sqrtParameters(false);
        return virtualParameters;
    }

    function _sqrtParameters(bool parameter0)
        internal
        view
        virtual
        returns (uint256)
    {
        return parameter0 ? _sqrtAlpha : _sqrtBeta;
    }

    // Returns a and b parameters

    function getvirtualParameters() external view returns (uint256[] memory) {
        return _getvirtualParameters();
    }

    function _getvirtualParameters() internal view returns (uint256[] memory) {
        uint256[] memory virtualParameters = new uint256[](2);

        uint256[] memory sqrtParams = _sqrtParameters();
        uint256 _invariant = this.getLastInvariant();

        virtualParameters[0] = _virtualParameters(
            true,
            sqrtParams[1],
            _invariant
        );
        virtualParameters[1] = _virtualParameters(
            false,
            sqrtParams[0],
            _invariant
        );
        return virtualParameters;
    }

    function _getvirtualParameters(
        uint256[] memory sqrtParams,
        uint256 invariant
    ) internal view virtual returns (uint256[] memory) {
        uint256[] memory virtualParameters = new uint256[](2);

        virtualParameters[0] = _virtualParameters(
            true,
            sqrtParams[1],
            invariant
        );
        virtualParameters[1] = _virtualParameters(
            false,
            sqrtParams[0],
            invariant
        );
        return virtualParameters;
    }

    function _virtualParameters(
        bool parameter0,
        uint256 sqrtParam,
        uint256 invariant
    ) internal view virtual returns (uint256) {
        return
            parameter0
                ? (
                    GyroTwoMath._calculateVirtualParameter0(
                        invariant,
                        sqrtParam
                    )
                )
                : (
                    GyroTwoMath._calculateVirtualParameter1(
                        invariant,
                        sqrtParam
                    )
                );
    }

    /**
     * @dev Returns the current value of the invariant.
     */
    function getInvariant() public view override returns (uint256) {
        (, uint256[] memory balances, ) = getVault().getPoolTokens(getPoolId());
        uint256[] memory sqrtParams = _sqrtParameters();

        // Since the Pool hooks always work with upscaled balances, we manually
        // upscale here for consistency
        _upscaleArray(balances);

        return
            GyroTwoMath._calculateInvariant(
                balances,
                sqrtParams[0],
                sqrtParams[1]
            );
    }

    // Swap Hooks

    function onSwap(
        SwapRequest memory request,
        uint256 balanceTokenIn,
        uint256 balanceTokenOut
    )
        public
        virtual
        override
        whenNotPaused
        onlyVault(request.poolId)
        returns (uint256)
    {
        bool tokenInIsToken0 = request.tokenIn == _token0;

        uint256 scalingFactorTokenIn = _scalingFactor(tokenInIsToken0);
        uint256 scalingFactorTokenOut = _scalingFactor(!tokenInIsToken0);

        // All token amounts are upscaled.
        balanceTokenIn = _upscale(balanceTokenIn, scalingFactorTokenIn);
        balanceTokenOut = _upscale(balanceTokenOut, scalingFactorTokenOut);

        // Update price oracle with the pre-swap balances
        _updateOracle(
            request.lastChangeBlock,
            tokenInIsToken0 ? balanceTokenIn : balanceTokenOut,
            tokenInIsToken0 ? balanceTokenOut : balanceTokenIn
        );

        // All the calculations in one function to avoid Error Stack Too Deep
        (
            uint256 currentInvariant,
            uint256 virtualParamIn,
            uint256 virtualParamOut
        ) = _calculateCurrentValues(
                balanceTokenIn,
                balanceTokenOut,
                tokenInIsToken0
            );

        if (request.kind == IVault.SwapKind.GIVEN_IN) {
            // Fees are subtracted before scaling, to reduce the complexity of the rounding direction analysis.
            // This is amount - fee amount, so we round up (favoring a higher fee amount).
            uint256 feeAmount = request.amount.mulUp(getSwapFeePercentage());
            request.amount = _upscale(
                request.amount.sub(feeAmount),
                scalingFactorTokenIn
            );

            uint256 amountOut = _onSwapGivenIn(
                request,
                balanceTokenIn,
                balanceTokenOut,
                virtualParamIn,
                virtualParamOut,
                currentInvariant
            );

            // amountOut tokens are exiting the Pool, so we round down.
            return _downscaleDown(amountOut, scalingFactorTokenOut);
        } else {
            request.amount = _upscale(request.amount, scalingFactorTokenOut);

            uint256 amountIn = _onSwapGivenOut(
                request,
                balanceTokenIn,
                balanceTokenOut,
                virtualParamIn,
                virtualParamOut,
                currentInvariant
            );

            // amountIn tokens are entering the Pool, so we round up.
            amountIn = _downscaleUp(amountIn, scalingFactorTokenIn);

            // Fees are added after scaling happens, to reduce the complexity of the rounding direction analysis.
            // This is amount + fee amount, so we round up (favoring a higher fee amount).
            return amountIn.divUp(getSwapFeePercentage().complement());
        }
    }

    //Check: why are these functions not colliding with those in WeightedPool2TokensForGyro, even when those functions are marked as external?

    function _onSwapGivenIn(
        SwapRequest memory swapRequest,
        uint256 currentBalanceTokenIn,
        uint256 currentBalanceTokenOut,
        uint256 virtualParamIn,
        uint256 virtualParamOut,
        uint256 invariant
    ) private pure returns (uint256) {
        // Swaps are disabled while the contract is paused.
        return
            GyroTwoMath._calcOutGivenIn(
                currentBalanceTokenIn,
                currentBalanceTokenOut,
                swapRequest.amount,
                virtualParamIn,
                virtualParamOut,
                invariant
            );
    }

    //Check: why are these functions not colliding with those in WeightedPool2TokensForGyro, even when those functions are marked as external?

    function _onSwapGivenOut(
        SwapRequest memory swapRequest,
        uint256 currentBalanceTokenIn,
        uint256 currentBalanceTokenOut,
        uint256 virtualParamIn,
        uint256 virtualParamOut,
        uint256 invariant
    ) private pure returns (uint256) {
        // Swaps are disabled while the contract is paused.
        return
            GyroTwoMath._calcInGivenOut(
                currentBalanceTokenIn,
                currentBalanceTokenOut,
                swapRequest.amount,
                virtualParamIn,
                virtualParamOut,
                invariant
            );
    }

    function calculateCurrentValues(
        uint256 balanceTokenIn,
        uint256 balanceTokenOut,
        bool tokenInIsToken0
    )
        public
        view
        returns (
            uint256 currentInvariant,
            uint256 virtualParamIn,
            uint256 virtualParamOut
        )
    {
        return
            _calculateCurrentValues(
                balanceTokenIn,
                balanceTokenOut,
                tokenInIsToken0
            );
    }

    function _calculateCurrentValues(
        uint256 balanceTokenIn,
        uint256 balanceTokenOut,
        bool tokenInIsToken0
    )
        internal
        view
        returns (
            uint256 currentInvariant,
            uint256 virtualParamIn,
            uint256 virtualParamOut
        )
    {
        // if we have more tokens we might need to get the balances from the Vault
        uint256[] memory balances = new uint256[](2);
        balances[0] = tokenInIsToken0 ? balanceTokenIn : balanceTokenOut;
        balances[1] = tokenInIsToken0 ? balanceTokenOut : balanceTokenIn;

        uint256[] memory sqrtParams = _sqrtParameters();

        currentInvariant = GyroTwoMath._calculateInvariant(
            balances,
            sqrtParams[0],
            sqrtParams[1]
        );

        uint256[] memory virtualParam = new uint256[](2);
        virtualParam = _getvirtualParameters(sqrtParams, currentInvariant);

        virtualParamIn = tokenInIsToken0 ? virtualParam[0] : virtualParam[1];
        virtualParamOut = tokenInIsToken0 ? virtualParam[1] : virtualParam[0];
    }

    //Note is public visibility ok for the following function?

    /**
     * @dev Called when the Pool is joined for the first time; that is, when the BPT total supply is zero.
     *
     * Returns the amount of BPT to mint, and the token amounts the Pool will receive in return.
     *
     * Minted BPT will be sent to `recipient`, except for _MINIMUM_BPT, which will be deducted from this amount and sent
     * to the zero address instead. This will cause that BPT to remain forever locked there, preventing total BTP from
     * ever dropping below that value, and ensuring `_onInitializePool` can only be called once in the entire Pool's
     * lifetime.
     *
     * The tokens granted to the Pool will be transferred from `sender`. These amounts are considered upscaled and will
     * be downscaled (rounding up) before being returned to the Vault.
     */
    function _onInitializePool(
        bytes32,
        address,
        address,
        bytes memory userData
    ) internal override returns (uint256, uint256[] memory) {
        BaseWeightedPool.JoinKind kind = userData.joinKind();
        _require(kind == BaseWeightedPool.JoinKind.INIT, Errors.UNINITIALIZED);

        uint256[] memory amountsIn = userData.initialAmountsIn();
        InputHelpers.ensureInputLengthMatch(amountsIn.length, 2);
        _upscaleArray(amountsIn);

        uint256[] memory sqrtParams = _sqrtParameters();

        uint256 invariantAfterJoin = GyroTwoMath._calculateInvariant(
            amountsIn,
            sqrtParams[0],
            sqrtParams[1]
        );

        // Set the initial BPT to the value of the invariant times the number of tokens. This makes BPT supply more
        // consistent in Pools with similar compositions but different number of tokens.

        uint256 bptAmountOut = Math.mul(invariantAfterJoin, 2);

        _lastInvariant = invariantAfterJoin;

        return (bptAmountOut, amountsIn);
    }

    /**
     * @dev Called whenever the Pool is joined after the first initialization join (see `_onInitializePool`).
     *
     * Returns the amount of BPT to mint, the token amounts that the Pool will receive in return, and the number of
     * tokens to pay in protocol swap fees.
     *
     * Implementations of this function might choose to mutate the `balances` array to save gas (e.g. when
     * performing intermediate calculations, such as subtraction of due protocol fees). This can be done safely.
     *
     * Minted BPT will be sent to `recipient`.
     *
     * The tokens granted to the Pool will be transferred from `sender`. These amounts are considered upscaled and will
     * be downscaled (rounding up) before being returned to the Vault.
     *
     * Due protocol swap fees will be taken from the Pool's balance in the Vault (see `IBasePool.onJoinPool`). These
     * amounts are considered upscaled and will be downscaled (rounding down) before being returned to the Vault.
     */
    function _onJoinPool(
        bytes32,
        address,
        address,
        uint256[] memory balances,
        uint256,
        uint256 protocolSwapFeePercentage,
        bytes memory userData
    )
        internal
        override
        returns (
            uint256,
            uint256[] memory,
            uint256[] memory
        )
    {
        uint256[] memory normalizedWeights = _normalizedWeights();

        // Due protocol swap fee amounts are computed by measuring the growth of the invariant between the previous join
        // or exit event and now - the invariant's growth is due exclusively to swap fees. This avoids spending gas
        // computing them on each individual swap

        uint256[] memory sqrtParams = _sqrtParameters();
        uint256 lastInvariant = this.getLastInvariant();

        uint256 invariantBeforeJoin = GyroTwoMath._calculateInvariant(
            balances,
            sqrtParams[0],
            sqrtParams[1]
        );

        uint256[] memory dueProtocolFeeAmounts = _getDueProtocolFeeAmounts(
            balances,
            normalizedWeights,
            lastInvariant,
            invariantBeforeJoin,
            protocolSwapFeePercentage
        );

        // Update current balances by subtracting the protocol fee amounts
        _mutateAmounts(balances, dueProtocolFeeAmounts, FixedPoint.sub);
        (uint256 bptAmountOut, uint256[] memory amountsIn) = _doJoin(
            balances,
            normalizedWeights,
            userData
        );

        // We have the incrementX (amountIn) and balances (excluding fees) so we should be able to calculate incrementL
        _lastInvariant = GyroTwoMath._liquidityInvariantUpdate(
            balances,
            sqrtParams[0],
            sqrtParams[1],
            lastInvariant,
            amountsIn[1],
            true
        );

        return (bptAmountOut, amountsIn, dueProtocolFeeAmounts);
    }

    /**
     * @dev Called whenever the Pool is exited.
     *
     * Returns the amount of BPT to burn, the token amounts for each Pool token that the Pool will grant in return, and
     * the number of tokens to pay in protocol swap fees.
     *
     * Implementations of this function might choose to mutate the `balances` array to save gas (e.g. when
     * performing intermediate calculations, such as subtraction of due protocol fees). This can be done safely.
     *
     * BPT will be burnt from `sender`.
     *
     * The Pool will grant tokens to `recipient`. These amounts are considered upscaled and will be downscaled
     * (rounding down) before being returned to the Vault.
     *
     * Due protocol swap fees will be taken from the Pool's balance in the Vault (see `IBasePool.onExitPool`). These
     * amounts are considered upscaled and will be downscaled (rounding down) before being returned to the Vault.
     */
    function _onExitPool(
        bytes32,
        address,
        address,
        uint256[] memory balances,
        uint256 lastChangeBlock,
        uint256 protocolSwapFeePercentage,
        bytes memory userData
    )
        internal
        override
        returns (
            uint256 bptAmountIn,
            uint256[] memory amountsOut,
            uint256[] memory dueProtocolFeeAmounts
        )
    {
        // Exits are not completely disabled while the contract is paused: proportional exits (exact BPT in for tokens
        // out) remain functional.

        uint256[] memory normalizedWeights = _normalizedWeights();

        uint256[] memory sqrtParams = _sqrtParameters();
        uint256 lastInvariant = this.getLastInvariant();

        if (_isNotPaused()) {
            // Update price oracle with the pre-exit balances
            _updateOracle(lastChangeBlock, balances[0], balances[1]);

            // Due protocol swap fee amounts are computed by measuring the growth of the invariant between the previous
            // join or exit event and now - the invariant's growth is due exclusively to swap fees. This avoids
            // spending gas calculating the fees on each individual swap.
            // TO DO: Same here as in joinPool
            uint256 invariantBeforeExit = GyroTwoMath._calculateInvariant(
                balances,
                sqrtParams[0],
                sqrtParams[1]
            );
            dueProtocolFeeAmounts = _getDueProtocolFeeAmounts(
                balances,
                normalizedWeights,
                lastInvariant,
                invariantBeforeExit,
                protocolSwapFeePercentage
            );

            // Update current balances by subtracting the protocol fee amounts
            _mutateAmounts(balances, dueProtocolFeeAmounts, FixedPoint.sub);
        } else {
            // If the contract is paused, swap protocol fee amounts are not charged and the oracle is not updated
            // to avoid extra calculations and reduce the potential for errors.
            dueProtocolFeeAmounts = new uint256[](2);
        }

        (bptAmountIn, amountsOut) = _doExit(
            balances,
            normalizedWeights,
            userData
        );

        _lastInvariant = GyroTwoMath._liquidityInvariantUpdate(
            balances,
            sqrtParams[0],
            sqrtParams[1],
            lastInvariant,
            amountsOut[1],
            false
        );

        return (bptAmountIn, amountsOut, dueProtocolFeeAmounts);
    }
}