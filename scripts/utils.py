from functools import lru_cache, wraps
import os
import sys
from typing import Any, Dict, cast
from brownie import accounts, network
from brownie.network.account import ClefAccount, LocalAccount

DEV_CHAIN_IDS = {1337}
MAINNET_DEPLOYER_ADDRESS = "0x0000000000000000000000000000000000000000"
REQUIRED_CONFIRMATIONS = 1

BROWNIE_GWEI = os.environ.get("BROWNIE_GWEI", "35")
BROWNIE_PRIORITY_GWEI = os.environ.get("BROWNIE_PRIORITY_GWEI")
BROWNIE_ACCOUNT_PASSWORD = os.environ.get("BROWNIE_ACCOUNT_PASSWORD")


def is_live():
    return network.chain.id not in DEV_CHAIN_IDS


def connect_to_clef():
    if not any(isinstance(acc, ClefAccount) for acc in accounts):
        print("Connecting to clef...")
        accounts.connect_to_clef()


def get_clef_account(address: str):
    connect_to_clef()
    return find_account(address)


def find_account(address: str) -> LocalAccount:
    matching = [acc for acc in accounts if acc.address == address]
    if not matching:
        raise ValueError(f"could not find account for {address}")
    return cast(LocalAccount, matching[0])


def make_tx_params():
    tx_params: Dict[str, Any] = {
        "required_confs": REQUIRED_CONFIRMATIONS,
    }
    if BROWNIE_PRIORITY_GWEI:
        tx_params["priority_fee"] = f"{BROWNIE_PRIORITY_GWEI} gwei"
    else:
        tx_params["gas_price"] = f"{BROWNIE_GWEI} gwei"
    return tx_params


@lru_cache()
def get_deployer() -> LocalAccount:
    chain_id = network.chain.id
    if not is_live():
        return cast(LocalAccount, accounts[0])
    if chain_id == 1111:  # live-mainnet-fork
        return find_account(MAINNET_DEPLOYER_ADDRESS)
    if chain_id == 1:  # mainnet
        return get_clef_account(MAINNET_DEPLOYER_ADDRESS)
    if chain_id == 137:  # polygon
        return cast(LocalAccount, accounts.load("polygon-master"))
    if chain_id == 42:  # kovan
        return cast(
            LocalAccount, accounts.load("kovan-deployer", BROWNIE_ACCOUNT_PASSWORD)  # type: ignore
        )
    raise ValueError(f"chain id {chain_id} not yet supported")


def abort(reason, code=1):
    print(f"error: {reason}", file=sys.stderr)
    sys.exit(code)


def with_deployed(Contract):
    def wrapped(f):
        @wraps(f)
        def wrapper(*args, **kwargs):
            if len(Contract) == 0:
                abort(f"{Contract.deploy._name} not deployed")

            contract = Contract[0]
            result = f(contract, *args, **kwargs)
            return result

        return wrapper

    return wrapped
