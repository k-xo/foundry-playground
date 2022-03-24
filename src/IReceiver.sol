//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.10;

interface IReceiver {
    function receiveTokens(address tokenAddress, uint256 amount) external;
}