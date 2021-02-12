pragma solidity  ^0.6.0;

interface ERC20Interface
{
    function totalSupply() external view returns(uint256);
    
    function balanceOf(address _tokenOwner)external view returns(uint balance );
    
    function allowance(address _tokenOwner, address _spender)external view returns (uint supply);
    
    function transfer(address _to,uint _tokens)external returns(bool success);
    
    function approve(address _spender,uint _tokens)external returns(bool success);
    
    function transferFrom(address _from,address _to,uint _tokens)external returns(bool success);
    
    event Transfer(address indexed _from, address indexed _to, uint256 _tokens);
    event Approval(address indexed _owner, address indexed _spender, uint256 _tokens);
    
}    