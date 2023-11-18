// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Interface/IWormholeRelayer.sol";
import "./Interface/IWormholeReceiver.sol";

contract Destination is IWormholeReceiver {
    event GreetingReceived(uint256[] numbers, uint16 senderChain, address sender, uint256 calculatedResult);

    // Way too much gas, for purpose of illustrating refund
    uint256 constant GAS_LIMIT = 3_000_000;

    IWormholeRelayer public immutable wormholeRelayer;
    // IWormholeRelayer public immutable receiverWormholeRelayer2;

    uint256[] public numbersArray;

    uint256 public calculatedResult; 

    constructor(address _wormholeRelayer) {
        wormholeRelayer = IWormholeRelayer(_wormholeRelayer);
    }

    function quoteCrossChainGreeting(uint16 targetChain) public view returns (uint256 cost) {
        (cost,) = wormholeRelayer.quoteEVMDeliveryPrice(targetChain, 0, GAS_LIMIT);
    }

    function quoteCrossChainGreetingRefundPerUnitGasUnused(uint16 targetChain) public view returns (uint256 refundPerUnitGasUnused) {
        (, refundPerUnitGasUnused) = wormholeRelayer.quoteEVMDeliveryPrice(targetChain, 0, GAS_LIMIT);
    }

    
    function receiveWormholeMessages(
        bytes memory payload,
        bytes[] memory, // additionalVaas
        bytes32, // address that called 'sendPayloadToEvm' (HelloWormholeRefunds contract address)
        uint16 sourceChain,
        bytes32 // deliveryHash
    ) public payable override{
        require(msg.sender == address(wormholeRelayer), "Only relayer allowed");


        (uint256[] memory numbers, address sender) = abi.decode(payload, (uint256[], address));
        numbersArray = numbers;
        calculatedResult = performOperations(numbers);

        emit GreetingReceived(numbersArray, sourceChain, sender,calculatedResult);
    }

    function getNumbersArray() public view returns (uint256[] memory) {
        return numbersArray;
    }

    function performOperations(uint256[] memory _array) public view returns (uint sum) {
        require(numbersArray.length > 0, "Array must contain at least one element");

        // Calculate sum
        for (uint i = 0; i < _array.length; i++) {
            sum += _array[i];
        }

        return (sum);
    }

    function sendCrossChainGreeting(
        uint16 targetChain,
        address targetAddress,
        // uint256 result,
        uint16 refundChain
    
    ) public payable {
        uint256 cost = quoteCrossChainGreeting(targetChain);
        require(msg.value >= cost);
        wormholeRelayer.sendPayloadToEvm{value: cost}(
            targetChain,
            targetAddress,
            abi.encode(calculatedResult, msg.sender), // payload
            0, // no receiver value needed since we're just passing a message
            GAS_LIMIT,
            refundChain, 
            msg.sender 
        );
    }
}