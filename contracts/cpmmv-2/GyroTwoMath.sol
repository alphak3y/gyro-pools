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

import "@balancer-labs/v2-solidity-utils/contracts/math/FixedPoint.sol";
import "@balancer-labs/v2-solidity-utils/contracts/math/Math.sol";
import "@balancer-labs/v2-solidity-utils/contracts/helpers/InputHelpers.sol";

import "./Gyro2PoolErrors.sol";

// These functions start with an underscore, as if they were part of a contract and not a library. At some point this
// should be fixed.
// solhint-disable private-vars-leading-underscore

library GyroTwoMath {
    using FixedPoint for uint256;
    // A minimum normalized weight imposes a maximum weight ratio. We need this due to limitations in the
    // implementation of the power function, as these ratios are often exponents.
    uint256 internal constant _MIN_WEIGHT = 0.01e18;
    // Having a minimum normalized weight imposes a limit on the maximum number of tokens;
    // i.e., the largest possible pool is one where all tokens have exactly the minimum weight.
    uint256 internal constant _MAX_WEIGHTED_TOKENS = 100;

    // Pool limits that arise from limitations in the fixed point power function (and the imposed 1:100 maximum weight
    // ratio).

    // Swap limits: amounts swapped may not be larger than this percentage of total balance.
    uint256 internal constant _MAX_IN_RATIO = 0.3e18;
    uint256 internal constant _MAX_OUT_RATIO = 0.3e18;

    uint256 internal constant _MIN_BAL_RATIO = 1e13; // 1e-5

    // Invariant growth limit: non-proportional joins cannot cause the invariant to increase by more than this ratio.
    uint256 internal constant _MAX_INVARIANT_RATIO = 3e18;
    // Invariant shrink limit: non-proportional exits cannot cause the invariant to decrease by less than this ratio.
    uint256 internal constant _MIN_INVARIANT_RATIO = 0.7e18;

    // About swap fees on joins and exits:
    // Any join or exit that is not perfectly balanced (e.g. all single token joins or exits) is mathematically
    // equivalent to a perfectly balanced join or  exit followed by a series of swaps. Since these swaps would charge
    // swap fees, it follows that (some) joins and exits should as well.
    // On these operations, we split the token amounts in 'taxable' and 'non-taxable' portions, where the 'taxable' part
    // is the one to which swap fees are applied.

    // Invariant is used to collect protocol swap fees by comparing its value between two times.
    // So we can round always to the same direction. It is also used to initiate the BPT amount
    // and, because there is a minimum BPT, we round down the invariant.
    function _calculateInvariant(
        uint256[] memory balances,
        uint256 sqrtAlpha,
        uint256 sqrtBeta
    ) internal pure returns (uint256) {
        /**********************************************************************************************
        // Calculate with quadratic formula
        // 0 = (1-sqrt(alpha/beta)*L^2 - (y/sqrt(beta)+x*sqrt(alpha))*L - x*y)
        // 0 = a*L^2 + b*L + c
        // here a > 0, b < 0, and c < 0, which is a special case that works well w/o negative numbers
        // taking mb = -b and mc = -c:                            (1/2)
        //                                  mb + (mb^2 + 4 * a * mc)^                   //
        //                   L =    ------------------------------------------          //
        //                                          2 * a                               //
        //                                                                              //
        **********************************************************************************************/
        (uint256 a, uint256 mb, uint256 mc) = _calculateQuadraticTerms(balances, sqrtAlpha, sqrtBeta);
        return _calculateQuadratic(a, mb, mc);
    }

    /** @dev Prepares quadratic terms for input to _calculateQuadratic
     *   works with a special case of quadratic that works nicely w/o negative numbers
     *   assumes a > 0, b < 0, and c <= 0 and returns a, -b, -c
     */
    function _calculateQuadraticTerms(
        uint256[] memory balances,
        uint256 sqrtAlpha,
        uint256 sqrtBeta
    )
        internal
        pure
        returns (
            uint256 a,
            uint256 mb,
            uint256 mc
        )
    {
        a = FixedPoint.ONE.sub(sqrtAlpha.divDown(sqrtBeta));
        uint256 bterm0 = balances[1].divDown(sqrtBeta);
        uint256 bterm1 = balances[0].mulDown(sqrtAlpha);
        mb = bterm0.add(bterm1);
        mc = balances[0].mulDown(balances[1]);
    }

    /** @dev Calculates quadratic root for a special case of quadratic
     *   assumes a > 0, b < 0, and c <= 0, which is the case for a L^2 + b L + c = 0
     *   where   a = 1 - sqrt(alpha/beta)
     *           b = -(y/sqrt(beta) + x*sqrt(alpha))
     *           c = -x*y
     *   The special case works nicely w/o negative numbers.
     *   The args use the notation "mb" to represent -b, and "mc" to represent -c
     */
    function _calculateQuadratic(
        uint256 a,
        uint256 mb,
        uint256 mc
    ) internal pure returns (uint256 invariant) {
        uint256 denominator = a.mulUp(2 * FixedPoint.ONE);
        uint256 bSquare = mb.mulDown(mb);
        uint256 addTerm = a.mulDown(mc.mulDown(4 * FixedPoint.ONE));
        // The minus sign in the radicand cancels out in this special case, so we add
        uint256 radicand = bSquare.add(addTerm);
        uint256 sqrResult = _squareRoot(radicand);
        // The minus sign in the numerator cancels out in this special case
        uint256 numerator = mb.add(sqrResult);
        invariant = numerator.divDown(denominator);
    }

    function _squareRoot(uint256 input) internal pure returns (uint256 result) {
        result = input.powDown(FixedPoint.ONE / 2);
    }

    /** @dev calculates change in invariant following an add or remove liquidity operation
     *   This assumes that the liquidity provided was correctly balanced.
     *   Using this instead of _calculateInvariant saves evaluating a square root
     */
    function _liquidityInvariantUpdate(
        uint256[] memory lastBalances,
        uint256 sqrtAlpha,
        uint256 sqrtBeta,
        uint256 lastInvariant,
        uint256[] memory deltaBalances,
        bool isIncreaseLiq
    ) internal pure returns (uint256 invariant) {
        /**********************************************************************************************
      // From Prop. 3 in Section 2.2.3 Liquidity Update                                            //
      // Assumed that the  liquidity provided is correctly balanced                                //
      // dL = change in L invariant, absolute value (sign information in isIncreaseLiq)            //
      // dY = change in Y reserves, absolute value (sign information in isIncreaseLiq)             //
      // sqrtPx = Square root of Price p_x              sqrtPx =  L / x'                           //
      // x' = virtual reserves X (real reserves + offsets)                                         //
      //                 /            dY            \       /            dX            \           //
      //          dL =  | -------------------------- |  =  | -------------------------- |          //
      //                 \  (sqrtPx - sqrtAlpha)    /       \ (1/sqrtPx - 1/sqrtBeta)  /           //
      // One of the denominators, but not both, can be 0. We dynamically choose the formula that   //
      // gives the best numerical stability.                                                       //
      **********************************************************************************************/
        uint256 virtualX = lastBalances[0] + lastInvariant.divUp(sqrtBeta);
        uint256 sqrtPx = _calculateSqrtPrice(lastInvariant, virtualX);
        uint256 diffInvariant;
        if (lastBalances[0] <= lastBalances[1]) {
            uint256 denominator = sqrtPx.sub(sqrtAlpha);
            diffInvariant = deltaBalances[1].divDown(denominator);
        } else {
            uint256 denominator = FixedPoint.ONE.divUp(sqrtPx).sub(FixedPoint.ONE.divDown(sqrtBeta));
            diffInvariant = deltaBalances[0].divDown(denominator);
        }
        invariant = isIncreaseLiq ? lastInvariant.add(diffInvariant) : lastInvariant.sub(diffInvariant);
    }

    /** @dev Computes how many tokens can be taken out of a pool if `amountIn' are sent, given current balances
     *   balanceIn = existing balance of input token
     *   balanceOut = existing balance of requested output token
     *   virtualParamIn = virtual reserve offset for input token
     *   virtualParamOut = virtual reserve offset for output token
     *   Offsets are L/sqrt(beta) and L*sqrt(alpha) depending on what the `in' and `out' tokens are respectively
     *   Note signs are changed compared to Prop. 4 in Section 2.2.4 Trade (Swap) Exeuction to account for dy < 0
     */
    function _calcOutGivenIn(
        uint256 balanceIn,
        uint256 balanceOut,
        uint256 amountIn,
        uint256 virtualParamIn,
        uint256 virtualParamOut,
        uint256 currentInvariant
    ) internal pure returns (uint256 amountOut) {
        /**********************************************************************************************
      // Described for X = `in' asset and Y = `out' asset, but equivalent for the other case       //
      // dX = incrX  = amountIn  > 0                                                               //
      // dY = incrY = amountOut < 0                                                                //
      // x = balanceIn             x' = x +  virtualParamX                                         //
      // y = balanceOut            y' = y +  virtualParamY                                         //
      // L  = inv.Liq                   /              L^2            \                            //
      //                   - dy = y' - |   --------------------------  |                           //
      //  x' = virtIn                   \          ( x' + dX)         /                            //
      //  y' = virtOut                                                                             //
      // Note that -dy > 0 is what the trader receives.                                            //
      // We exploit the fact that this formula is symmetric up to virtualParam{X,Y}.               //
      **********************************************************************************************/

        _require(amountIn <= balanceIn.mulDown(_MAX_IN_RATIO), Errors.MAX_IN_RATIO);
        {
            uint256 virtIn = balanceIn.add(virtualParamIn);
            uint256 denominator = virtIn.add(amountIn);
            uint256 subtrahend = currentInvariant.mulDown(currentInvariant).divDown(denominator);
            uint256 virtOut = balanceOut.add(virtualParamOut);
            amountOut = virtOut.sub(subtrahend);
        }

        (uint256 balOutNew, uint256 balInNew) = (balanceOut.sub(amountOut), balanceIn.add(amountIn));

        if (balOutNew >= balInNew) {
            _require(balInNew.divUp(balOutNew) > _MIN_BAL_RATIO, Gyro2PoolErrors.ASSET_BOUNDS_EXCEEDED);
        } else {
            _require(balOutNew.divUp(balInNew) > _MIN_BAL_RATIO, Gyro2PoolErrors.ASSET_BOUNDS_EXCEEDED);
        }

        // This in particular ensures amountOut < balanceOut.
        _require(amountOut <= balanceOut.mulDown(_MAX_OUT_RATIO), Errors.MAX_OUT_RATIO);
    }

    // Computes how many tokens must be sent to a pool in order to take `amountOut`, given the
    // current balances and weights.
    // Similar to the one before but adapting bc negative values

    function _calcInGivenOut(
        uint256 balanceIn,
        uint256 balanceOut,
        uint256 amountOut,
        uint256 virtualParamIn,
        uint256 virtualParamOut,
        uint256 currentInvariant
    ) internal pure returns (uint256 amountIn) {
        /**********************************************************************************************
      // dX = incrX  = amountIn  > 0                                                               //
      // dY = incrY  = amountOut < 0                                                               //
      // x = balanceIn             x' = x +  virtualParamX                                         //
      // y = balanceOut            y' = y +  virtualParamY                                         //
      // x = balanceIn                                                                             //
      // L  = inv.Liq                /              L^2             \                              //
      //                     dx =   |   --------------------------  |  -  x'                       //
      // x' = virtIn                \         ( y' + dy)           /                               //
      // y' = virtOut                                                                              //
      // Note that dy < 0 < dx.                                                                    //
      **********************************************************************************************/
        _require(amountOut <= balanceOut.mulDown(_MAX_OUT_RATIO), Errors.MAX_OUT_RATIO);
        {
            uint256 virtOut = balanceOut.add(virtualParamOut);
            uint256 denominator = virtOut.sub(amountOut);
            uint256 term = currentInvariant.mulUp(currentInvariant).divUp(denominator);
            uint256 virtIn = balanceIn.add(virtualParamIn);
            amountIn = term.sub(virtIn);
        }

        (uint256 balOutNew, uint256 balInNew) = (balanceOut.sub(amountOut), balanceIn.add(amountIn));

        if (balOutNew >= balInNew) {
            _require(balInNew.divUp(balOutNew) > _MIN_BAL_RATIO, Gyro2PoolErrors.ASSET_BOUNDS_EXCEEDED);
        } else {
            _require(balOutNew.divUp(balInNew) > _MIN_BAL_RATIO, Gyro2PoolErrors.ASSET_BOUNDS_EXCEEDED);
        }

        _require(amountIn <= balanceIn.mulDown(_MAX_IN_RATIO), Errors.MAX_IN_RATIO);
    }

    /** @dev calculate virtual offset a for reserves x, as in (x+a)*(y+b)=L^2
     */
    function _calculateVirtualParameter0(uint256 invariant, uint256 _sqrtBeta) internal pure returns (uint256) {
        return invariant.divDown(_sqrtBeta);
    }

    /** @dev calculate virtual offset b for reserves y, as in (x+a)*(y+b)=L^2
     */
    function _calculateVirtualParameter1(uint256 invariant, uint256 _sqrtAlpha) internal pure returns (uint256) {
        return invariant.mulDown(_sqrtAlpha);
    }

    /** @dev calculate square root price of asset X in terms of asset Y
     *   derived from relation p_x * (x+a)^2 = L^2
     */
    function _calculateSqrtPrice(uint256 invariant, uint256 virtualX) internal pure returns (uint256) {
        /*********************************************************************************
      /*  sqrtPrice =  L / x'
      *********************************************************************************/
        return invariant.divDown(virtualX);
    }
}
