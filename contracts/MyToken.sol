// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract WorldCup is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Address for address;
    using SafeMath for uint256;
    Counters.Counter private _tokenIdCounter;

    uint256 public constant cost = 0.0001 ether;

    string public baseURI = "ipfs://image/";

    bool public isPaused = false;

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

    mapping(address => uint256) private mintCounts;

    mapping(uint256 => string[]) private tiers;

    constructor() ERC721("Worldcup", "WC") {
        tiers[1] = [
            "Brazil",
            "France",
            "England",
            "Spain",
            "Germany",
            "Argentina",
            "Belgium",
            "Portygal"
        ];
        tiers[2] = [
            "Netherlands",
            "Denmark",
            "Croatia",
            "Uruguay",
            "Poland",
            "Senegal",
            "United States",
            "Serbia"
        ];
        tiers[3] = [
            "Switzerland",
            "Mexico",
            "Wales",
            "Ghana",
            "Ecuador",
            "Moroco",
            "Cameroon",
            "Canada"
        ];
        tiers[4] = [
            "Japan",
            "Qatar",
            "Tunisia",
            "South Korea",
            "Australia",
            "Iran",
            "Saudi Arabia",
            "Costa Rica"
        ];
    }

    struct NFT {
        string name;
        string description;
        string traits;
    }

    mapping(uint256 => NFT) private _nfts;

    

    function setApprovalForAll(address operator, bool approved)
        public
        override
    {
        require(msg.sender != operator, "ERC721: Approve to caller");
        super.setApprovalForAll(operator, approved);
        emit ApprovalForAllNft(msg.sender, operator, approved);
    }

    function pause() public onlyOwner {
        isPaused = !isPaused;
    }

   
    function safeMint() public payable {
        require(!isPaused);

        if (msg.sender != owner()) {
            require(msg.value >= cost, "Insufficient funds to mint tokens");
        }

        string memory typeTrait = mintRandomTiers();
        uint256 tokenId = _tokenIdCounter.current().add(1);
        _safeMint(msg.sender, tokenId);
        _nfts[tokenId] = NFT("Worldcup", "Worldcup 2020", typeTrait);

        _tokenIdCounter.increment();
        mintCounts[msg.sender]++;

        emit Mint(block.timestamp, address(0), msg.sender, tokenId);
    }

    function mintRandomTiers() internal view returns (string memory) {
        string memory selectedElements;

        if (mintCounts[msg.sender] > 3) {
            uint256 randomTiers = randomModulus(2);
            uint256 randomElement = randomModulus(
                tiers[randomTiers + 1].length
            );
            selectedElements = tiers[randomTiers + 1][randomElement];
        } else {
            uint256 randTiers = randomModulus(4);
            uint256 randEl = randomModulus(tiers[randTiers + 1].length);
            selectedElements = tiers[randTiers + 1][randEl];
        }
        return selectedElements;
    }

    function randomModulus(uint256 mob) internal view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        block.difficulty,
                        msg.sender
                    )
                )
            ) % mob;
    }


    function withdrawAll() external onlyOwner {
        require(address(this).balance > 0, "Contract balance is zero");

        address payable owner = payable(owner());
        bool success = owner.send(address(this).balance);
        require(success, "Withdrawal failed");

        emit Withdraw(owner, address(this).balance);
    }

    function checkOwnerOfNFT(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "Token does not exist");
        return ownerOf(tokenId);
    }

    function checkTotalOwerMint() external view returns (uint256) {
        return mintCounts[msg.sender];
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

    function getMetadata(uint256 tokenId) external view returns (NFT memory) {
        require(_exists(tokenId), "ERC721Metadata: NFT does not exist");
        return _nfts[tokenId];
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
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
