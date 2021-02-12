pragma solidity  ^0.6.0;

contract Constant {
    string constant ERR_CONTRACT_SELF_ADDRESS = "ERR_CONTRACT_SELF_ADDRESS";
    string constant ERR_ZERO_ADDRESS = "ERR_ZERO_ADDRESS";
    string constant ERR_NOT_OWN_ADDRESS = "ERR_NOT_OWN_ADDRESS";
    string constant ERR_VALUE_IS_ZERO = "ERR_VALUE_IS_ZERO";
    string constant ERR_AUTHORIZED_ADDRESS_ONLY = "ERR_AUTHORIZED_ADDRESS_ONLY";
    string constant ERR_NOT_ENOUGH_BALANCE = "ERR_NOT_ENOUGH_BALANCE";

    modifier notOwnAddress(address _which) {
        require(msg.sender != _which, ERR_NOT_OWN_ADDRESS);
        _;
    }

    // validates an address is not zero
    modifier notZeroAddress(address _which) {
        require(_which != address(0), ERR_ZERO_ADDRESS);
        _;
    }

    // verifies that the address is different than this contract address
    modifier notThisAddress(address _which) {
        require(_which != address(this), ERR_CONTRACT_SELF_ADDRESS);
        _;
    }

    modifier notZeroValue(uint256 _value) {
        require(_value > 0, ERR_VALUE_IS_ZERO);
        _;
    }
}