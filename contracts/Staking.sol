pragma solidity ^0.6.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC20Interface.sol";
import "./Token.sol";

contract StakeStorage {
    
     /**
     * @dev check if token is listed 
    **/
    mapping(address => bool) public listedToken;
    
    /**
     * @dev list of tokens
    **/
    address[] public tokens;
    
    mapping(address =>uint256)public tokenIndex;

    mapping(address => mapping(address => uint256)) public stakeBalance;
    
    mapping(address => mapping(address => uint256)) public lastStakeClaimed;
    
    mapping(address => uint256)public totalTokens;
    
    /**
     * @dev annual mint percent of a token
     **/
     mapping (address => uint256) public annualMintPercentage;
     /**
     * @dev list of particular token's paynoder
     **/
    mapping(address => address[])public payNoders;
    /**
     * @dev check if address is in paynode
     **/
    mapping(address => mapping(address => bool)) public isPayNoder;
    /**
     * @dev maintain array index for addresses
     **/
    mapping(address => mapping(address => uint256)) public payNoderIndex;
    /**
     * @dev token's  paynode slot
    **/
    mapping(address => uint256)public tokenPayNoderSlot;
    
    /**
     * @dev minimum balance require for be in paynode
    **/
    mapping(address => uint256)public tokenMinimumBalance;
        
    mapping(address => uint256)public tokenExtraMintForPayNodes;
     
    event Stake(
            uint256 indexed _stakeTimestamp,
            address indexed _token,
            address indexed _whom,
            uint256 _amount
        );
        
        event StakeClaimed(
            uint256 indexed _stakeClaimedTimestamp,
            address indexed _token,
            address indexed _whom,
            uint256 _amount
        );

        event UnStake(
            uint256 indexed _unstakeTimestamp,
            address indexed _token,
            address indexed _whom,
            uint256 _amount
        );
}

contract Paynodes is Ownable,SafeMath,StakeStorage{
  
    /**
     * @dev adding paynode account
    **/
    function addaccountToPayNode(address _token,address _whom)
        external
        onlyOwner()
        returns (bool)
    {   
        require(isPayNoder[_token][_whom] == false,"ERR_ALREADY_IN_PAYNODE_LIST");
        
        require(payNoders[_token].length < tokenPayNoderSlot[_token] ,"ERR_PAYNODE_LIST_FULL");
        
        require(stakeBalance[_token][_whom] >= tokenMinimumBalance[_token],"ERR_PAYNODE_MINIMUM_BALANCE");
        
        isPayNoder[_token][_whom] = true;
        payNoderIndex[_token][_whom] = payNoders[_token].length;
        payNoders[_token].push(_whom);
        return true;
    }

    /**
     * @dev removing paynode account
     **/
    function _removeaccountToPayNode(address _token,address _whom) internal returns (bool) {
        
        require(isPayNoder[_token][_whom], "ERR_ONLY_PAYNODER");
        uint256  _payNoderIndex = payNoderIndex[_token][_whom];
      
        address  _lastAddress = payNoders[_token][safeSub(payNoders[_token].length,1)];
        payNoders[_token][_payNoderIndex] =_lastAddress ;
        payNoderIndex[_token][_lastAddress] = _payNoderIndex;
        delete isPayNoder[_token][_whom];
        payNoders[_token].pop();
        return true;
    }

    /**
     * @dev remove account from paynode
     **/
    function removeaccountToPayNode(address _token,address _whom)
        external
        onlyOwner()
        returns (bool)
    {
        return _removeaccountToPayNode(_token,_whom);
    }

    /**
     * @dev owner can change minimum balance requirement
     **/
    function setMinimumBalanceForPayNoder(address _token,uint256 _minimumBalance)
        external
        onlyOwner()
        returns (bool)
    {
        tokenMinimumBalance[_token] = _minimumBalance;
        return true;
    }

    /**
     * @dev owner can change extra mint percent for paynoder
     * _extraMintForPayNodes is set in percent with mulitply 100
     * if owner want to set 1.25% then value is 125
     **/
    function setExtraMintingForNodes(address _token,uint256 _extraMintForPayNodes)
        external
        onlyOwner()
        returns (bool)
    {
        tokenExtraMintForPayNodes[_token] = _extraMintForPayNodes;
        return true;
    }

    /**
     * @dev owner can set paynoder slots
     **/
    function setPayNoderSlot(address _token,uint256 _payNoderSlot)
        external
        onlyOwner()
        returns (bool)
    {
        tokenPayNoderSlot[_token] = _payNoderSlot;
        return true;
    }
 
}

contract staking is Paynodes {
    
    constructor(address[] memory _token) public {
        for(uint8 i = 0; i < _token.length; i++){
            listedToken[_token[i]] = true;  
            tokens.push(_token[i]);
            tokenIndex[_token[i]]  = i;
        }
    }
    
     /**
     * @dev stake token
     **/
    function stake(address _token,uint256 _amount) external returns(bool){
        
        require(listedToken[_token],"ERR_TOKEN_IS_NOT_LISTED");
        
        ERC20Interface(_token).transferFrom(msg.sender,address(this),_amount);
        
        if (lastStakeClaimed[_token][msg.sender] == 0) {
            lastStakeClaimed[_token][msg.sender] = now;
        }else{
            uint256 _stakeReward = _calculateStake(_token,msg.sender);
            lastStakeClaimed[_token][msg.sender] = now;
            stakeBalance[_token][msg.sender] =  safeAdd(stakeBalance[_token][msg.sender],_stakeReward);
        }
        
        totalTokens[_token] =  safeAdd(totalTokens[_token],_amount);
        stakeBalance[_token][msg.sender] = safeAdd(stakeBalance[_token][msg.sender], _amount );
        emit Stake(now,_token, msg.sender,_amount);
        return true;
    }
    
    /**
     * @dev stake token
     **/
    function unStake(address _token) external returns(bool){
        
        require(listedToken[_token],"ERR_TOKEN_IS_NOT_LISTED");
        
        uint256 userTokenBalance = stakeBalance[_token][msg.sender];
        uint256 _stakeReward = _calculateStake(_token,msg.sender);
        ERC20Interface(_token).transfer(msg.sender,safeAdd(userTokenBalance,_stakeReward));
        emit UnStake(now,_token, msg.sender,safeAdd(userTokenBalance,_stakeReward));
        totalTokens[_token] =  safeSub(totalTokens[_token],userTokenBalance);
        stakeBalance[_token][msg.sender] = 0;
        lastStakeClaimed[_token][msg.sender] = 0;
        return true;
    }
    
    /**
     * @dev withdraw token
     **/
     function withdrawToken(address _token)external  returns(bool){
        
        require(listedToken[_token],"ERR_TOKEN_IS_NOT_LISTED");
        uint256 userTokenBalance = stakeBalance[_token][msg.sender];
        stakeBalance[_token][msg.sender] = 0;
        lastStakeClaimed[_token][msg.sender] = 0;
        ERC20Interface(_token).transfer(msg.sender,userTokenBalance);
		return true;
    }
    
    /**
     * @dev withdraw token by owner
     **/
    
    function withdrawToken(address _token,uint256 _amount )external onlyOwner() returns(bool) {
         require(listedToken[_token],"ERR_TOKEN_IS_NOT_LISTED");
         require(totalTokens[_token] == 0,"ERR_TOTAL_TOKENS_NEEDS_TO_BE_0_FOR_WITHDRAWL");
         ERC20Interface(_token).transfer(msg.sender,_amount);
         return true;
    }
    
    // we calculate daily basis stake amount 
    function _calculateStake(address _token,address _whom) internal view returns (uint256) {

        uint256 _lastRound = lastStakeClaimed[_token][_whom];
        uint256 totalStakeDays = safeDiv(safeSub(now,_lastRound),86400);
        uint256 userTokenBalance = stakeBalance[_token][_whom];
        
        uint256 tokenPercentage = annualMintPercentage[_token];
        if (totalStakeDays > 0) {
            uint256 stakeAmount = safeDiv(safeMul(safeMul(userTokenBalance,tokenPercentage),totalStakeDays),3650000);
            if(isPayNoder[_token][_whom]){
                if(stakeBalance[_token][_whom] >= tokenMinimumBalance[_token]){
                   uint256 extraPayNode = safeDiv(safeMul(safeMul(userTokenBalance,tokenPercentage),tokenExtraMintForPayNodes[_token]),3650000);
                   stakeAmount = safeAdd(stakeAmount,extraPayNode);
                }
            }
            return stakeAmount;
        }
        return 0;
    
    }   
    
    // show stake balance with what user get
    function balanceOf(address _token,address _whom) external view returns (uint256) {
        uint256 _stakeReward = _calculateStake(_token,_whom); 
        return safeAdd(stakeBalance[_token][_whom], _stakeReward);
    }
    
    // show stake balance with what user get
    function getOnlyRewards(address _token,address _whom) external view returns (uint256) {
        return _calculateStake(_token,_whom); 
    }
    
    // claim only rewards and withdraw it
    function claimRewardsOnlyAndWithDraw(address _token) external returns (bool) {
        require(lastStakeClaimed[_token][msg.sender] != 0,"ERR_TOKEN_IS_NOT_STAKED");
        uint256 _stakeReward = _calculateStake(_token,msg.sender);
        ERC20Interface(_token).transfer(msg.sender,_stakeReward);
        lastStakeClaimed[_token][msg.sender] = now;
        emit StakeClaimed(now,_token,msg.sender,_stakeReward);
        return true;
    }
    
    // claim only rewards and restake it
    function claimRewardsOnlyAndStake(address _token) external returns (bool) {
        require(lastStakeClaimed[_token][msg.sender] != 0,"ERR_TOKEN_IS_NOT_STAKED");
        uint256 _stakeReward = _calculateStake(_token,msg.sender);
       
        lastStakeClaimed[_token][msg.sender] = now;
        stakeBalance[_token][msg.sender] =  safeAdd(stakeBalance[_token][msg.sender],_stakeReward);
        emit StakeClaimed(now,_token,msg.sender,_stakeReward);
        emit Stake(now,_token, msg.sender,stakeBalance[_token][msg.sender]);
        return true;
    }
    
    // _percent should be mulitplied by 100
    function setAnnualMintPercentage(address _token,uint256 _percent) external onlyOwner()  returns (bool) {
        require(listedToken[_token],"ERR_TOKEN_IS_NOT_LISTED");
        annualMintPercentage[_token] = _percent;
        return true;
    }
    
    // to add new token
    function addToken(address _token)external onlyOwner(){
      require(!listedToken[_token],"ERR_TOKEN_ALREADY_EXISTS");
      tokens.push(_token);
      listedToken[_token] = true;
      tokenIndex[_token] = tokens.length;
    }
    
    // to remove the token
    function removeToken(address _token)external onlyOwner(){
      require(listedToken[_token],"ERR_TOKEN_DOESNOT_EXISTS");
      
      uint256 _lastindex = tokenIndex[_token];
      address _lastaddress = tokens[safeSub(tokens.length,1)];
      tokenIndex[_lastaddress] = _lastindex;
      tokens[_lastindex] = _lastaddress;
      tokens.pop();
      delete tokenIndex[_lastaddress];
      listedToken[_token] = false;
    }
    
    function availabletokens()public view returns(uint){
       return tokens.length;
    }
   
}
 