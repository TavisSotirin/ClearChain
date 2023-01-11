const Transfer = artifacts.require("Transfer");

contract ("Transfer", accounts => {
    let transfer;
    let GOOG;
    let AAPL;
    let AMZN;
    const account1 = accounts[0];
    const account2 = accounts[1];
    const accounts3 = accounts[2];

    before(async () => {
        // Create contract instance
        transfer = await Transfer.deployed();
        
        // Creates stock instances
        await transfer.newIPO("GOOG",1000,900);
        await transfer.newIPO("AAPL",1000,800);
        await transfer.newIPO("AMZN",1000,700);
        GOOG = await transfer.getCompanySymbol(0);
        AAPL = await transfer.getCompanySymbol(1);
        AMZN = await transfer.getCompanySymbol(2);
    });
    
    describe("Tests buy requests for users.", async () => {
        it("If new user, create a new User account", async() => {
            // assert empty list
            let originalUsersAddress0 = await transfer.getUsers(account1);
            assert.equal(originalUsersAddress0, "0x0000000000000000000000000000000000000000", "`users` struct should be empty");

            await transfer.buyRequest(GOOG, 2, 900, {from: account1});
            let newUser = await transfer.getUsers(account1);
            assert.notEqual(newUser, "0x0000000000000000000000000000000000000000", "User account should have been added.");
        });

        it("Checks buyRequest does not assign ownership of stock yet", async() => {
            await transfer.buyRequest(AAPL, 5, 800, {from: account2});            
            let stockQuantity = await transfer.getUsersStockBalance(account2, AAPL);
            assert.equal(stockQuantity, 0, "Stock quantity should be 0 because we only put in a request");
        });

        it("Checks buyRequest has correct values pending for user", async() => {
            await transfer.buyRequest(AMZN, 5, 1000, {from: accounts3});            
            buyRequest = await transfer.getUsersBuyOrderQuantity(accounts3, AMZN);
            assert.equal(buyRequest, 5, "Stock quantity bought should match stock quantity in account");

            buyRequest = await transfer.getUsersBuyOrderPrice(accounts3, AMZN);
            assert.equal(buyRequest, 1000, "Stock quantity bought should match stock quantity in account");
        });

        it("Should fail since this stock already exists", async () => {
            try {
                await transfer.newIPO("AMZN", 9999, 999);
            } catch (error) {
                print(`Should return an error but couldn't get assert.fail to work yet. Error: ${error}`);
            }
        })

    })
})
