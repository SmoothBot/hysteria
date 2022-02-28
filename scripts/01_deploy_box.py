#!/usr/bin/python3
from brownie import (
    Hysteria,
    TransparentUpgradeableProxy,
    ProxyAdmin,
    config,
    network,
    Contract,
)
from scripts.helpful_scripts import get_account, encode_function_data


def main():
    account = get_account()
    print(f"Deploying to {network.show_active()}")
    hysteria = Hysteria.deploy(
        {"from": account},
        publish_source=True
    )
    # Optional, deploy the ProxyAdmin and use that as the admin contract
    proxy_admin = ProxyAdmin.deploy(
        {"from": account},
    )

    # If we want an intializer function we can add
    # `initializer=box.store, 1`
    # to simulate the initializer being the `store` function
    # with a `newValue` of 1
    box_encoded_initializer_function = encode_function_data()
    # box_encoded_initializer_function = encode_function_data(initializer=box.store, 1)
    proxy = TransparentUpgradeableProxy.deploy(
        hysteria.address,
        proxy_admin.address,
        b'',
        {"from": account},
        publish_source=True
    )
    print(f"Proxy deployed to {proxy} ! You can now upgrade it to BoxV2!")
    proxy_box = Contract.from_abi("Box", proxy.address, Box.abi)
    print(f"Here is the initial value in the Box: {proxy_box.retrieve()}")
