
<h3 align="center">Protocol Integration</h3>

  <p align="center">
    A collection of minimal contracts facilitating integration with Web3 protocols
    <br />
  </p>

<p align="center">
  <img src="https://img.shields.io/badge/Solidity-e6e6e6?style=for-the-badge&logo=solidity&logoColor=black" alt="Solidity"/>
  <img src="https://camo.githubusercontent.com/8c47fd6bf4ac8eec4be8caefd7d56b8cdbff9de4985b76e3ff3ab1497d7363e8/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f466f756e6472792d677265793f7374796c653d666c6174266c6f676f3d646174613a696d6167652f706e673b6261736536342c6956424f5277304b47676f414141414e53556845556741414142514141414155434159414141434e6952304e414141456c456c45515652346e483156555568556152673939383459647a42706b7152305a3231307249455349585361624562634867796472704e52526a30306b57617a746a3055314d4f57304d4f49624433303049764c4d7142704d54475978646f71796f524e4455455342445777557550756743535373544d3775304f6a312f2b656664694d636d6e50322f66446437374434662f4f4236784361327572515a626c6c56494359477471616e4b31744c53344164674179414167797a4a615731734e712f756c543474774f4777346650697741474470374f77385656316437625661725257785743772f6b386d67736245786d30776d5a2b4c782b4d2f5872312f2f4363417353566d534a4830314d634c68734145416e45356e782b546b35422f78654a784f70354e39665832737171716978574c686e5474333648413447497646474931475533563164663550652f394431743765486b676b45757a6f3647425054343957576c6f713748613766756a5149546f6344753761745573336d38336936745772326f6b544a2f6a6978517565506e3236357a5053634468736b47555a652f6675625876382b44467633727970626469775161786274343652534954373975336a304e415162393236525656564f54342b5471765679767a38664430594443354e546b3679736248786c43524a2f354b536c41415552794b5254464e546b7741673774363953352f507837362b50713747794d6749392b2f667a394852555149514f336273454b4f6a6f333844734a43554a4144772b2f3042565657376f74486f387073336234797658723343784d514554435954544359544e453044414f546c3553475879304652464f7a5a7377646d73786b564652584c4e545531786d67302b6b4e76622b2f3341474163474269493739363957776367367572712b4f544a4539363764343962746d7a68395054305233574a52494b4251494442594a425455314e73614767674147477a32665465337435664165515a415777754c69347550336e79704f5431656d457747464265586f3761326c6f734c4379676f6145422f6633394d4a6c4d434956436b43514a42773865684e56716863666a51584e7a7331525355694b7458372b2b4445415a71717171334b465169414259554644414d32664f6b4351584678644a6b766676333264685953473958692b765862764732646e5a6a346f446751434c696f716f4b417148686f626f6444712f4d63374e7a556b6c4a535549426f4f7732577a59746d30626c7065587357624e476b784d544f44703036646f61327644344f41674e6d37634349764641704c516452336e7a7033447a70303738664c6c537851564665486475336341674970486a7836392f7a425558356b2b4d4442417439764e5938654f736275376d366c556967634f484b444c3557496d6b79484a7a39544759724563414c734d49506e363965735a54644d49674d2b6550554e58567864753337364e73724979754e3175584c70304357617a476350447733433558464256465766506e6b564e5451313850702b657a5759354d7a507a4f344466414142486a687a704a736c554b71566476486952342b506a624739765a79365849306b754c5330786d55785343454753395076394c4330747064466f5a47566c705361456f4d2f6e757749414b782f37713547526b6239436f5a42515656576350332b657a35382f4a306d6d30326b4f44673779776f554c6a4d5669544b6654744e7674584c74324c5464743271546e63726e6c736247784c49437653557166726c35484a424c68314e54556b6842434a386d4668515832392f6454565655574642547777594d48314857646c7939667071496f65694b52574a71666e3264316458576e4c4d7566377a4d41484431367447642b666e37465a7932627a59724b796b6f644141465156565639635846526b4e5465766e334c75626b357472533058506e6678484534484e384f44772b6e562f79616e70366d782b4f68782b503561494d51676d4e6a59332f5731745a2b74357273537747372b666a78342f37362b76726d3764753332776f4c433030416b45366e3338666a385a6d4844782f2b637550476a5238424a4c3859734374596451494d414c5971696c4b764b456f394150754874792b656748384133476646444a586d786d4d41414141415355564f524b3543594949253344266c696e6b3d6874747073253341253246253246626f6f6b2e676574666f756e6472792e7368253246" alt="Foundry"/>
  <img src="https://img.shields.io/badge/license-MIT-blue" alt="MIT"/>
</p>

# About The Project

## Project Description

This project highlights minimalized protocol integration contracts that facilitate interactions with Web3 protocols, using [RocketPool's](https://rocketpool.net) rETH as an example token. It showcases "shortcuts" for common DeFi operations:

* **[Adding liquidity](src/liquidity/)**
    * Allows user to add liquidity to [Balancer](https://balancer.fi) protocol directly or through [Aura](https://aura.finance)
* **[Flash loans](src/flash-loans/)**
    * Open and close leveraged positions with [Aave](https://aave.com) flash loans
* **[Getting asset price](src/price-pools/)**
    * Get the rETH/ETH exchange rate using [RocketPool]() of [Chainlink Price Feeds](https://docs.chain.link/data-feeds/price-feeds)
    * Using Chainlink price feeds in a complex protocol: **[Decentralized Stable Coin](https://github.com/mlbyvn/DSC)**
* **[Restaking](src/restake/)**
    * Provides functionality to stake and delegate staking on [EigenLayer](https://www.eigenlayer.xyz)
* **[Swapping](src/swapping/)**
    * Swap rETH using [Balancer](https://balancer.fi), [RocketPool](https://rocketpool.net) or [Uniswap V3](https://blog.uniswap.org/uniswap-v3)
* **[VRF](src/vrf)**
    * Request and handle randomness from [Gelato VRF](https://docs.gelato.network/web3-services/vrf/quick-start)
    * Using [Chainlink VRF](https://docs.chain.link/vrf) in a complex protocol: **[F3BlackJack](https://github.com/mlbyvn/blackjack)**

<p align="right">(<a href="#readme-top">back to top</a>)</p>


## Project Structure
```
src
├── aave                                  # Aave helper contracts
├── interfaces                            # Interfaces for protocols and tokens
├── flash-loans      
│   └── AaveLeverage.sol                  # Leveraging with Aave flash loans
├── liquidity
│   ├── AuraLiquidity.sol                 # Provide liquidity in Aura
│   └── BalancerLiquidity.sol             # Provide liquidity in Balancer
├── price-pools      
│   └── ChainlinkPricePool.sol            # Chainlink and RocketPool price oracles
├── restake
│   └── EigenLayerRestake.sol             # EigenLayer restaking 
├── swapping
│   ├── BalancerV2Swap.sol                # Swap on Balancer
│   ├── RocketPoolSwap.sol                # Swap on RocketPool
│   └── UniswapV3Swap.sol                 # Swap on Uniswap v3
├── vrf      
│   └── GelatoVrfMinimal                  # Request randomness from Gelato VRF
├── Util.sol                              # Utils
└──README.md                              # Project documentation
```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

# License

*Distributed under the MIT license.*

<p align="right">(<a href="#readme-top">back to top</a>)</p>

# Contact

*Flopcatcher* - flopcatcher.audit@gmail.com

<p align="right">(<a href="#readme-top">back to top</a>)</p>

# Disclaimer

*This codebase has not undergone a proper security review and is therefore not suitable for production.*


<p align="right">(<a href="#readme-top">back to top</a>)</p>
