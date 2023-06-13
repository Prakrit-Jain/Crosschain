// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import "layerzero/token/oft/OFTCore.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract ProxyOFT is OFTCore {
    using SafeERC20 for IERC20;

    IERC20 internal immutable innerToken;

    /**
     * @dev Initializes the ProxyOFT contract.
     * @param _lzEndpoint The address of the LZ endpoint.
     * @param _token The address of the inner token contract.
     */
    constructor(address _lzEndpoint, address _token) OFTCore(_lzEndpoint) {
        innerToken = IERC20(_token);
    }
    /**
     * @dev Gets the circulating supply of the proxy token.
     * @return The circulating supply of the proxy token.
     */

    function circulatingSupply() public view virtual override returns (uint256) {
        unchecked {
            return innerToken.totalSupply() - innerToken.balanceOf(address(this));
        }
    }
    /**
     * @dev Gets the address of the inner token contract.
     * @return The address of the inner token contract.
     */

    function token() public view virtual override returns (address) {
        return address(innerToken);
    }

    /**
     * @dev Internal function to debit tokens from a specific address.
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
        require(_from == _msgSender(), "ProxyOFT: owner is not send caller");
        uint256 before = innerToken.balanceOf(address(this));
        innerToken.safeTransferFrom(_from, address(this), _amount);
        return innerToken.balanceOf(address(this)) - before;
    }

    /**
     * @dev Internal function to credit tokens to a specific address.
     * @param _toAddress The address to which tokens are credited.
     * @param _amount The amount of tokens to be credited.
     * @return The actual amount of tokens credited.
     */
    function _creditTo(uint16, address _toAddress, uint256 _amount) internal virtual override returns (uint256) {
        uint256 before = innerToken.balanceOf(_toAddress);
        innerToken.safeTransfer(_toAddress, _amount);
        return innerToken.balanceOf(_toAddress) - before;
    }
}
