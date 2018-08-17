pragma solidity ^0.4.24;

/**
 * Math operations with safety checks
 */
library SafeMath {
  function mul(uint a, uint b) internal pure returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal pure returns (uint) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
}


interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }


contract BETToken {
    // Public variables of the token
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply;

    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    // This generates a public event on the blockchain that will notify clients
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

    /**
     * Constructor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor(
        uint256 initialSupply
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        balanceOf[msg.sender] = totalSupply;                // Give the creator all initial tokens
        name = "BET Tokens";                                   // Set the name for display purposes
        symbol = "BETT";                               // Set the symbol for display purposes
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balanceOf[_from] >= _value);
        // Check for overflows
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        // Subtract from the sender
        balanceOf[_from] -= _value;
        // Add the same to the recipient
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` on behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens on your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * Set allowance for other address and notify
     *
     * Allows `_spender` to spend no more than `_value` tokens on your behalf, and then ping the contract about it
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     * @param _extraData some extra information to send to the approved contract
     */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }
    
    // for BET Smart contract
    function approveBetAndCall(address _spender, uint256 _value, uint256 _id_team, uint256 _id_match)
        public
        returns (bool success) {
        // tokenRecipient spender = tokenRecipient(_spender);
        BETSmartContract spender = BETSmartContract(_spender);
        if (approve(_spender, _value)) {
            spender.bet(msg.sender, _value, _id_team, _id_match);
            return true;
        }
    }
}

contract BETSmartContract {
    
    using SafeMath for uint256;
    
    address public BETTokenAddress;
    address public MasterAddress;
    
    constructor(address _BETTokenAddress, uint256 _timeOneMatch) public {
        BETTokenAddress = _BETTokenAddress;
        nameOfTeam[1] = "Manchester United F.C.";
        nameOfTeam[2] = "Real Madrid C.F.";
        nameOfTeam[3] = "Viet Nam";
        nameOfTeam[4] = "Korea";
        nameOfTeam[5] = "Japan";
        timeOneMatch = _timeOneMatch;
        
        MasterAddress = msg.sender;
    }
    
    modifier onlyBETToken {
        require(msg.sender == BETTokenAddress);
        _;
    }
    
    modifier onlyMaster {
        require(msg.sender == MasterAddress);
        _;
    }
    
    event BET(address indexed user, uint amount, uint indexed id_match, uint timeBetting);
    event Withdraw(address indexed user, uint amount, uint indexed id_match, uint timeWithdraw);
    
    
    struct Match {
        uint256 id_team_a;
        uint256 id_team_b;
        uint256 time_end;
        // if (time_end result !== 0) {result = `id team win`}
        uint256 result;
        uint256 totalBetting;
        uint256 totalBetTeamA;
        uint256 totalBetTeamB;
    }
    
    // list address betting
    struct user {
        uint256 valueBet;
        bool isBet;
        uint256 id_team_bet;
        bool isWithdrawn;
        
    }
    
    
    mapping (uint256 => Match) public listMatch;
    mapping (uint256 => string) public nameOfTeam;
    mapping(address => mapping(uint256 => user)) public userBet;
    
    uint256 public timeOneMatch;
    uint256 public currentMatch;
    
    
    
    function changeMaster(address _masterAddress) public onlyMaster {
        require(_masterAddress != address(0));
        MasterAddress = _masterAddress;
    }
    
    function changeTimeOneMatch(uint256 _timeOneMatch) public onlyMaster {
        require(_timeOneMatch != 0);
        timeOneMatch = _timeOneMatch;
    }
    
    function openMatch(uint256 _id_match, uint256 _id_team_a, uint256 _id_team_b, uint256 _time_end) 
        public
        onlyMaster 
    {
        require(_id_match > currentMatch && listMatch[_id_match].time_end == 0);
        require(_time_end > now);
        currentMatch = _id_match;
        listMatch[_id_match].id_team_a = _id_team_a;
        listMatch[_id_match].id_team_b = _id_team_b;
        listMatch[_id_match].time_end = _time_end;
    }
    
    function bet(address _from, uint256 _value, uint256 _id_team, uint256 _id_match) public onlyBETToken {
        require(BETTokenAddress != address(0) && _id_team != 0 && _id_match != 0 && _value > 0);
        
        // match
        require(now < (listMatch[_id_match].time_end).sub(timeOneMatch));
        require(_id_team == listMatch[_id_match].id_team_a || _id_team == listMatch[_id_match].id_team_b);
        require(!userBet[_from][_id_match].isBet);
        
        // get token
        BETToken betToken = BETToken(BETTokenAddress);
        betToken.transferFrom(_from, this, _value);
        
        listMatch[_id_match].totalBetting = listMatch[_id_match].totalBetting.add(_value);
        userBet[_from][_id_match].valueBet = _value;
        userBet[_from][_id_match].id_team_bet = _id_team;
        
        if (_id_team == listMatch[_id_match].id_team_a) {
            listMatch[_id_match].totalBetTeamA = listMatch[_id_match].totalBetTeamA.add(_value);
        } else if (_id_team == listMatch[_id_match].id_team_b) {
            listMatch[_id_match].totalBetTeamB = listMatch[_id_match].totalBetTeamB.add(_value);
        } else {
            revert();
        }
        
        userBet[_from][_id_match].isBet = true;
        emit BET(_from, _value, _id_match, now);
    }
    
    function withdraw(uint256 _id_match) public {
        uint256 tokenReturn;
        
        // match
        require(listMatch[_id_match].result != 0);
        require(now > listMatch[_id_match].time_end && listMatch[_id_match].time_end > 0);
        
        // user
        require(userBet[msg.sender][_id_match].isBet && !userBet[msg.sender][_id_match].isWithdrawn);
        require(listMatch[_id_match].result == userBet[msg.sender][_id_match].id_team_bet);
        
        if (listMatch[_id_match].result == listMatch[_id_match].id_team_a) {
            tokenReturn = listMatch[_id_match].totalBetting.mul(userBet[msg.sender][_id_match].valueBet).div(listMatch[_id_match].totalBetTeamA);
        } else if(listMatch[_id_match].result == listMatch[_id_match].id_team_b) {
            tokenReturn = listMatch[_id_match].totalBetting.mul(userBet[msg.sender][_id_match].valueBet).div(listMatch[_id_match].totalBetTeamB);
        } else {
            revert();
        }
        
        BETToken betToken = BETToken(BETTokenAddress);
        betToken.transfer(msg.sender, tokenReturn);
        
        userBet[msg.sender][_id_match].isWithdrawn = true;
        
        emit Withdraw(msg.sender, tokenReturn, _id_match, now);
    }
    
    function getWinAmount(address _user, uint256 _id_match) public view
    returns (uint256)
    {
        uint256 tokenReturn = 0;
        
        if (listMatch[_id_match].result == listMatch[_id_match].id_team_a) {
            tokenReturn = listMatch[_id_match].totalBetting.mul(userBet[_user][_id_match].valueBet).div(listMatch[_id_match].totalBetTeamA);
        } else if(listMatch[_id_match].result == listMatch[_id_match].id_team_b) {
            tokenReturn = listMatch[_id_match].totalBetting.mul(userBet[_user][_id_match].valueBet).div(listMatch[_id_match].totalBetTeamB);
        }
        
        if (listMatch[_id_match].result == userBet[msg.sender][_id_match].id_team_bet) {
            return tokenReturn;
        } else {
            return 0;
        }
        
    }
    
    function submitResult(uint256 _id_match, uint256 _id_team_win) onlyMaster public {
        
        require(now > listMatch[_id_match].time_end && listMatch[_id_match].time_end > 0);
        require(_id_team_win == listMatch[_id_match].id_team_a || _id_team_win == listMatch[_id_match].id_team_b);
        listMatch[_id_match].result = _id_team_win;
    }
}
