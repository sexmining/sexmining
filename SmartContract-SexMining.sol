pragma solidity ^0.4.20;

library SafeMath {


    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}


contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}



contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


contract Token is ERC20Interface, Owned {
    using SafeMath for uint;

    string public name = "Sex";
    string public symbol = "SEX";
    string public nameMining = "Mining";
    string public symbolMining = "MNG";
    uint8 public decimals = 4;
    uint public _totalSupply;
    uint public supplySex;
    uint public supplyMining;

    mapping(address => uint) balanceSex;
    mapping(address => uint) balanceMining;
    mapping(address => mapping(address => uint)) allowed;

    constructor() public {   
        name = "Sex";
        symbol = "SEX";
        decimals = 4;
        _totalSupply = 100000000 * 10**uint(decimals);
        supplySex = 100000000 * 10**uint(decimals);
        balanceSex[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }

    function totalSupply() public view returns (uint) { 
        return _totalSupply - balanceSex[address(0)] - balanceMining[address(0)];
    }

    function totalSupplySex() public view returns (uint) {
        return supplySex;
    }

    function totalSupplyMining() public view returns (uint) {
        return supplyMining;
    }
    // Extra function
    function totalSupplyWithZeroAddress() public view returns (uint) { 
        return _totalSupply;
    }

    function balanceOf(address tokenOwner) public view returns (uint balance) { 
        return balanceSex[tokenOwner];
    }

    // token B related
    function balanceOfMining(address tokenOwner) public view returns(uint balance) {
        return balanceMining[tokenOwner];
    }

    // Extra function
    function myBalance() public view returns (uint balance) {
        return balanceSex[msg.sender];
    }

    function myBalanceMining() public view returns (uint balance) {
        return balanceMining[msg.sender];
    }

    function burnSex(uint256 amount) external {
        balanceSex[msg.sender] = balanceSex[msg.sender].sub(amount);
        supplySex = supplySex.sub(amount);
        balanceMining[msg.sender] = balanceMining[msg.sender].add(amount);
        supplyMining = supplyMining.add(amount);
    }

    function burnMining(address[] receivers, uint256 amount) external {
        require(receivers.length <= 10);
        uint256 distrAmount = amount / receivers.length;
        balanceMining[msg.sender] = balanceMining[msg.sender].sub(amount);
        supplyMining = supplyMining.sub(amount);
        supplySex = supplySex.add(amount);
        for(uint i; i<receivers.length; i++) {
            balanceSex[receivers[i]] += distrAmount;
        }
    }

    function transfer(address to, uint tokens) public returns (bool success) {  
        balanceSex[msg.sender] = balanceSex[msg.sender].sub(tokens);
        balanceSex[to] = balanceSex[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function approve(address spender, uint tokens) public returns (bool success) {  
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {    
        balanceSex[from] = balanceSex[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balanceSex[to] = balanceSex[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {  
        return allowed[tokenOwner][spender];
    }

    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }

    function () public payable {  
        revert();
    }

    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) { 
        return ERC20Interface(tokenAddress).transfer(owner, tokens);        
    }
}

contract Admin is Token {
    // change symbol and name of token A and B
    function reconfig(string newNameSex, string newSymbolSex, string newNameMining, string newSymbolMining) external onlyOwner {
        name = newNameSex;
        symbol = newSymbolSex;
        nameMining = newNameMining;
        symbolMining = newSymbolMining;
    }
}