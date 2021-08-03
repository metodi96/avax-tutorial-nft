// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import './Collectible.sol';

contract Marketplace is Collectible {

    using SafeMath for uint256;

    struct Listing {
        uint256 tokenId;
        uint256 price;
        address owner;
    }

    mapping (uint256 => Listing) public tokenIdToListing;
    mapping (uint256 => bool) public hasBeenListed;

    // Mapping used for listing when the owner transfers the token to the contract and would then wish to cancel the listing
    mapping (uint256 => address) public claimableByAccount;

    /**
     * @dev Emitted when a `tokenId` has been listed for a `price` by a `seller`
    */
    event ItemListed(
        uint256 tokenId,
        uint256 price, 
        address seller
    );

    /**
     * @dev Emitted when a `tokenId` listing for a `price` has been cancelled by a `seller`
    */
    event ListingCancelled(
        uint256 tokenId,
        uint256 price, 
        address seller
    );

    /**
     * @dev Emitted when a `tokenId` has been bought for a `price` by a `buyer`
    */
    event ItemBought(
        uint256 tokenId,
        uint256 price,
        address buyer
    );

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


    function listItem(
        uint256 tokenId, 
        uint256 price
    ) public onlyTokenOwner(tokenId) {
        require(!hasBeenListed[tokenId], "The token can only be listed once");

         //send the token to the smart contract
        _transfer(msg.sender, address(this), tokenId);
        claimableByAccount[tokenId] = msg.sender;

        tokenIdToListing[tokenId] = Listing(
            tokenId,
            price,
            msg.sender
        );

        hasBeenListed[tokenId] = true;
        emit ItemListed(
            tokenId,
            price,
            msg.sender
        );
    }

    function cancelListing(uint256 tokenId) public onlyListingAccount(tokenId) {
        //send the token from the smart contract back to the one who listed it
        _transfer(address(this), msg.sender, tokenId);
        uint256 price = tokenIdToListing[tokenId].price;

        delete claimableByAccount[tokenId];
        delete tokenIdToListing[tokenId];
        hasBeenListed[tokenId] = false;

        emit ListingCancelled(
            tokenId,
            price,
            msg.sender
        );
    }

    function buyItem(uint256 tokenId) public payable {
        require(hasBeenListed[tokenId], "The token needs to be listed in order to be bought!");
        require(tokenIdToListing[tokenId].price == msg.value, "You need to pay the price.");

        //split up the value for owner and for creator

        uint256 royaltyForCreator = tokenIdToItem[tokenId].royalty.mul(msg.value).div(100);
        uint256 remainder = msg.value.sub(royaltyForCreator);

        //send to creator
        (bool sentRoyalty, ) = tokenIdToItem[tokenId].creator.call{value: royaltyForCreator}("");
        require(sentRoyalty, "Failed to send AVAX");

        //send to owner
        (bool sentRemainder, ) = tokenIdToItem[tokenId].owner.call{value: remainder}("");
        require(sentRemainder, "Failed to send AVAX");

        //transfer the token from the smart contract back to the buyer
        _transfer(address(this), msg.sender, tokenId);

        delete tokenIdToListing[tokenId];
        hasBeenListed[tokenId] = false;

        emit ItemBought(
            tokenId,
            msg.value,
            msg.sender
        );
    }

}