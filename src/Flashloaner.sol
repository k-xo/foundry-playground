// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {ReentrancyGuard} from "solmate/utils/ReentrancyGuard.sol";
import {IReceiver} from "./IReceiver.sol";

// adapted from https://github.com/nicolasgarcia214/damn-vulnerable-defi-foundry
contract Flashloaner is ReentrancyGuard {
    ERC20 public immutable token;
    uint256 public poolBalance;

    address owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "!owner");
        _;
    }

    error TokenAddressCannotBeZero();
    error MustBorrowOneTokenMinimum();
    error NotEnoughTokensInPool();
    error FlashLoanHasNotBeenPaidBack();
    error MustDepositOneTokenMinimum();

    constructor(address tokenAddress) {
        if (tokenAddress == address(0)) revert TokenAddressCannotBeZero();
        token = ERC20(tokenAddress);
        owner = msg.sender;
    }

    function depositTokens(uint256 amount) external nonReentrant {
        if (amount == 0) revert MustDepositOneTokenMinimum();

        // Transfer token from sender. Sender must have first approved them.
        token.transferFrom(msg.sender, address(this), amount);
        poolBalance = poolBalance + amount;
    }

    function flashLoan(uint256 borrowAmount) external nonReentrant {
        if (borrowAmount == 0) revert MustBorrowOneTokenMinimum();

        uint256 balanceBefore = token.balanceOf(address(this));
        if (balanceBefore < borrowAmount) revert NotEnoughTokensInPool();

        // Ensured by the protocol via the `depositTokens` function
        assert(poolBalance == balanceBefore);

        token.transfer(msg.sender, borrowAmount);

        IReceiver(msg.sender).receiveTokens(address(token), borrowAmount);

        uint256 balanceAfter = token.balanceOf(address(this));
        if (balanceAfter < balanceBefore) revert FlashLoanHasNotBeenPaidBack();
        poolBalance = balanceAfter;
    }
}
