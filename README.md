# Avalanche Developer ERC721 Tutorial 

## Introduction

In this tutorial you will get the chance to get familiar with ERC721 smart contracts and how to deploy these to the Avalanche Fuji testnet and also the Avalanche mainnet (C-Chain). The goal of this tutorial is to be as beginner friendly as possible. I will go through each line of code in order to give you a full understanding of what is happening, so that you can use the concepts as a basis for your first NFT decentralized application. The plan is to showcase:

1. How to create an ERC721 smart contract, so that you can mint your own ERC721 NFT on Avalanche using Open Zeppelin and the Truffle framework;
2. How to extend the contract, so each token has royalties;
3. How to create your own NFT marketplace where you can list your items, cancel listings and purchase other NFTs;
4. How to extensively test your smart contracts using Truffle's built in Mocha.js library and Open Zeppelin's Test Helper assertion library achieving 100% code coverage;

## Step 1: Creating an ERC721 smart contract using Truffle and Open Zeppelin
For this tutorial I have used [Visual Studio Code](https://code.visualstudio.com/) as my code editor but you can used any code editor you'd like. I recommend to install the **solidity** extension by Juan Blanco to get that nice Syntax highlighting along with some code snippets should you go for Visual Studio Code. You would also need to create a MetaMask wallet or whatever similar provider you are comfortable with.

### Dependencies
* [NodeJS v8.9.4 or later](https://nodejs.org/en/).
* Truffle, which you can install with npm install -g truffle
* (Optional) [Avash](https://github.com/ava-labs/avash) is a tool for running a local Avalanche network. It's similar to Truffle's [Ganache](https://www.trufflesuite.com/ganache).

### Setting up a Truffle project

1. Create a project directory and inside of it run the commands:
```powershell
truffle init -y
npm init -y
```

2. The first one will provide you with a base structure of a Truffle project and the second one will include a **package.json** file to keep track of the dependencies.
Afterwards, include the following dependencies which will help us building and testing the smart contracts.
```powershell
npm install @openzeppelin/contracts @truffle/hdwallet-provider dotenv
npm install --save-dev @openzeppelin/test-helpers solidity-coverage
```
* The [@openzeppelin/contracts](https://github.com/OpenZeppelin/openzeppelin-contracts) is a library for a secure smart contract development. We inherit from their ERC721 smart contract;
* The [@truffle/hdwallet-provider](https://www.npmjs.com/package/@truffle/hdwallet-provider) is used to sign transactions for addresses derived from a 12 or 24 word mnemonic. In our case we will create a MetaMask wallet and provide the mnemonic from there to deploy to the Avalanche Fuji testnet;
* The [dotenv](https://www.npmjs.com/package/dotenv) is a zero-dependency module that loads environment variables from a .env file into process.env. We do not want to leak our mnemonic to other people after all;
* The [@openzeppelin/test-helpers](https://docs.openzeppelin.com/test-helpers/0.5/) is a library that will helps us test when transactions revert and also handle Big Numbers for us. It is a dev dependency;
* The [solidity-coverage](https://www.npmjs.com/package/solidity-coverage) is a library that we will use to check how much coverage our tests have;

3. Now that we have all the necessary dependencies installed, let us go to the **truffle-config.js** in the root of our project and paste the following lines of code in there:

```javascript
const HDWalletProvider = require('@truffle/hdwallet-provider')
require('dotenv').config()
module.exports = {
  networks: {
    fuji: {
      provider: () => {
        return new HDWalletProvider({
          mnemonic: process.env.MNEMONIC,
          providerOrUrl: `https://avalanche--fuji--rpc.datahub.figment.io/apikey/${process.env.APIKEY}/ext/bc/C/rpc`,
          chainId: '43113'
        })
      },
      network_id: "*",
      gasPrice: 225000000000
    },
    mainnet: {
      provider: () => {
        return new HDWalletProvider({
          mnemonic: process.env.MNEMONIC,
          providerOrUrl: `https://api.avax.network/ext/bc/C/rpc`,
          chainId: '43114',
        })
      },
      network_id: "*",
      gasPrice: 225000000000
    }
  },
  compilers: {
    solc: {
      version: "0.8.6"
    }
  },
  plugins: ["solidity-coverage"]
};
```

This file is the entrypoint of our Truffle project. As you can see, we specify two networks on which we would like to deploy our smart contracts after we are done with them, namely *fuji* and *mainnet*. We utilize the [@truffle/hdwallet-provider](https://www.npmjs.com/package/@truffle/hdwallet-provider) library, so that we provide a RPC to which we can connect to to deploy our contracts as well as a mnemonic which will be used to sign the transaction to do that. As you can see, some of the variables are accessed via process.env. These are defined in a separate **.env** file in the root of our project and have the following structure:
```
MNEMONIC='paste your metamask mnemonic here which is twelve words long believe me'
APIKEY=YOUR_DATAHUB_API_KEY_FOR_THE_FUJI_TESTNET
```
Note: For the Fuji testnet I used [DataHub](https://datahub.figment.io/services/avalanche)'s testnet RPC. There is a free plan which you can use. For that you would need to register, grab your APIKEY and paste it into your **.env** file. 

### Writing our first ERC721 contract

1. Inside the **contracts/** folder of your Truffle project create a new Collectible.sol file and paste in the following code:

```javascript
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Collectible is ERC721URIStorage {
    using SafeMath for uint256;

    // Mapping to check if the metadata has been minted
    mapping(string => bool) public hasBeenMinted;

    // Mapping to keep track of the Item
    mapping(uint256 => Item) public tokenIdToItem;

    // A struct for the collectible item containing info about `tokenId`, `owner`, `creator` and the `royalty`
    struct Item {
        uint256 tokenId;
        address owner;
        address creator;
        uint256 royalty;
    }

    Item[] private items;

    /**
     * @dev Emitted when a `tokenId` has been bought for a `price` by a `buyer`
    */
    event ItemMinted(uint256 tokenId, address creator, string metadata, uint256 royalty);

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection inheriting from the ERC721 smart contract.
     */
    constructor() ERC721("NFTCollectible", "NFTC") {}

    /**
     * @dev create a collectible with a `metadata` for the msg.sender
     *
     * Requirements:
     * - `metadata` has not been minted before
     * - `royalty` must be between 0% and 40%
     *
     * Emits a {Transfer} event - comes from the ERC-721 smart contract.
     */
    function createCollectible(string memory metadata, uint256 royalty)
        public
        returns (uint256)
    {
        require(
            !hasBeenMinted[metadata],
            "This metadata has already been used to mint an NFT."
        );
        require(
            royalty >= 0 && royalty <= 40,
            "Royalties must be between 0% and 40%"
        );
        uint256 newItemId = items.length.add(1);
        Item memory newItem = Item(newItemId, msg.sender, msg.sender, royalty);
        items.push(newItem);
        _safeMint(msg.sender, newItemId);
        _setTokenURI(newItemId, metadata);
        tokenIdToItem[newItemId] = newItem;
        hasBeenMinted[metadata] = true;
        emit ItemMinted(newItemId, msg.sender, metadata, royalty);
        return newItemId;
    }

    /**
     * @dev return the length of the items array
     */
    function getItemsLength() public view returns (uint256) {
        return items.length;
    }

    /**
     * @dev return an item associated to a provided `tokenId`
     */
    function getItem(uint256 tokenId) public view returns (uint256, address, address, uint256)
    {
        return (tokenIdToItem[tokenId].tokenId, tokenIdToItem[tokenId].owner, tokenIdToItem[tokenId].creator, tokenIdToItem[tokenId].royalty);
    }
}
```

Now that we have this let us start from the top and explain what the smart contract does.

2. Collectible.sol logic

* At the top we define the solidity version. At the time of this tutorial this is the latest Solidity version:

```javascript
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
```

* Next we will import the **ERC721URIStorage.sol** contract from Open Zeppelin. This contract is an extension of their **ERC721.sol** contract which takes metadata of an NFT into account as well. We will also use the popular **SafeMath.sol** library for our mathematical operations. This is a library which prevents unsigned integer overflows: 

```javascript
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
```

* Now that we have done that let us define our **Collectible** contract which will inherit from the **ERC721URIStorage**. This would allow us to use all the functions and access all the public state variables which that contract offers. Pretty cool, right? 
```javascript
contract Collectible is ERC721URIStorage {
```

* Afterwards we will define the state variables and also the constructor of our contract:

```javascript
    mapping(string => bool) public hasBeenMinted;
    mapping(uint256 => Item) public tokenIdToItem;
    struct Item {
        address owner;
        address creator;
        uint256 royalty;
    }
    Item[] private items;
    event ItemMinted(uint256 tokenId, address creator, string metadata, uint256 royalty);
    
    constructor() ERC721("NFTCollectible", "NFTC") {}
```

The main thing to note here is the **Item** struct. We need one to keep track of some extra on-chain data that our NFTs can have. In our case this is the **owner**, the **creator** and the **royalty** which would be a percentage of the price paid out to the **creator** on each purchase of the NFT. 
With each minting a new **Item** will be pushed to the array of items. This array can be then used to display those properties on the frontend, for example.
We define an ItemMinted event due to our custom NFTs which we will emit at the end of our minting function. Last but not least, as you can see, we initialize the ERC721 constructor by providing it a name for our token contract and a symbol. These are the two parameters which it takes. Our constructor does not have any, hence the empty body.
The mappings are used to keep track of information such as whether a metadata hash has been minted, meaning that we prevent the minting of that metadata again and also to map the token id to an **Item**.

* The **createCollectible(string memory metadata, uint256 royalty)** function:

```javascript
function createCollectible(string memory metadata, uint256 royalty) public returns (uint256)
    {
        require(
            !hasBeenMinted[metadata],
            "This metadata has already been used to mint an NFT."
        );
        require(
            royalty >= 0 && royalty <= 40,
            "Royalties must be between 0% and 40%"
        );
        Item memory newItem = Item(msg.sender, msg.sender, royalty);
        items.push(newItem);
        uint256 newItemId = items.length;
        _safeMint(msg.sender, newItemId);
        _setTokenURI(newItemId, metadata);
        tokenIdToItem[newItemId] = newItem;
        hasBeenMinted[metadata] = true;
        emit ItemMinted(newItemId, msg.sender, metadata, royalty);
        return newItemId;
    }
```

The function takes two parameters - metadata and royalty. In the beginning of the function body we see a couple of guard conditions which are used to prevent unwanted transaction execution and to revert the transaction if the conditions are not fulfilled. We use the mapping which we have defined above to check whether the metadata has been minted. We also check whether the royalty is between 0% and 40%. Should we pass these conditions, we can now move on to creating our **Item** with the information we have. 
At this point the creator is both the owner and the creator, so we use msg.sender which is one of Solidity's global variables and denotes the caller of the function. Our third property is the royalty. After we push this **Item** to the array, we make use of the functions which the **ERC721URIStorage.sol** provides us, namely 

*_safeMint(msg.sender, newItemId);*

*_setTokenURI(newItemId, metadata);*

The newItemId is simply the length of the array before 
This will do the minting for us and associate the item id (token id) with the metadata which we have provided. At the end we update the mappings accordingly with the new information and return the token id.

* At the end we define a couple of view functions. These do not cost any gas, since we do not change the state of the blockchain by calling them.

```javascript
    function getItemsLength() public view returns (uint256) {
        return items.length;
    }
    
    function getItem(uint256 tokenId) public view returns (address, address, uint256)
    {
        return (tokenIdToItem[tokenId].owner, tokenIdToItem[tokenId].creator, tokenIdToItem[tokenId].royalty);
    }
}
```

### Creating our NFT Marketplace.sol contract

1. Inside the **contracts/** folder of your Truffle project create a new Marketplace.sol file and paste in the following code:

```javascript
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import './Collectible.sol';

contract Marketplace is Collectible {
    using SafeMath for uint256;

    struct Listing {
        uint256 price;
        address owner;
    }

    // Mapping for a token id to Listing
    mapping (uint256 => Listing) public tokenIdToListing;

    // Mapping to prevent the same item being listed twice
    mapping (uint256 => bool) public hasBeenListed;

    // Mapping used for listing when the owner transfers the token to the contract and would then wish to cancel the listing
    mapping (uint256 => address) public claimableByAccount;

    /**
     * @dev Emitted when a `tokenId` has been listed for a `price` by a `seller`
    */
    event ItemListed(uint256 tokenId, uint256 price, address seller);

    /**
     * @dev Emitted when a `tokenId` listing for a `price` has been cancelled by a `seller`
    */
    event ListingCancelled(uint256 tokenId, uint256 price, address seller);

    /**
     * @dev Emitted when a `tokenId` has been bought for a `price` by a `buyer`
    */
    event ItemBought(uint256 tokenId, uint256 price, address buyer);

    modifier onlyTokenOwner(uint256 tokenId) {
        require(
            msg.sender == ownerOf(tokenId),
            "Only the owner of the token id can call this function."
        );
        _;
    }

    modifier onlyListingAccount(uint256 tokenId) {
        require(
            msg.sender == claimableByAccount[tokenId],
            "Only the address that has listed the token can cancel the listing."
        );
        _;
    }

    /**
     * @dev list an item with a `tokenId` for a `price`
     *
     * Requirements:
     * - Only the owner of the `tokenId` can list the item
     * - The `tokenId` can only be listed once
     *
     * Emits a {Transfer} event - transfer the token to this smart contract.
     * Emits a {ItemListed} event
     */
    function listItem(uint256 tokenId, uint256 price) public onlyTokenOwner(tokenId) {
        require(!hasBeenListed[tokenId], "The token can only be listed once");
        //send the token to the smart contract
        _transfer(msg.sender, address(this), tokenId);
        claimableByAccount[tokenId] = msg.sender;
        tokenIdToListing[tokenId] = Listing(
            price,
            msg.sender
        );
        hasBeenListed[tokenId] = true;
        emit ItemListed(tokenId, price, msg.sender);
    }

    /**
     * @dev Cancel a listing of an item with a `tokenId`
     *
     * Requirements:
     * - Only the account that has listed the `tokenId` can delist it
     *
     * Emits a {Transfer} event - transfer the token from this smart contract to the owner.
     * Emits a {ListingCancelled} event.
     */
    function cancelListing(uint256 tokenId) public onlyListingAccount(tokenId) {
        //send the token from the smart contract back to the one who listed it
        _transfer(address(this), msg.sender, tokenId);
        uint256 price = tokenIdToListing[tokenId].price;
        delete claimableByAccount[tokenId];
        delete tokenIdToListing[tokenId];
        delete hasBeenListed[tokenId];
        emit ListingCancelled(tokenId, price, msg.sender);
    }

    /**
     * @dev Buy an item with a `tokenId` and pay the owner and the creator
     *
     * Requirements:
     * - `tokenId` has to be listed
     * - `price` needs to be the same as the value sent by the caller
     *
     * Emits a {Transfer} event - transfer the item from this smart contract to the buyer.
     * Emits an {ItemBought} event.
     */
    function buyItem(uint256 tokenId) public payable {
        require(hasBeenListed[tokenId], "The token needs to be listed in order to be bought.");
        require(tokenIdToListing[tokenId].price == msg.value, "You need to pay the correct price.");

        //split up the price between owner and creator
        uint256 royaltyForCreator = tokenIdToItem[tokenId].royalty.mul(msg.value).div(100);
        uint256 remainder = msg.value.sub(royaltyForCreator);
        //send to creator
        (bool isRoyaltySent, ) = tokenIdToItem[tokenId].creator.call{value: royaltyForCreator}("");
        require(isRoyaltySent, "Failed to send AVAX");
        //send to owner
        (bool isRemainderSent, ) = tokenIdToItem[tokenId].owner.call{value: remainder}("");
        require(isRemainderSent, "Failed to send AVAX");

        //transfer the token from the smart contract back to the buyer
        _transfer(address(this), msg.sender, tokenId);

        //Modify the owner property of the item to be the buyer
        Collectible.Item storage item = tokenIdToItem[tokenId];
        item.owner = msg.sender;

        //clean up
        delete tokenIdToListing[tokenId];
        delete claimableByAccount[tokenId];
        delete hasBeenListed[tokenId];
        emit ItemBought(tokenId, msg.value, msg.sender);
    }

    /**
     * @dev return a listing of a `tokenId`
     */
    function getListing(uint256 tokenId) public view returns (uint256, address)
    {
        return (tokenIdToListing[tokenId].price, tokenIdToListing[tokenId].owner);
    }

}
```

This might look slighly more complicated but again, I will go through each line of code, so that at the end you can make sense of the logic entirely.

2. Marketplace.sol logic

* At the top we define as usual the solidity version:

```javascript
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
```
* Next we will import our created **Collectible.sol** contract and inherit from it, since we would want to make use of some of the public state variables there: 

```javascript
import './Collectible.sol';

contract Marketplace is Collectible {
    using SafeMath for uint256;
```

Note: You might have noticed that we again use **SafeMath** for the uint256. This is to prevent the overflows that might happen.

* Afterwards we will define the state variables, events and modifiers:

```javascript
    struct Listing {
        uint256 price;
        address owner;
    }
    mapping (uint256 => Listing) public tokenIdToListing;
    mapping (uint256 => bool) public hasBeenListed;
    mapping (uint256 => address) public claimableByAccount;
    event ItemListed(uint256 tokenId, uint256 price, address seller);
    event ListingCancelled(uint256 tokenId, uint256 price, address seller);
    event ItemBought(uint256 tokenId, uint256 price, address buyer);

    modifier onlyTokenOwner(uint256 tokenId) {
        require(
            msg.sender == ownerOf(tokenId),
            "Only the owner of the token id can call this function."
        );
        _;
    }

    modifier onlyListingAccount(uint256 tokenId) {
        require(
            msg.sender == claimableByAccount[tokenId],
            "Only the address that has listed the token can cancel the listing."
        );
        _;
    }
```

You can see that again we have a struct for the Listing of a NFT. We use it to define who has listed a NFT and for what price. We have again some mappings to keep track of vital information such as to which token id a listing belongs to, whether the token id has been listed as we do not want any double listings of the same NFT and also we have a mapping to keep track of the address that can claim the NFT after it has been listed. This is of course the owner of the item. We need this, because you will see in a bit that we transfer the NFT to the smart contract when listing it, thus making the smart contract the new owner. We have some events for the different functions, namely for listing, cancelling a listing and buying an item. The new concepts which you see here are the modifiers. These can be appended as function modifiers to the functions and act exactly the same as the require() statements. They are usually used to prevent writing the same conditions for different functions. In this case we have two modifiers. The first one is used to prevent other addresses from listing a token which they do not own, whereas the second one is used for allowing only the address that has listed the token to cancel the listing.
 
