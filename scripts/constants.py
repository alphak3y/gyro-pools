from os import path

CONFIG_PATH = path.join(path.dirname(path.dirname(__file__)), "config")

BALANCER_ADDRESSES = {
    137: {
        "query_processor": "0x72D07D7DcA67b8A406aD1Ec34ce969c90bFEE768",
        "vault": "0xBA12222222228d8Ba445958a75a0704d566BF2C8",
    }
}

GYROSCOPE_ADDRESSES = {
    137: {
        "gyro_config": "0x429d5e3dcD3b0E643C4ceD35ee4b9334f9Bf81D7",
    }
}

POOL_OWNER = {
    137: "0x1645484290842EbAFeDBc9Fa5212D0D16a874865",
}

DEPLOYED_POOLS = {
    137: {
        "c2lp": "0xF353BE94205776387C0C8162B424806B00FCA93F00020000000000000000045F",
        "c3lp": "0xBC9BC9DC07A3C860DA97693D94B0F12D6DCCF4B1000100000000000000000460",
    }
}