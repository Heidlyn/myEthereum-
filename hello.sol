pragma solidity ^0.4.16;
contract hello {
    string greeting;

    function hello(string _greeting) public {
        greeting = _greeting;
    }

    function say() constant public returns (string) {
        return greeting;
    }
}