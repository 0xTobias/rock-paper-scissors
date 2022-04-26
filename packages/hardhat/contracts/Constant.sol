pragma solidity ^0.8.4;

contract Constant {
    //86501 gas
    address public constant ad = 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045;
}

contract Immutable {
    //89380 gas
    address public immutable ad = 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045;

    //Can be set up on constructor
    // constructor(address _immutable) {
    //     ad = _immutable;
    // }
}
