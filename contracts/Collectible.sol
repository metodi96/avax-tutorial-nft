// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Collectible is ERC721URIStorage, Ownable {
    using SafeMath for uint256;

    // Mapping to check if the metadata has been minted
    mapping (string => bool) public hasBeenMinted;
    mapping (uint256 => Item) public tokenIdToItem;

    struct Item {
        address owner;
        address creator;
        uint256 royalty;
    }

    Item[] public items;

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
    function createCollectible(
        string memory metadata,
        uint256 royalty
    ) public returns (uint256) {
        require(
            !hasBeenMinted[metadata],
            "This metadata has already been used to mint an NFT!"
        );
        require(
            royalty >= 0 && royalty <= 40, "Royalties must be between 0% and 40%"
        );

        uint256 newItemId = items.length;

        items.push(
            Item(
                msg.sender,
                msg.sender,
                royalty
            )
        );

        _safeMint(msg.sender, newItemId);
        _setTokenURI(newItemId, metadata);

        return newItemId;
    }
}