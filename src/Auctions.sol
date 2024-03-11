// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Auctions {
    address public owner;
    uint constant DURATION = 86400; // 24 hours
    uint constant FEE = 5; 

    struct Auction {
        address payable seller;
        uint startingPrice;
        uint finalPrice;
        uint startAt;
        uint endsAt;
        string item;
        bool stopped;
    }
    
    struct Bid {
        address bidder;
        uint amount;
    }

    mapping(string => Auction) public auctions;
    mapping(string => Bid) public currentBids;

    modifier onlySeller(string memory _item) {
        require(msg.sender == auctions[_item].seller, "Only the seller can perform this action");
        _;
    }
    
    event AuctionStarted(string item, uint startingPrice, uint duration);
    event BidPlaced(string item, address bidder, uint amount);
    event AuctionEnded(string item, address winner, uint amount);

    constructor() {
        owner = msg.sender;
    }

    function createAuction(uint _startingPrice, string memory _item, uint _duration) external {
        require(_startingPrice >= 0);

        uint duration = _duration == 0 ? DURATION : _duration;
        
        auctions[_item] = Auction({
            seller: payable(msg.sender),
            startingPrice: _startingPrice,
            finalPrice: _startingPrice,
            startAt: block.timestamp,
            endsAt: block.timestamp + duration,
            item: _item,
            stopped: false
        });

        emit AuctionStarted(_item, _startingPrice, duration);
    }

    function placeBid(string memory _item) external payable {
        require(!auctions[_item].stopped, "Auction is stopped!");
        require(block.timestamp < auctions[_item].endsAt, "Auction  ended!");
        require(msg.value > currentBids[_item].amount, "Bid amount less than current highest bid");

        payable(currentBids[_item].bidder).transfer(currentBids[_item].amount);

        currentBids[_item] = Bid({
            bidder: msg.sender,
            amount: msg.value
        });

        emit BidPlaced(_item, msg.sender, msg.value);
    }

    function endAuction(string memory _item) external onlySeller(_item) {
        require(block.timestamp >= auctions[_item].endsAt, "Auction is ongoing!");
        require(!auctions[_item].stopped, "Auction is stopped!");

        auctions[_item].stopped = true;

        uint amount = auctions[_item].finalPrice;

        if (block.timestamp < auctions[_item].endsAt) {
            amount = amount * (100 - FEE) / 100;
        }

        auctions[_item].seller.transfer(amount);
        emit AuctionEnded(_item, currentBids[_item].bidder, amount);
    }
}
