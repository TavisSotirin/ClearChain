// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0 <0.9.0;

import "./SharedLib.sol";

contract User
{
    struct Transaction
    {
        uint quantity;
        uint price;
    }
    
    struct Stock
    {
        string symbol;
        uint owned;
        Transaction[] buyOrders;
        Transaction[] sellOrders;
    }
    
    address payable public owner;
	mapping(uint => string) public stockListIndex; //private
    mapping(string => Stock) public stockList;
	uint stockCount = 0;
	
	constructor(address payable _owner, string memory _symbol, uint _quantity, uint _priceLimit)
	{
		owner = _owner;
		stockListIndex[stockCount] = "NULL";
		
		if (!SL.compareStrings(_symbol,""))
    	{
    	    _symbol = SL.toUpper(_symbol);
    	    
    	    stockList[_symbol].symbol = _symbol;
    		stockList[_symbol].owned = 0;
    			
    		stockListIndex[++stockCount] = _symbol;
    		stockList[_symbol].sellOrders.push(Transaction(_quantity,_priceLimit));
    	}
	}
	
	function addValue(uint _quantity, uint _priceLimit) public payable
	{
		require(msg.value == _quantity * _priceLimit,"User contract didn't receive required eth");
	}
	
	function returnCredit(uint amount) public payable
	{
        require(address(this).balance >= amount,"User does not have enough credit for return request");
        (bool sent, ) = owner.call{value: amount}("");
        if (!sent) revert("Failed to send Ether");
    }
	
	function addBuyOrder(string memory _symbol, uint _quantity, uint _priceLimit) public payable
    {
        _symbol = SL.toUpper(_symbol);
        
        if(SL.compareStrings(stockList[_symbol].symbol,""))
        {
			stockList[_symbol].symbol = _symbol;
			stockList[_symbol].owned = 0;
			
			stockListIndex[++stockCount] = _symbol;
        }
			
		stockList[_symbol].buyOrders.push(Transaction(_quantity,_priceLimit));
    }
    
    function addSellOrder(string memory _symbol, uint _quantity, uint _priceLimit) public payable
    {
		_symbol = SL.toUpper(_symbol);
		require(!SL.compareStrings(stockList[_symbol].symbol,""), "User does not own any of the given stock");
		require(stockList[_symbol].owned >= _quantity,"User does not own enough of the given stock");
		
		stockList[_symbol].owned -= _quantity;
			
		stockList[_symbol].sellOrders.push(Transaction(_quantity,_priceLimit));
    }
	
	function deleteTransaction(string memory _symbol, uint index, bool removeFromBuy) private returns(bool)
	{
		Transaction[] storage array = removeFromBuy ? stockList[_symbol].buyOrders : stockList[_symbol].sellOrders;

		if (index >= array.length) return false;

		for (uint i = index; i<array.length-1; i++)
			array[i] = array[i+1];

		array.pop();
		return true;
	}
	
	// Send eth for fulfilled orders
	function sendPayment(address payable _to, uint amount, string memory symbol, uint sold) public payable
	{
		require(address(this).balance >= amount);
		(bool sent,) = _to.call{value: amount}("");
		if (!sent) revert("Failed to send Ether to user contract");
		
		stockList[symbol].owned += sold;
	}
	
	function checkBuyPrice(string memory _symbol) public view returns(uint)
    {  
        if (stockList[_symbol].buyOrders.length <= 0) return 0;
    	return stockList[_symbol].buyOrders[0].price;
    }
    
    function checkSellPrice(string memory _symbol) public view returns(uint)
    {
        if (stockList[_symbol].sellOrders.length <= 0) return 0;
    	return stockList[_symbol].sellOrders[0].price;
    }
    
    function sellAvailable(string memory _symbol, uint _quantity, uint _price) public returns(uint sold, uint forPrice, bool noLongerActive)
	{
		sold = 0;
		forPrice = 0;
		
		// Loop sell orders
		for (uint i = 0; i < stockList[_symbol].sellOrders.length && _quantity >= 0; i++)
		{
			Transaction memory tr = stockList[_symbol].sellOrders[i];
			
			if (tr.price <= _price)
			{
				if (tr.quantity > _quantity)
				{
					tr.quantity -= _quantity;
					
					sold += _quantity;
					forPrice += _quantity * tr.price;
					
					_quantity = 0;
				}
				else if (tr.quantity == _quantity)
				{
					sold += _quantity;
					forPrice += _quantity * tr.price;
					
					_quantity = 0;
					deleteTransaction(_symbol, i, false);
				}
				else
				{
					sold += _quantity;
					forPrice += _quantity * tr.price;
					
					_quantity -= tr.quantity;
					deleteTransaction(_symbol, i, false);
				}
			}
			else
				break;
		}
		
		noLongerActive = stockList[_symbol].sellOrders.length > 0;
	}
	
	function buyAvailable(string memory _symbol, uint _quantity, uint _price) public returns(uint bought, uint forPrice, bool noLongerActive)
	{
		bought = 0;
		forPrice = 0;
		
		// Loop buy orders
		for (uint i = 0; i < stockList[_symbol].buyOrders.length && _quantity >= 0; i++)
		{
			Transaction memory tr = stockList[_symbol].buyOrders[i];
			
			if (tr.price >= _price)
			{
				if (tr.quantity > _quantity)
				{
					tr.quantity -= _quantity;
					
					bought += _quantity;
					forPrice += _quantity * tr.price;
					
					_quantity = 0;
				}
				else if (tr.quantity == _quantity)
				{
					uint priceActual = tr.price > _price ? _price : tr.price;
				
					bought += _quantity;
					forPrice += _quantity * priceActual;
					
					_quantity = 0;
					deleteTransaction(_symbol, i, true);
				}
				else
				{
					uint priceActual = tr.price > _price ? _price : tr.price;
					
					bought += _quantity;
					forPrice += _quantity * priceActual;
					
					_quantity -= tr.quantity;
					deleteTransaction(_symbol, i, true);
				}
			}
			else
				break;
		}
		
		noLongerActive = stockList[_symbol].buyOrders.length > 0;
	}
	
	function getAmountOfShares(string memory _symbol) public view returns(uint)
	{
		_symbol = SL.toUpper(_symbol);
		return stockList[_symbol].owned;
	}
}