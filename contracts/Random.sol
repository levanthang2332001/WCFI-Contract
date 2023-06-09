// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "hardhat/console.sol";

contract Random {
    using SafeMath for uint256;

    mapping(uint256 => string[]) private tiers;

    
    constructor() {
        tiers[1] = ["Brazil", "France","England","Spain","Germany","Argentina","Belgium","Portygal"];
        tiers[2] = ["Netherlands", "Denmark","Croatia","Uruguay","Poland","Senegal","United States","Serbia"];
        tiers[3] = ["Switzerland", "Mexico","Wales","Ghana","Ecuador","Moroco","Cameroon","Canada"];
        tiers[4] = ["Japan", "Qatar","Tunisia","South Korea","Australia","Iran","Saudi Arabia","Costa Rica"];
    }

    function _randModulus(uint256 mob) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, msg.sender))) % mob;
    }

    function mintRandom() external view returns (string memory) {
        string memory selectedElements;
        uint256 rand = _randModulus(4);
        uint256 index = _randModulus(tiers[rand + 1].length);

        selectedElements = tiers[rand + 1][index];  
        console.log(selectedElements);

        return selectedElements;
    }

    
}

