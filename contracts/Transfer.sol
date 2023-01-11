// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0 <0.9.0;

import "./Company.sol";

contract Transfer
{
    uint wei_to_eth = 1000000000000000000;
    mapping(string => Company) public companies;
    mapping(address => User) public users;
    string[] public companySymbols;
    
    function checkCompanyNew(string memory _symbol) private view returns (bool)
    {
        // Loop symbols, if matching is found return false
        for (uint i = 0; i < companySymbols.length; i++) { if (SL.compareStrings(_symbol, companySymbols[i])) return false; }
        return true;
    }
    
    // Add new company stock to ClearChain contract options
     function addCompany(string memory _symbol, uint _issued, uint _float, uint _baseSharePrice) public payable
     {
        require(_float < _issued, "Total shares is not greater than float.");
        //require(msg.value == 1 ether,"Adding a company requires 1 ether to complete");
        _symbol = SL.toUpper(_symbol);
        require(checkCompanyNew(_symbol),"Company already exists");
        
        // Create new user for company, add sell request for float shares at given base price
        if(address(users[msg.sender]) == address(0))
			users[msg.sender] = new User(payable(msg.sender),_symbol,_float,_baseSharePrice);
		//users[msg.sender].addSellOrder(_symbol,_float,_baseSharePrice);
        
        // Create company
        companySymbols.push(_symbol);
        companies[_symbol] = new Company(msg.sender,_symbol,_issued,_float,_baseSharePrice,address(users[msg.sender]));
     }
     
     function changeOwnership(string memory _symbol, address _newOwner) public payable returns(address)
    {
        require(msg.value == 1 ether,"Change of ownership requires 1 ether to complete");
        _symbol = SL.toUpper(_symbol);
        require(!checkCompanyNew(_symbol),"Company does not exist");
        //address newOwner = companies[upperSym].changeOwnership(msg.sender,_newOwner);
        return companies[_symbol].changeOwnership(msg.sender,_newOwner);
    }
    
    function buyRequest(string memory _symbol, uint _quantity, uint _priceLimit) public payable
    {
        _symbol = SL.toUpper(_symbol);
		require(!checkCompanyNew(_symbol),"Company does not exist");
		require(_quantity * _priceLimit == msg.value,"Incorrect amount of ether sent to complete trade at requested price");
        
        if(address(users[msg.sender]) == address(0))
			users[msg.sender] = new User(payable(msg.sender),"",0,0);
			
		users[msg.sender].addValue{value: _priceLimit * _quantity}(_quantity,_priceLimit);
			
		//(bool sent,) = address(users[msg.sender]).call{value: _quantity * _priceLimit}("");
        //if (!sent) revert("Failed to send Ether to user contract");
		
		(int outCode, uint bought, uint spent) = companies[_symbol].addBuyOrder(address(users[msg.sender]),_quantity,_priceLimit);
		
		if (outCode == -1) revert("Error add buy request");
		
		if (outCode == 0)
			users[msg.sender].addBuyOrder(_symbol,_quantity - bought,_priceLimit);

		// Return excess credit if any
		uint remaining = msg.value - spent - (_priceLimit * (_quantity - bought));
		if (remaining > 0) users[msg.sender].returnCredit(remaining);
    }
    
    function sellRequest(string memory _symbol, uint _quantity, uint _priceLimit) public
    {
        _symbol = SL.toUpper(_symbol);
		require(!checkCompanyNew(_symbol),"Company does not exist");
		require(address(users[msg.sender]) != address(0),"User does not exist");
        
        ///if(address(users[msg.sender]) == address(0))
			//users[msg.sender] = new User(msg.sender);
		
		(int outCode, uint sold, ) = companies[_symbol].addSellOrder(address(users[msg.sender]),_quantity,_priceLimit);
		
		if (outCode == -1) revert("Error adding sell request");
		
		if (outCode == 0)
			users[msg.sender].addSellOrder(_symbol,_quantity - sold,_priceLimit);
    }
    
    function getAmountOfShares(string memory _symbol) public view returns(uint)
	{
		//_symbol = SL.toUpper(_symbol);
		return users[msg.sender].getAmountOfShares(_symbol);
	} 
    
}