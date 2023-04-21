import json
import os

from brownie import BalancerVault, interface, chain  # type: ignore
from eth_abi import encode_abi

from scripts.constants import BALANCER_ADDRESSES
from scripts.utils import get_deployer

SEED_DATA_PATH = os.environ.get("SEED_DATA_PATH")
POOL_ADDRESS = os.environ.get("POOL_ADDRESS")
GAS_PRICE = os.environ.get("BROWNIE_GWEI", "100") + " gwei"


def main():
    assert SEED_DATA_PATH, "SEED_DATA_PATH environment variable must be set"
    assert POOL_ADDRESS, "POOL_ADDRESS environment variable must be set"
    assert os.path.exists(SEED_DATA_PATH), "Config path does not exist"

    deployer = get_deployer()

    with open(SEED_DATA_PATH) as f:
        seed_data = json.load(f)

    # Doesn't work for some reason
    # vault = Vault[0]
    vault = BalancerVault.at(BALANCER_ADDRESSES[chain.id]["vault"])

    pool = interface.IBalancerPool(POOL_ADDRESS)

    pool_id = pool.getPoolId()
    pool_tokens = vault.getPoolTokens(pool_id)[0]

    assert set(seed_data["amounts"]) == set(pool_tokens), "Invalid pool tokens"

    for token, amount in seed_data["amounts"].items():
        erc_token = interface.IERC20(token)
        allowance = erc_token.allowance(deployer, vault)
        if allowance < amount:
            erc_token.approve(vault, amount, {"from": deployer, "gas_price": GAS_PRICE})

    max_amounts_in = [int(seed_data["amounts"][token]) for token in pool_tokens]

    encoded_data = encode_abi(["uint256", "uint256[]"], [0, max_amounts_in])
    user_data = (pool_tokens, max_amounts_in, encoded_data, False)

    args = {"from": deployer, "gas_price": GAS_PRICE}

    vault.joinPool(pool_id, deployer, deployer, user_data, args)
