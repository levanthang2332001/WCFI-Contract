// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract MyToken is ERC721 , Ownable {
    using Counters for Counters.Counter;
    using Address for address;
    Counters.Counter private _tokenIdCounter;

    uint256 public mintPrice = 0.00001 ether;
    string public baseURI = "ipfs://image/";

    event Mint(uint _date, address indexed _from, address indexed _to, uint indexed _tokenId);
    event Transfer(uint _date, address indexed  _from, address indexed  _to, uint indexed _tokenId);
    event ApprovalForAllNft(address indexed owner, address indexed operator, bool approved);


    mapping (address => uint256) private mintCounts;

    mapping(uint256 => string[]) private tiers;

    constructor() payable ERC721("Worldcup", "WC") {
        tiers[1] = ["Brazil", "France","England","Spain","Germany","Argentina","Belgium","Portygal"];
        tiers[2] = ["Netherlands", "Denmark","Croatia","Uruguay","Poland","Senegal","United States","Serbia"];
        tiers[3] = ["Switzerland", "Mexico","Wales","Ghana","Ecuador","Moroco","Cameroon","Canada"];
        tiers[4] = ["Japan", "Qatar","Tunisia","South Korea","Australia","Iran","Saudi Arabia","Costa Rica"];
    }
    
    struct NFT {
        string name;
        string description;
        string traits;
    }

    mapping(uint256 => NFT) private _nfts;

    function randomModulus(uint256 mob) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender))) % mob;
    }

    function setApprovalForAll(address operator, bool approved) public override {
        require(_msgSender() != operator, "ERC721: Approve to caller");
        
        super.setApprovalForAll(operator, approved);
        emit ApprovalForAllNft(_msgSender(), operator, approved);
    }

    function mintRandomTiers() internal view returns (string memory) {
        string memory selectedElements;

        if(mintCounts[msg.sender] > 3) {
            uint256 randomTiers = randomModulus(2);
            uint256 randomElement = randomModulus(tiers[randomTiers + 1].length);
            selectedElements = tiers[randomTiers + 1][randomElement]; 
        } else  {
            uint256 randTiers = randomModulus(4);
            uint256 randEl = randomModulus(tiers[randTiers + 1].length);
            selectedElements = tiers[randTiers + 1][randEl];  
        }
        return selectedElements;
    }

    function safeMint(
        string memory _name,
        string memory _description
    ) external payable  {
        require(msg.value <= mintPrice, "Balances don't enough");
        string memory typeTrait = mintRandomTiers();

        uint256 tokenId = _tokenIdCounter.current() + 1;
        _safeMint(msg.sender, tokenId);
        _nfts[tokenId] = NFT(_name, _description, typeTrait);

        _tokenIdCounter.increment();
        mintCounts[msg.sender] ++;
        
        emit Mint(block.timestamp, address(0), msg.sender, tokenId);
    }

    function checkOwnerOfNFT(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "Token does not exist");
        return ownerOf(tokenId);
    }

    function getMintCount() external view returns (uint256) {
        return mintCounts[msg.sender];
    }

    function transfer(address _to, uint256 _tokenId) public virtual {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "ERC721: transfer caller is not owner nor approved");
        require(_to != address(0), "Cannot transfer to address zero");
        
        _transfer(msg.sender, _to, _tokenId);

        emit Transfer(block.timestamp,msg.sender,_to,_tokenId);
    }

    function getMetadata(uint256 tokenId) external view returns (NFT memory) {
        require(_exists(tokenId), "ERC721Metadata: NFT does not exist");
        return _nfts[tokenId];
    }

    function _baseURI() internal view override returns(string memory) {
        return baseURI;
    }

     function tokenURI(uint256 tokenId) override(ERC721) public view returns (string memory) {
        require(_exists(tokenId), "Token does not exist");
        NFT memory nft = _nfts[tokenId];

        string memory json = string(
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
        return json;
    }
}
