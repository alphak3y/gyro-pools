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

pragma solidity 0.7.6;

// solhint-disable

library GyroThreePoolErrors {
    // NOTE: we offset by 1000 to avoid clashing with Balancer errors
    // Math
    uint256 internal constant PRICE_BOUNDS_WRONG = 351;
    uint256 internal constant INVARIANT_DIDNT_CONVERGE = 352;
    uint256 internal constant ASSET_BOUNDS_EXCEEDED = 357; //NB this is the same as the CEMM
    uint256 internal constant UNDERESTIMATE_INVARIANT_FAILED = 360;
    uint256 internal constant INVARIANT_TOO_LARGE = 361;
    uint256 internal constant BALANCES_TOO_LARGE = 362;
    uint256 internal constant INVARIANT_UNDERFLOW = 363;

    // Input
    uint256 internal constant TOKENS_LENGTH_MUST_BE_3 = 353;
}
