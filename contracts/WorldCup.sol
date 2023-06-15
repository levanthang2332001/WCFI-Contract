// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract WorldCup is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Address for address;
    using SafeMath for uint256;
    Counters.Counter private _currentTokenId ;

    uint256 public constant TOTAL_TIERS = 4;
    uint256 public constant FIRST_THREE_MINTS = 3;
    uint256 public constant COST = 100000000000000 wei;

    mapping(address => uint256) public _mintCount;

    bool public isPaused = false;

    struct NFT {
        string name;
        uint256 rarity;
    }

    struct Tier {
        NFT[] nfts;
        uint256 totalRarity;
    }

    struct Metadata {
        string name;
        string description;
        string traits;
    }

    mapping(uint256 => Metadata) private _metadata;

    Tier[4] public tiers;

    event Mint(
        uint256 _date,
        address indexed _from,
        address indexed _to,
        uint256 indexed _tokenId
    );
    event Transfer(
        uint256 _date,
        address indexed _from,
        address indexed _to,
        uint256 indexed _tokenId
    );
    event ApprovalForAllNft(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    event Withdraw(
        address indexed account, 
        uint256 amount
    );

    constructor() ERC721("WorldCup", "WC") {
        // Tier 1
        tiers[0].nfts.push(NFT("Brazil", 8));
        tiers[0].nfts.push(NFT("France", 10));
        tiers[0].nfts.push(NFT("England", 11));
        tiers[0].nfts.push(NFT("Spain", 14));
        tiers[0].nfts.push(NFT("Germany", 19));
        tiers[0].nfts.push(NFT("Argentina", 19));
        tiers[0].nfts.push(NFT("Belgium", 22));
        tiers[0].nfts.push(NFT("Portugal", 22));
        tiers[0].totalRarity = 125;

        // Tier 2
        tiers[1].nfts.push(NFT("Netherlands", 26));
        tiers[1].nfts.push(NFT("Denmark", 52));
        tiers[1].nfts.push(NFT("Croatia", 65));
        tiers[1].nfts.push(NFT("Uruguay", 93));
        tiers[1].nfts.push(NFT("Poland", 121));
        tiers[1].nfts.push(NFT("Senegal", 121));
        tiers[1].nfts.push(NFT("United States", 149));
        tiers[1].nfts.push(NFT("Serbia", 149));
        tiers[1].totalRarity = 776;

        // Tier 3
        tiers[2].nfts.push(NFT("Switzerland", 149));
        tiers[2].nfts.push(NFT("Mexico", 186));
        tiers[2].nfts.push(NFT("Wales", 186));
        tiers[2].nfts.push(NFT("Ghana", 280));
        tiers[2].nfts.push(NFT("Ecuador", 280));
        tiers[2].nfts.push(NFT("Morocco", 373));
        tiers[2].nfts.push(NFT("Cameroon", 466));
        tiers[2].nfts.push(NFT("Canada", 466));
        tiers[2].totalRarity = 2386;

        // Tier 4
        tiers[3].nfts.push(NFT("Japan", 466));
        tiers[3].nfts.push(NFT("Qatar", 466));
        tiers[3].nfts.push(NFT("Tunisia", 559));
        tiers[3].nfts.push(NFT("South Korea", 746));
        tiers[3].nfts.push(NFT("Australia", 746));
        tiers[3].nfts.push(NFT("Iran", 932));
        tiers[3].nfts.push(NFT("Saudi Arabia", 932));
        tiers[3].nfts.push(NFT("Costa Rica", 1864));
        tiers[3].totalRarity = 6711;
    }

    function pause() public onlyOwner {
        isPaused = !isPaused;
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override
    {
        require(msg.sender != operator, "ERC721: Approve to caller");
        super.setApprovalForAll(operator, approved);
        emit ApprovalForAllNft(msg.sender, operator, approved);
    }


    function safeMint() public payable {
        require(!isPaused, "Mint paused");
        if (msg.sender != owner()) {
            require(msg.value >= COST, "Insufficient funds to mint tokens");
        }
        
        uint256 tokenId = _currentTokenId.current().add(1);
        string memory country = checkRandomNft();
        _metadata[tokenId] = Metadata("Shoes","World cup 2020", country);
        _safeMint(msg.sender, tokenId);
      
        _currentTokenId.increment();
        _mintCount[msg.sender]++;
        emit Mint(block.timestamp, address(0), msg.sender, tokenId);
    }

    function checkRandomNft() public view returns(string memory) {
        uint256 tierIdx = _getRandomTier();
        uint256 nftIdx = _getRandomNFT(tierIdx);

        return tiers[tierIdx].nfts[nftIdx].name;
    }

   function checkValueRandom(uint256 value) public view returns(uint256) {
       uint256 randomValue = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, _currentTokenId.current()))) % value;
       return randomValue;
    }


    function _getRandomTier() internal view returns(uint256) {
        uint256 limit;

        if (_mintCount[msg.sender] < FIRST_THREE_MINTS) {
            limit = TOTAL_TIERS;
        } else {
            limit = 2;
        }
        uint256 randomValue = checkValueRandom(limit);
        return randomValue;
    }


    function _getRandomNFT(uint256 tierIndex) private view returns (uint256) {
        uint256 totalRarity = 0;

        if (_mintCount[msg.sender] >= FIRST_THREE_MINTS && tierIndex < 2) {
            totalRarity = tiers[tierIndex].nfts.length;
        } else {
            for (uint256 i = 0; i < tiers[tierIndex].nfts.length; i++) {
                totalRarity += tiers[tierIndex].nfts[i].rarity;
            }
        }

        uint256 randomValue = checkValueRandom(totalRarity);
        for (uint256 i = 0; i < tiers[tierIndex].nfts.length; i++) {
            uint256 currentRarity = (_mintCount[msg.sender] >= FIRST_THREE_MINTS && tierIndex < 2) ? 1 : tiers[tierIndex].nfts[i].rarity;
            
            if (randomValue < currentRarity) {
                return i;
            }
            randomValue -= currentRarity;
        }

        return tiers[tierIndex].nfts.length - 1;
    }

    function withdrawAll() external onlyOwner {
        require(address(this).balance > 0, "Contract balance is zero");

        address payable owner = payable(owner());
        bool success = owner.send(address(this).balance);
        require(success, "Withdrawal failed");

        emit Withdraw(owner, address(this).balance);
    }

    function transfer(address _to, uint256 _tokenId) public virtual {
        require(
            _isApprovedOrOwner(msg.sender, _tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        require(_to != address(0), "Cannot transfer to address zero");

        _transfer(msg.sender, _to, _tokenId);
        emit Transfer(block.timestamp, msg.sender, _to, _tokenId);
    }

    function checkOwnerOfNFT(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "Token does not exist");
        return ownerOf(tokenId);
    }

    function checkTotalOwerMint() external view returns (uint256) {
        return _mintCount[msg.sender];
    }


    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        require(_exists(tokenId), "Token does not exist");
        Metadata memory nft = _metadata[tokenId];

        string memory data = string(
            abi.encodePacked(
                '{"name":"',
                nft.name,
                '","description":"',
                nft.description,
                '","traits":"',
                nft.traits,
                '"}'
            )
        );
        return data;
    }
}
