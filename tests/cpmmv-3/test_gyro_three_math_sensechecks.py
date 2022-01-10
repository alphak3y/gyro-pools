from decimal import Decimal
from typing import Tuple

import hypothesis.strategies as st
import pytest
from brownie.test import given
from brownie import reverts
from hypothesis import assume

from tests.support.utils import scale, to_decimal, qdecimals, unscale
from tests.support.quantized_decimal import QuantizedDecimal as D

from operator import add

billion_balance_strategy = st.integers(min_value=0, max_value=1_000_000_000)


def triple_uniform_integers(min_value=0, max_value=1_000_000_000):
    g = st.integers(min_value=min_value, max_value=max_value)
    return st.tuples(g, g, g)


def gen_balances():
    return st.tuples(
        billion_balance_strategy, billion_balance_strategy, billion_balance_strategy
    )


def gen_root3Alpha():
    return qdecimals(min_value="0.9", max_value="0.99996")


@given(
    balances=gen_balances(),
    root3Alpha=gen_root3Alpha(),
    addl_balances=triple_uniform_integers(500_000_000),
)
def test_calculateInvariant_growth(
    gyro_three_math_testing, balances, root3Alpha, addl_balances
):
    l_low = gyro_three_math_testing.calculateInvariant(
        scale(balances), scale(root3Alpha)
    )

    balances_high = tuple(map(add, balances, addl_balances))
    l_high = gyro_three_math_testing.calculateInvariant(
        scale(balances_high), scale(root3Alpha)
    )
    assert l_low < l_high

def test_calcInGivenOut_pricebounds(gyro_three_math_testing):
    run_test_calcInGivenOut_pricebounds(gyro_three_math_testing, [1_000_000, 2_000_000, 1_000_000], D('0.999')**(D(1)/3), 100_000, 0, 2)
    run_test_calcInGivenOut_pricebounds(gyro_three_math_testing, [10_000_000, 2_000_000, 10_000], D('0.9995'), 100_000, 1, 0)
    run_test_calcInGivenOut_pricebounds(gyro_three_math_testing, [10_000_000, 2_000_000, 10_000], D('0.9998'), 2000, 1, 2)
    run_test_calcInGivenOut_pricebounds(gyro_three_math_testing, [10_000_000, 2_000_000, 10_000_000_000], D('0.9997'), 500_000, 0, 2)
    run_test_calcInGivenOut_pricebounds(gyro_three_math_testing, [10_000_000, 2_000_000, 10_000_000_000], D('0.9999'), 200, 1, 0)
    with reverts():
        run_test_calcInGivenOut_pricebounds(gyro_three_math_testing, [10_000_000, 2_000_000, 10_000], D('0.9998'), 5000, 2, 1)
    with reverts():
        run_test_calcInGivenOut_pricebounds(gyro_three_math_testing, [10_000_000, 2_000_000, 10_000], D('0.9998'), 5000, 1, 2)


def test_calcOutGivenIn_pricebounds(gyro_three_math_testing):
    run_test_calcOutGivenIn_pricebounds(gyro_three_math_testing, [1_000_000, 2_000_000, 1_000_000], D('0.999')**(D(1)/3), 100_000, 0, 2)
    run_test_calcOutGivenIn_pricebounds(gyro_three_math_testing, [10_000_000, 2_000_000, 10_000], D('0.9995'), 100_000, 1, 0)
    run_test_calcOutGivenIn_pricebounds(gyro_three_math_testing, [10_000_000, 2_000_000, 10_000], D('0.9998'), 2000, 1, 2)
    run_test_calcOutGivenIn_pricebounds(gyro_three_math_testing, [10_000_000, 2_000_000, 10_000_000_000], D('0.9997'), 500_000, 0, 2)
    run_test_calcOutGivenIn_pricebounds(gyro_three_math_testing, [10_000_000, 2_000_000, 10_000_000_000], D('0.9999'), 200, 1, 0)
    with reverts():
        run_test_calcInGivenOut_pricebounds(gyro_three_math_testing, [10_000_000, 2_000_000, 10_000], D('0.9998'), 5000, 2, 1)
    with reverts():
        run_test_calcInGivenOut_pricebounds(gyro_three_math_testing, [10_000_000, 2_000_000, 10_000], D('0.9998'), 5000, 1, 2)


def test_InOut_inverse(gyro_three_math_testing):
    run_test_InOut_inverse(gyro_three_math_testing, [1_000_000, 2_000_000, 1_000_000], D('0.999')**(D(1)/3), 100_000, 0, 2)
    run_test_InOut_inverse(gyro_three_math_testing, [10_000_000, 2_000_000, 10_000], D('0.9995'), 100_000, 1, 0)
    run_test_InOut_inverse(gyro_three_math_testing, [10_000_000, 2_000_000, 10_000], D('0.9998'), 2000, 1, 2)
    run_test_InOut_inverse(gyro_three_math_testing, [10_000_000, 2_000_000, 10_000_000_000], D('0.9997'), 500_000, 0, 2)
    run_test_InOut_inverse(gyro_three_math_testing, [10_000_000, 2_000_000, 10_000_000_000], D('0.9999'), 200, 1, 0)

def run_test_calcInGivenOut_pricebounds(gyro_three_math_testing, balances, root3Alpha, amountOut, ixIn, ixOut):
    invariant = unscale(gyro_three_math_testing._calculateInvariant(scale(balances), scale(root3Alpha)))
    virtualOffsetInOut = invariant * root3Alpha

    amountIn = unscale(gyro_three_math_testing._calcInGivenOut(
        scale(balances[ixIn]), scale(balances[ixOut]), scale(amountOut), scale(virtualOffsetInOut)
    ))

    alpha = root3Alpha**3

    assert alpha < amountOut / amountIn < D(1)/alpha

def run_test_calcOutGivenIn_pricebounds(gyro_three_math_testing, balances, root3Alpha, amountIn, ixIn, ixOut):
    invariant = unscale(gyro_three_math_testing._calculateInvariant(scale(balances), scale(root3Alpha)))
    virtualOffsetInOut = invariant * root3Alpha

    amountOut = unscale(gyro_three_math_testing._calcOutGivenIn(
        scale(balances[ixIn]), scale(balances[ixOut]), scale(amountIn), scale(virtualOffsetInOut)
    ))

    alpha = root3Alpha**3

    assert alpha < amountOut / amountIn < D(1)/alpha


def run_test_InOut_inverse(gyro_three_math_testing, balances, root3Alpha, amountIn, ixIn, ixOut):
    invariant = unscale(gyro_three_math_testing._calculateInvariant(scale(balances), scale(root3Alpha)))
    virtualOffsetInOut = invariant * root3Alpha

    amountOut = unscale(gyro_three_math_testing._calcOutGivenIn(
        scale(balances[ixIn]), scale(balances[ixOut]), scale(amountIn), scale(virtualOffsetInOut)
    ))
    amountIn1 = unscale(gyro_three_math_testing._calcInGivenOut(
        scale(balances[ixIn]), scale(balances[ixOut]), scale(amountOut), scale(virtualOffsetInOut)
    ))

    assert amountIn1 == to_decimal(amountIn).approxed()

    amountOut1 = unscale(gyro_three_math_testing._calcOutGivenIn(
        scale(balances[ixIn]), scale(balances[ixOut]), scale(amountIn1), scale(virtualOffsetInOut)
    ))

    assert amountOut1 == amountOut.approxed()


