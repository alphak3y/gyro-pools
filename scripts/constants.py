from os import path

CONFIG_PATH = path.join(path.dirname(path.dirname(__file__)), "config")

BALANCER_ADDRESSES = {
    1: {
        "query_processor": "0x469b58680774AAc9Ad66447eFB4EF634756A2cC5",
        "vault": "0xBA12222222228d8Ba445958a75a0704d566BF2C8",
    },
    137: {
        "query_processor": "0x72D07D7DcA67b8A406aD1Ec34ce969c90bFEE768",
        "vault": "0xBA12222222228d8Ba445958a75a0704d566BF2C8",
    },
    1337: {
        "query_processor": "0xCfEB869F69431e42cdB54A4F4f105C19C080A601",
        "vault": "0xD833215cBcc3f914bD1C9ece3EE7BF8B14f841bb",
    },
    42: {
        "vault": "0xBA12222222228d8Ba445958a75a0704d566BF2C8",
        "query_processor": "0x41c7523aA9b369a65983C0ff719B81947B07fc5c",
    },
    10: {
        "query_processor": "0xD7FAD3bd59D6477cbe1BE7f646F7f1BA25b230f8",
        "vault": "0xBA12222222228d8Ba445958a75a0704d566BF2C8",
    },
    5: {
        "vault": "0xBA12222222228d8Ba445958a75a0704d566BF2C8",
        "query_processor": "0xF949645042a607fa260D932DF999FE8A02B86247",
    },
    42161: {
        "vault": "0xBA12222222228d8Ba445958a75a0704d566BF2C8",
        "query_processor": "0x6783995f91A3D7f7C24B523669488F96cCa88d31",
    },
    1101: {
        "vault": "0xBA12222222228d8Ba445958a75a0704d566BF2C8",
        "query_processor": "0x8A5eB9A5B726583a213c7e4de2403d2DfD42C8a6",
    },
}

GYROSCOPE_ADDRESSES = {
    1: {
        "gyro_config": "0xaC89cc9d78BBAd7EB3a02601B4D65dAa1f908aA6",
        "proxy_admin": "0x581aE43498196e3Dc274F3F23FF7718d287BC2C6",
    },
    137: {
        "gyro_config": "0xFdc2e9E03f515804744A40d0f8d25C16e93fbE67",
        "proxy_admin": "0x83d34ca335d197bcFe403cb38E82CBD734C4CbBE",
    },
    1337: {
        "proxy_admin": "0x90F8bf6A479f320ead074411a4B0e7944Ea8c9C1",
        "gyro_config": "0xe78A0F7E598Cc8b0Bb87894B0F60dD2a88d6a8Ab",
    },
    42: {"gyro_config": "0x402519E6cc733893af5fFf40e26397268769CBc3"},
    5: {"gyro_config": "0xfd5E29d7B36d0AfD4cb8A0AFAB5F360d21dE5C63"},
    10: {
        "gyro_config": "0x32Acb44fC929339b9F16F0449525cC590D2a23F3",
        "proxy_admin": "0x00A2a9BBD352Ab46274433FAA9Fec35fE3aBB4a8",
    },
    1101: {
        "gyro_config": "0x9b683cA24B0e013512E2566b68704dBe9677413c",
        "proxy_admin": "0x4e56F19235FF2a14C76332877a35D6aF5bDE07EC",
    },
    42161: {
        "gyro_config": "0x9b683cA24B0e013512E2566b68704dBe9677413c",
        "proxy_admin": "0x4e56F19235FF2a14C76332877a35D6aF5bDE07EC",
    },
}

POOL_OWNER = {
    1: "0xd096c2eBE242801466e6f1aC2BF5228cE1Fd445C",
    137: "0xEf63C5ceDEc9d53911162BEd5cE8956AE570387B",
    1337: "0x90F8bf6A479f320ead074411a4B0e7944Ea8c9C1",
    10: "0x8c1ce9CfD579A26D86Fd7c2fA980c28AC4C7B282",
    42161: "0x0a2B93a5e0281557428cbD7eD75aa76DADD6C6Ab",
    1101: "0xad27f3CBB918aE168c474347377C9889B10611b1",
}

PAUSE_MANAGER = {
    1: "0x41D06AA3Ea542A88f59cE853BE924CB7A942C626",
    137: "0x148b36E4F96914550145b72E9Dbcd514048CafED",
    1337: "0x90F8bf6A479f320ead074411a4B0e7944Ea8c9C1",
    10: "0xAB58cc8EA92E65b7d08314D433F9363C472346e0",
    42161: "0x4CFEf41FC6c380E8197B4f9A079360aE924a4990",
    1101: "0x67c2cE311Fcf9Ba4a6E3554E9E74A5869f3813d4",
}

DEPLOYED_POOLS = {
    137: {
        "c2lp": "0xF353BE94205776387C0C8162B424806B00FCA93F00020000000000000000045F",
        "c3lp": "0xBC9BC9DC07A3C860DA97693D94B0F12D6DCCF4B1000100000000000000000460",
    }
}

DEPLOYED_FACTORIES = {
    1: {
        "eclp": "0x412a5B2e7a678471985542757A6855847D4931D5",
        "c2clp": "0x579653927BF509B361F6e3813f5D4B95331d98c9",
    },
    1337: {
        "eclp": "0xe982E462b094850F12AF94d21D470e21bE9D0E9C",
    },
    137: {
        "c2lp": "0x5d8545a7330245150bE0Ce88F8afB0EDc41dFc34",
        "c3lp": "0x90f08B3705208E41DbEEB37A42Fb628dD483AdDa",
        "eclp": "0x1a79A24Db0F73e9087205287761fC9C5C305926b",
    },
    10: {"eclp": "0x9b683cA24B0e013512E2566b68704dBe9677413c"},
    42: {"eclp": "0xd0E45cf9e4E7008B78e679F46778bb28C2e8a5Eb"},
    5: {"eclp": "0xeEe2e20C97633f473A063e3de4807f3F974DBC6c"},
    1101: {"eclp": "0x5D56EA1B2595d2dbe4f5014b967c78ce75324f0c"},
    42161: {"eclp": "0xdCA5f1F0d7994A32BC511e7dbA0259946653Eaf6"},
}


DECIMALS = {
    "USDC": 6,
    "USDT": 6,
    "BTC": 8,
    "WBTC": 8,
    "ETH": 18,
    "WETH": 18,
    "wETH": 18,
    "DAI": 18,
    "BUSD": 18,
    "TUSD": 18,
    "WMATIC": 18,
    "stMATIC": 18,
    "MATICX": 18,
    "wstETH": 18,
    "bb-rf-aWETH": 18,
    "swETH": 18,
    "PGYD": 18,
    "rETH": 18,
    "cbETH": 18,
    "R": 18,
    "sDAI": 18,
    "LUSD": 18,
    "crvUSD": 18,
    "USDP": 18,
    "GUSD": 2,
    "TVaDAIv2": 18,
    "GYD": 18,
}

STABLE_COINS = [
    "DAI",
    "USDT",
    "USDC",
    "GUSD",
    "HUSD",
    "TUSD",
    "USDP",
    "LUSD",
    "R",
    "crvUSD",
]

TOKEN_ADDRESSES = {
    1: {
        "DAI": "0x6B175474E89094C44Da98b954EedeAC495271d0F",
        "WBTC": "0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599",
        "USDC": "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",
        "WETH": "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
        "wETH": "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
        "CRV": "0xD533a949740bb3306d119CC777fa900bA034cd52",
        "TUSD": "0x0000000000085d4780B73119b644AE5ecd22b376",
        "USDP": "0x8E870D67F660D95d5be530380D0eC0bd388289E1",
        "PAXG": "0x45804880De22913dAFE09f4980848ECE6EcbAf78",
        "AAVE": "0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9",
        "LUSD": "0x5f98805A4E8be255a32880FDeC7F6728C6568bA0",
        "COMP": "0xc00e94Cb662C3520282E6f5717214004A7f26888",
        "USDT": "0xdAC17F958D2ee523a2206206994597C13D831ec7",
        "GUSD": "0x056Fd409E1d7A124BD7017459dFEa2F387b6d5Cd",
        "HUSD": "0xdF574c24545E5FfEcb9a659c229253D4111d87e1",
        "wstETH": "0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0",
        "swETH": "0xf951E335afb289353dc249e82926178EaC7DEd78",
        "cbETH": "0xBe9895146f7AF43049ca1c1AE358B0541Ea49704",
        "R": "0x183015a9bA6fF60230fdEaDc3F43b3D788b13e21",
        "sDAI": "0x83F20F44975D03b1b09e64809B757c47f942BEeA",
        "rETH": "0xae78736Cd615f374D3085123A210448E74Fc6393",
        "crvUSD": "0xf939e0a03fb07f59a73314e73794be0e57ac1b4e",
        "GYD": "0xe07F9D810a48ab5c3c914BA3cA53AF14E4491e8A",
    },
    10: {
        "USDC": "0x7F5c764cBc14f9669B88837ca1490cCa17c31607",
        "USDT": "0x94b008aa00579c1307b0ef2c499ad98a8ce58e58",
        "WETH": "0x4200000000000000000000000000000000000006",
        "wstETH": "0x1F32b1c2345538c0c6f582fCB022739c4A194Ebb",
        "bb-rf-aWETH": "0xDD89C7cd0613C1557B2DaAC6Ae663282900204f1",
    },
    137: {
        "DAI": "0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063",
        "WBTC": "0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6",
        "USDC": "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174",
        "WETH": "0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619",
        "CRV": "0x172370d5Cd63279eFa6d502DAB29171933a610AF",
        "TUSD": "0x2e1AD108fF1D8C782fcBbB89AAd783aC49586756",
        "PAXG": "0x553d3D295e0f695B9228246232eDF400ed3560B5",
        "AAVE": "0xD6DF932A45C0f255f85145f286eA0b292B21C90B",
        "COMP": "0x8505b9d2254A7Ae468c0E9dd10Ccea3A837aef5c",
        "USDT": "0xc2132D05D31c914a87C6611C10748AEb04B58e8F",
        "GUSD": "0xC8A94a3d3D2dabC3C1CaffFFDcA6A7543c3e3e65",
        "HUSD": "0x2088C47Fc0c78356c622F79dBa4CbE1cCfA84A91",
        "BUSD": "0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39",
        "WMATIC": "0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270",
        "stMATIC": "0x3A58a54C066FdC0f2D55FC9C89F0415C92eBf3C4",
        "MATICX": "0xfa68FB4628DFF1028CFEc22b4162FCcd0d45efb6",
        "PGYD": "0x37b8E1152fB90A867F3dccA6e8d537681B04705E",
        "TVaDAIv2": "0x15e86Be6084C6A5a8c17732D398dFbC2Ec574CEC",
    },
    42161: {
        "rETH": "0xEC70Dcb4A1EFa46b8F2D97C310C9c4790ba5ffA8",
        "wstETH": "0x5979D7b546E38E414F7E9822514be443A4800529",
        "USDC": "0xaf88d065e77c8cC2239327C5EDb3A432268e5831",
        "USDT": "0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9",
    },
    1101: {
        "WETH": "0x4F9A0e7FD2Bf6067db6994CF12E4495Df938E6e9",
        "wETH": "0x4F9A0e7FD2Bf6067db6994CF12E4495Df938E6e9",
        "rETH": "0xb23C20EFcE6e24Acca0Cef9B7B7aA196b84EC942",
    },
}

# For testing. map.json should in principle work, too, but Steffen doesn't trust it sorry.
TEST_CONST_RATE_PROVIDER_POLYGON = "0xC707205b3cFf2df873811F19f789648286AbB85e"
