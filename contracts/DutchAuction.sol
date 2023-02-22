//SPDX-License-Identifier:MIT
pragma solidity ^0.8.17;

interface IERC721 {
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
}

contract DucthAuction {
    uint private constant DURATION = 7 days;

    IERC721 public immutable nftContract;
    uint public immutable nftId;

    address payable public immutable seller;
    uint public immutable startingPrice;
    uint public immutable startAuctionAt;
    uint public immutable endAuctionAt;
    uint public immutable discountRate;

    constructor(uint _startingPrice, uint _discountRate, address _nftContract, uint _nftId) {
        seller = payable(msg.sender);
        startingPrice = _startingPrice;
        discountRate = _discountRate;
        startAuctionAt = block.timestamp;
        endAuctionAt = block.timestamp + DURATION;

        require(_startingPrice >= _discountRate * DURATION, "Starting price is less than Discount");

        nftContract = IERC721(_nftContract);
        nftId = _nftId;
    }

    //Calculating Discount rate
    function getPrice() public view returns (uint) {
        uint timeElasped = block.timestamp - startAuctionAt;
        uint discount = discountRate * timeElasped;
        return startingPrice - discount;
    }

    //Fucntion to buy NFT
    function buyNFt() external payable {
        require(block.timestamp < endAuctionAt, "Auction ends");

        uint price = getPrice();
        require(msg.value > price, "ETH < current price");

        nftContract.transferFrom(seller, msg.sender, nftId);

        uint refund = msg.value - price;
        if (refund > 0) {
            (bool success, ) = msg.sender.call{value: refund}("");
            require(success, "Transaction Failed");
        }

        selfdestruct(seller);
    }
}
