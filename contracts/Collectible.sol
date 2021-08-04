// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Collectible is ERC721URIStorage {
    // Mapping to check if the metadata has been minted
    mapping(string => bool) public hasBeenMinted;

    // Mapping to keep track of the Item
    mapping(uint256 => Item) public tokenIdToItem;

    // A struct for the collectible item containing info about `owner`, `creator` and the `royalty`
    struct Item {
        address owner;
        address creator;
        uint256 royalty;
    }

    Item[] private items;

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
            "This metadata has already been used to mint an NFT!"
        );
        require(
            royalty >= 0 && royalty <= 40,
            "Royalties must be between 0% and 40%"
        );

        uint256 newItemId = items.length;

        items.push(Item(msg.sender, msg.sender, royalty));

        _safeMint(msg.sender, newItemId);
        _setTokenURI(newItemId, metadata);

        hasBeenMinted[metadata] = true;

        return newItemId;
    }

    /**
     * @dev return the length of the items array
     */
    function getItemsLength() public view returns (uint256) {
        return items.length;
    }

    /**
     * @dev return an item with an `index` from the items array
     */
    function getItem(uint256 index) public view returns (address, address, uint256)
    {
        return (items[index].owner, items[index].creator, items[index].royalty);
    }
}
