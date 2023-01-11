// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0 <0.9.0;

import "./User.sol";

contract Company
{
    struct FilledTransaction
	{
		uint _totalPrice;
		uint _totalShares;
	}

    string public symbol;
    address public owner;
    address associatedUser;
    
    // Total stock
    uint issuedShares;
    // Publicly available stock
    uint floatShares;
    // Default share price
    uint sharePrice;
    
    mapping(address => address) public buyOrders;
    mapping(address => address) public sellOrders;
    
    address buyHead;
    address sellHead;
    
    constructor(address _owner, string memory _symbol, uint _issued, uint _float, uint _sharePrice, address _associatedUser)
    {
        owner = _owner;
        symbol = _symbol;
        issuedShares = _issued;
        floatShares = _float;
        sharePrice = _sharePrice;
        associatedUser = _associatedUser;
        
        sellHead = _associatedUser;
        buyHead = address(0);
        
        sellOrders[sellHead] = address(0);
    }
    
    function isOwner(address _addr) public view returns (bool)
    {
        return _addr == owner;
    }
    
    function changeOwnership(address _oldOwner, address _newOwner) public returns(address)
	{
		require(_oldOwner == owner, "Ownership change request made from non-authoratative account");
		owner = _newOwner;
		return owner;
	}
    
    // return outCode (function status code):
    // 		-1: buy order failed to add
    // 		0: buy order added to list
    // 		1: matching sell order(s) found, buy order fulfilled
    function addBuyOrder(address _user, uint _quantity, uint _price) public returns(int outCode, uint bought, uint spent)
    {
        require(_quantity < floatShares,"Not enough shares available to complete request");
        
        // Fulfill order if possible
        (uint soldShares, uint soldPrice) = fulfillBuyOrder(_user, _quantity, _price);
        if (soldShares == _quantity) return (1,soldShares,soldPrice);
        
        // No existing buy orders
        if (buyHead == address(0))
        {
            buyHead = _user;
            buyOrders[buyHead] = address(0);
            return (0,0,0);
        }
		// Sort new buy order into existing order list
        else
        {
            User curUser = User(buyHead);
            address prevUserAdd = address(0);
            
            while(address(curUser) != address(0))
            {
                if (curUser.checkBuyPrice(symbol) < _price)
                {
                    if (address(curUser) == buyHead)
                    {
                        buyOrders[_user] = buyHead;
                        buyHead = _user;
                    }
                    else
                    {
                        buyOrders[prevUserAdd] = _user;
                        buyOrders[_user] = address(curUser);
                    }
                    
                    return (0,soldShares,soldPrice);
                }
                
                prevUserAdd = address(curUser);
                curUser = User(buyOrders[address(curUser)]);
            }
        }
        
		// Failed
        return (-1,0,0);
    }
    
	// return codes (buy and sell):
    // -1: buy order failed to add
    // 0: buy order added to list
    // 1: matching buy order(s) found, sell order fulfilled
    function addSellOrder(address _user, uint _quantity, uint _price) public returns(int outCode, uint sold, uint earned)
    {
        require(_quantity < floatShares,"Not enough shares available to complete request");
        
        // Fulfill order if possible
        (uint soldShares, uint soldPrice) = fulfillSellOrder(_user, _quantity, _price);
        if (soldShares == _quantity) return (1,soldShares,soldPrice);
        
        // No existing buy orders
        if (sellHead == address(0))
        {
            sellHead = _user;
            sellOrders[_user] = address(0);
            return (0,0,0);
        }
		// Sort new buy order into existing order list
        else
        {
            User curUser = User(sellHead);
            address prevUserAdd = address(0);
            
            while(address(curUser) != address(0))
            {
                if (curUser.checkBuyPrice(symbol) < _price)
                {
                    if (address(curUser) == sellHead)
                    {
                        sellOrders[_user] = sellHead;
                        sellHead = _user;
                    }
                    else
                    {
                        sellOrders[prevUserAdd] = _user;
                        sellOrders[_user] = address(curUser);
                    }
                    
                    return (0,soldShares,soldPrice);
                }
                
                prevUserAdd = address(curUser);
                curUser = User(sellOrders[address(curUser)]);
            }
        }
        
		// Failed
        return (-1,0,0);
    }
	
	// Checks if active sell orders can fulfill requested buy order
	function fulfillBuyOrder(address _user, uint _quantity, uint _price) private returns(uint _totalShares, uint _totalPrice)
    {
        if (sellHead == address(0)) return (99,0);
		
		User curUser = User(sellHead);
		User prevUser = curUser;
		
		while(address(curUser) != address(0) && _quantity > 0)
		{
			// Don't allow sell and buy orders to be paired from the same user
			if (address(curUser) == _user)
			{
				prevUser = curUser;
				curUser = User(sellOrders[address(curUser)]);
				continue;
			}
			
			(uint sold, uint forPrice, bool noLongerActive) = curUser.sellAvailable(symbol,_quantity,_price);
			
			if (sold > 0) 
			{
			    User(_user).sendPayment(curUser.owner(),forPrice,symbol,sold);
			}
			
			//outTrans._matchedUsers.push(address(curUser));
			_totalPrice += forPrice;
			_quantity -= sold;
			_totalShares += sold;
			
			if(noLongerActive)
				removeOrder(address(curUser), address(prevUser), false);
			if (_quantity <= 0)
				return (_totalShares, _totalPrice);
			
			prevUser = curUser;
			curUser = User(sellOrders[address(curUser)]);
		}
		
		return (_totalShares,_totalPrice);
    }
	
	// Remove this users buy or sell order from company listing
	// UPDATE: data not 'removed' from mapping for _remove user, just ignored. Consider some form of memory cleanup or an alt structure
	function removeOrder(address _remove, address _prev, bool _removeFromBuy) public
	{
		if (_remove != _prev && _remove != address(0) && _prev != address(0))
		{
		    if (_removeFromBuy)
			    buyOrders[_prev] = buyOrders[_remove];
			else
			    sellOrders[_prev] = sellOrders[_remove];
		}
	}
	
	// Checks if active buy orders can fulfill requested sell order
	function fulfillSellOrder(address _user, uint _quantity, uint _price) private returns(uint _totalShares, uint _totalPrice)
    {
        if (buyHead == address(0)) return (0,0);
		
		User curUser = User(buyHead);
		User prevUser = curUser;
		
		while(address(curUser) != address(0) && _quantity > 0)
		{
			// Don't allow sell and buy orders to be paired from the same user
			if (address(curUser) == _user)
			{
				prevUser = curUser;
				curUser = User(buyOrders[address(curUser)]);
				continue;
			}
			
			(uint bought,uint forPrice, bool noLongerActive) = curUser.buyAvailable(symbol,_quantity,_price);
			//if (bought > 0) curUser.sendPayment(User(_user).owner(),forPrice, symbol, bought);
			
			//outTrans._matchedUsers.push(address(curUser));
			_totalPrice += forPrice;
			_quantity -= bought;
			_totalShares += bought;
			
			if(noLongerActive)
				removeOrder(address(curUser), address(prevUser), true);
			if (_quantity <= 0)
				return (_totalShares, _totalPrice);
			
			prevUser = curUser;
			curUser = User(buyOrders[address(curUser)]);
		}
		
		return (_totalShares, _totalPrice);
    }
}