pragma solidity >=0.4.19;

contract setScore{

    uint public score;
    function set(uint _score) public{
        score = _score;
    }

}