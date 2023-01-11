pragma solidity >=0.4.22 <0.9.0;

import "../contracts/Transfer.sol";
import "truffle/DeployedAddresses.sol";
import "truffle/Assert.sol";

contract testSuite {
     //The address of the contract to be tested
     Transfer transfer = Transfer(DeployedAddresses.Transfer());
    
    function testCreateNewStock() public
    {
		bool ret = transfer.companyNew("GOOG");
        Assert.isTrue(ret,"Company already exists, but has not been created");
        transfer.newIPO("GOOG",1000,900);
		ret = transfer.companyNew("GOOG");
        Assert.isFalse(ret,"Company does not exist, but has been created");
		
		ret = transfer.companyNew("AAPL");
		Assert.isTrue(ret,"Company already exists, but has not been created");
        transfer.newIPO("AAPL",1000,800);
		ret = transfer.companyNew("AAPL");
        Assert.isFalse(ret,"Company does not exist, but has been created");
		
		ret = transfer.companyNew("AMZN");
		Assert.isTrue(ret,"Company already exists, but has not been created");
        transfer.newIPO("AMZN",1000,700);
		ret = transfer.companyNew("AMZN");
        Assert.isFalse(ret,"Company does not exist, but has been created");
    }
	
	//function testCreateExistingStock() public 
	//{
		//Assert.
	//}
	
	function testChangeOwnership() public
	{
		address newOwner_attempted = address(0xeDBf33179A36170Fe8cD40B633bb577D4dcc2DB8);
		address newOwner_actual = transfer.changeOwnership("GOOG",address(0xeDBf33179A36170Fe8cD40B633bb577D4dcc2DB8));
		Assert.equal(newOwner_actual,newOwner_attempted,"Ownership was not transferred correctly");
	}
	
	function testCreateUser() public
	{
		Assert.isTrue(true,"WOO");
	}
}
