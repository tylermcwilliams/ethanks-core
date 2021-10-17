// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract EThanksERC20 is ERC20, Ownable {
    uint256 private _maxSupplyUnlockBlock;
    uint256 private _maxSupply;
    
    constructor() ERC20("EThanks", "TNKS") {
        _maxSupplyUnlockBlock = block.number + 28000 * 365 * 3;
        _maxSupply = 1000000000 * 10**decimals();
    }
    
    function decimals() public override pure returns(uint8){
        return 18;
    }

    function mint(address to, uint256 amount) public onlyOwner {
        require(_maxSupply >= totalSupply() + amount, "ETHANKS: Max supply reached");
        _mint(to, amount);
    }

    function getMaxSupply() public view returns(uint256){
        return _maxSupply;
    }

    function setMaxSupply(uint256 amount) public onlyOwner {
        require(amount > totalSupply(), "ETHANKS: Cannot exceed max supply");
        require(block.number > _maxSupplyUnlockBlock, "ETHANKS: Max supply still frozen");
        _maxSupply = amount;
    }

    function getMaxSupplyUnlockBlock() public view returns(uint256){
        return _maxSupplyUnlockBlock;
    }
}
