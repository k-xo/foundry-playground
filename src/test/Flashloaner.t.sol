// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "ds-test/test.sol";
import {Vm} from "forge-std/Vm.sol";
import {ERC20, MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";
import {Flashloaner} from "../Flashloaner.sol";

contract TokenReturner {
    uint256 return_amount;

    function receiveTokens(
        address tokenAddress,
        uint256 /* amount */
    ) external {
        // transfers the tokens back straight away
        ERC20(tokenAddress).transfer(msg.sender, return_amount);
    }
}

contract ContractTest is DSTest, TokenReturner {
    Vm vm = Vm(HEVM_ADDRESS);

    address alice = address(0x1234);
    address bob = address(0x123456789);

    MockERC20 token;
    Flashloaner loaner;

    function setUp() public {
        vm.label(alice, "Alice");
        vm.label(bob, "Bob");
        vm.label(address(this), "TestContract");

        token = new MockERC20("TestToken", "TT0", 18);
        vm.label(address(token), "TestToken");

        loaner = new Flashloaner(address(token));

        token.mint(address(this), 1e18);

        token.approve(address(loaner), 100);
        loaner.depositTokens(100);
    }

    function test_ConstructNonZeroTokenRevert() public {
        vm.expectRevert(Flashloaner.TokenAddressCannotBeZero.selector);
        new Flashloaner(address(0x0));
    }

    function test_PoolBalance() public {
        token.approve(address(loaner), 1);
        loaner.depositTokens(1);

        assertEq(loaner.poolBalance(), 101);
        assertEq(token.balanceOf(address(loaner)), loaner.poolBalance());
    }

    function test_RevertWhenZeroDeposit() public {
        vm.expectRevert(Flashloaner.MustDepositOneTokenMinimum.selector);
        loaner.depositTokens(0);
    }

    function test_BorrowZeroRevert() public {
        vm.expectRevert(Flashloaner.MustBorrowOneTokenMinimum.selector);
        loaner.flashLoan(0);
    }

    function test_BorrowMoreRevert() public {
        vm.expectRevert(Flashloaner.NotEnoughTokensInPool.selector);
        loaner.flashLoan(2**250);
    }

    function test_ReturnAmountRevert() public {
        vm.expectRevert(Flashloaner.FlashLoanHasNotBeenPaidBack.selector);
        return_amount = 0;
        loaner.flashLoan(100);
    }

    function test_flashloan() public {
        return_amount = 100;
        loaner.flashLoan(100);
        assertEq(loaner.poolBalance(), 100);
        assertEq(token.balanceOf(address(loaner)), loaner.poolBalance());
    }
}
