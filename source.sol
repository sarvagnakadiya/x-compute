// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Interface/IWormholeRelayer.sol";
import "./Interface/IWormholeReceiver.sol";


contract Source is IWormholeReceiver {
    event GreetingReceived(uint256 result, uint16 senderChain, address sender);
    

    // Way too much gas, for purpose of illustrating refund
    uint256 constant GAS_LIMIT = 3_000_000;

    IWormholeRelayer public immutable wormholeRelayer;
    // IWormholeRelayer public immutable receiverWormholeRelayer2;
    uint256 public finalResult;

    constructor(address _wormholeRelayer) {
        wormholeRelayer = IWormholeRelayer(_wormholeRelayer);
    }

    function quoteCrossChainGreeting(uint16 targetChain) public view returns (uint256 cost) {
        (cost,) = wormholeRelayer.quoteEVMDeliveryPrice(targetChain, 0, GAS_LIMIT);
    }

    function quoteCrossChainGreetingRefundPerUnitGasUnused(uint16 targetChain) public view returns (uint256 refundPerUnitGasUnused) {
        (, refundPerUnitGasUnused) = wormholeRelayer.quoteEVMDeliveryPrice(targetChain, 0, GAS_LIMIT);
    }

    function sendCrossChainGreeting(
        uint16 targetChain,
        address targetAddress,
        uint256[] memory numbers,
        uint16 refundChain
    
    ) public payable {
        uint256 cost = quoteCrossChainGreeting(targetChain);
        require(msg.value >= cost);
        wormholeRelayer.sendPayloadToEvm{value: cost}(
            targetChain,
            targetAddress,
            abi.encode(numbers, msg.sender), // payload
            0, // no receiver value needed since we're just passing a message
            GAS_LIMIT,
            refundChain, 
            msg.sender 
        );
    }

    function receiveWormholeMessages(
        bytes memory payload,
        bytes[] memory, // additionalVaas
        bytes32, // address that called 'sendPayloadToEvm' (HelloWormholeRefunds contract address)
        uint16 sourceChain,
        bytes32 // deliveryHash
    ) public payable override{

        require(msg.sender == address(wormholeRelayer), "Only relayer allowed");
        (uint256 result, address sender) = abi.decode(payload, (uint256, address));
        finalResult = result;
        emit GreetingReceived(result, sourceChain, sender);
    }

  
}