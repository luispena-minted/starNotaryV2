// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//Importing openzeppelin-solidity ERC-721 implemented Standard
import "../node_modules/openzeppelin-solidity/contracts/token/ERC721/ERC721.sol";

// StarNotary Contract declaration inheritance the ERC721 openzeppelin implementation
contract StarNotary is ERC721 {

    // Star data
    struct Star {
        string name;
    }

    struct TokenExchange {
        uint256 exChangeWithToken;
        address otherPartyOwner;

    }

    // mapping the Star with the Owner Address
    mapping(uint256 => Star) public tokenIdToStarInfo;
    // mapping the TokenId and price
    mapping(uint256 => uint256) public starsForSale;

    // mapping of tokenId to exchange vs TokenExchange
    mapping(uint256 => TokenExchange) public tokenExchangeInfo;


    // Implement Task 1 Add a name and symbol properties
    // name: Is a short name to your token
    // symbol: Is a short string like 'USD' -> 'American Dollar'
    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {
    }

    // Create Star using the Struct
    function createStar(string memory _name, uint256 _tokenId) public {
        // Passing the name and tokenId as a parameters
        Star memory newStar = Star(_name);
        // Star is an struct so we are creating a new Star
        tokenIdToStarInfo[_tokenId] = newStar;
        // Creating in memory the Star -> tokenId mapping
        _mint(msg.sender, _tokenId);
        // _mint assign the the star with _tokenId to the sender address (ownership)
    }

    // Putting an Star for sale (Adding the star tokenid into the mapping starsForSale, first verify that the sender is the owner)
    function putStarUpForSale(uint256 _tokenId, uint256 _price) public {
        require(ownerOf(_tokenId) == msg.sender, "You can't sale the Star you don't owned");
        starsForSale[_tokenId] = _price;
    }


    // Function that allows you to convert an address into a payable address
    function _make_payable(address x) internal pure returns (address payable) {
        address payable addrss = payable(x);
        return addrss;
    }

    function buyStar(uint256 _tokenId) public payable {
        require(starsForSale[_tokenId] > 0, "The Star should be up for sale");
        uint256 starCost = starsForSale[_tokenId];
        address ownerAddress = ownerOf(_tokenId);
        require(ownerAddress != msg.sender, "You cant buy a Star you own");
        require(msg.value > starCost, "You need to have enough Ether");
        //prevent approval check
        _transfer(ownerAddress, msg.sender, _tokenId);
        // We can't use _addTokenTo or_removeTokenFrom functions, now we have to use _transferFrom
        address payable ownerAddressPayable = _make_payable(ownerAddress);
        // We need to make this conversion to be able to use transfer() function to transfer ethers
        ownerAddressPayable.transfer(starCost);
        if (msg.value > starCost) {
            address payable senderAddress = _make_payable(msg.sender);
            senderAddress.transfer(msg.value - starCost);
        }
    }

    // Implement Task 1 lookUptokenIdToStarInfo
    function lookUptokenIdToStarInfo(uint _tokenId) public view returns (string memory) {
        Star memory info = tokenIdToStarInfo[_tokenId];
        if (bytes(info.name).length == 0) {
            revert("Token ID non existing");
        }
        return info.name;
    }

    // Implement Task 1 Exchange Stars function
    // The stars are successfully exchanged when the 2 parties execute the exchangeStars transaction
    function exchangeStars(uint256 _tokenId1, uint256 _tokenId2) public {
        //1. Passing to star tokenId you will need to check if the owner of _tokenId1 or _tokenId2 is the sender
        //2. You don't have to check for the price of the token (star)
        //3. Get the owner of the two tokens (ownerOf(_tokenId1), ownerOf(_tokenId2)
        //4. Use _transferFrom function to exchange the tokens.
        address ownerOf1 = ownerOf(_tokenId1);
        address ownerOf2 = ownerOf(_tokenId2);

        uint256 senderToken;
        uint256 otherPartyToken;
        address otherPartyAddress;

        if (msg.sender == ownerOf1 && msg.sender == ownerOf2) {
            revert("You cant exchange 2 tokens you already own");
        } else if (msg.sender == ownerOf1) {
            senderToken = _tokenId1;
            otherPartyToken = _tokenId2;
            otherPartyAddress = ownerOf2;
        } else if (msg.sender == ownerOf2) {
            senderToken = _tokenId2;
            otherPartyToken = _tokenId1;
            otherPartyAddress = ownerOf1;
        } else {
            revert("Sender dont own any of this tokens");
        }

        TokenExchange memory exChangeInfo1 = tokenExchangeInfo[_tokenId1];
        TokenExchange  memory exChangeInfo2 = tokenExchangeInfo[_tokenId2];

        // check if there is no info of this exchange, if not, then add the info to exchangeStars
        if (exChangeInfo1.exChangeWithToken == 0 && exChangeInfo2.exChangeWithToken == 0) {
            TokenExchange memory exChangeInfo = TokenExchange({
            exChangeWithToken : otherPartyToken,
            otherPartyOwner : otherPartyAddress
            });
            tokenExchangeInfo[senderToken] = exChangeInfo;
            // approve other party to transferStar
            approve(otherPartyAddress, senderToken);
            return;
        }
        // if there is information about this exchange, get the information
        TokenExchange memory exChangeInfo = exChangeInfo1.exChangeWithToken != 0 ? exChangeInfo1 : exChangeInfo2;
        // if the sender of the token is the third party, go ahead and exchange the tokens
        if (exChangeInfo.otherPartyOwner == msg.sender && exChangeInfo.exChangeWithToken == senderToken) {
            transferStar(otherPartyAddress, senderToken);
            transferFrom(otherPartyAddress, msg.sender, otherPartyToken);
        } else if (exChangeInfo.otherPartyOwner != msg.sender) {
            //in case the owner of the token that the info was mapped to
            //wants to exchange the token with another token, rewrite the info
            TokenExchange  memory exChangeInfo = TokenExchange({
            exChangeWithToken : otherPartyToken,
            otherPartyOwner : otherPartyAddress
            });
            tokenExchangeInfo[senderToken] = exChangeInfo;
            // clear previous approval
            _approve(exChangeInfo.otherPartyOwner, 0);
            // approve other party to transferStar
            approve(otherPartyAddress, senderToken);
        } else {
            revert("This operation is not allowed");
        }
    }

    // Implement Task 1 Transfer Stars
    function transferStar(address _to1, uint256 _tokenId) public {
        //1. Check if the sender is the ownerOf(_tokenId)
        //2. Use the transferFrom(from, to, tokenId); function to transfer the Star
        require(_isApprovedOrOwner(_msgSender(), _tokenId), "ERC721: transfer caller is not owner nor approved");
        transferFrom(msg.sender, _to1, _tokenId);
    }

}
