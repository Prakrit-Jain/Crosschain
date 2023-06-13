// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import "layerzero/token/oft/OFTCore.sol";
import "layerzero/token/oft/IOFT.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

contract OFT is OFTCore, ERC20, IOFT {
    /**
     * @dev Initializes the OFT contract.
     * @param _name The name of the token.
     * @param _symbol The symbol of the token.
     * @param _lzEndpoint The address of the LZ endpoint.
     */
    constructor(string memory _name, string memory _symbol, address _lzEndpoint)
        ERC20(_name, _symbol)
        OFTCore(_lzEndpoint)
    {}

    /**
     * @dev Checks if the contract supports the given interface.
     * @param interfaceId The interface identifier.
     * @return A boolean value indicating whether the contract supports the interface.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(OFTCore, IERC165) returns (bool) {
        return interfaceId == type(IOFT).interfaceId || interfaceId == type(IERC20).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Gets the address of the token contract.
     * @return The address of the token contract.
     */
    function token() public view virtual override returns (address) {
        return address(this);
    }

    /**
     * @dev Gets the circulating supply of the token.
     * @return The circulating supply of the token
     */
    function circulatingSupply() public view virtual override returns (uint256) {
        return totalSupply();
    }

    /**
     * @dev Function to debit tokens from a specific address.
     * @param _from The address from which tokens are debited.
     * @param _amount The amount of tokens to be debited.
     * @return The actual amount of tokens debited.
     */
    function _debitFrom(address _from, uint16, bytes memory, uint256 _amount)
        internal
        virtual
        override
        returns (uint256)
    {
        address spender = _msgSender();
        if (_from != spender) _spendAllowance(_from, spender, _amount);
        _burn(_from, _amount);
        return _amount;
    }

    /**
     * @dev Function to credit tokens to a specific address.
     * @param _toAddress The address to which tokens are credited.
     * @param _amount The amount of tokens to be credited.
     * @return The actual amount of tokens credited.
     */
    function _creditTo(uint16, address _toAddress, uint256 _amount) internal virtual override returns (uint256) {
        _mint(_toAddress, _amount);
        return _amount;
    }
}
