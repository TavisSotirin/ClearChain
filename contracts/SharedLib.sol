// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0 <0.9.0;

library SL
{
    function toUpper(string memory str) internal pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bUpper = new bytes(bStr.length);
        for (uint i = 0; i < bStr.length; i++) {
            // Uppercase character...
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90))
                bUpper[i] = bStr[i];
            // Lowercase - make upper by -32
            else 
                bUpper[i] = bytes1(uint8(bStr[i]) - 32);
        }
        return string(bUpper);
    }
    
    function compareStrings(string memory a, string memory b) public pure returns (bool) 
    {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
}