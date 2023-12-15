// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity =0.8.18;

import "./Counter.sol";
import "@hyperlane/solidity/contracts/libs/TypeCasts.sol";
import "@hyperlane/solidity/contracts/interfaces/IMessageRecipient.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";

contract Recieve is IMessageRecipient {
    /**
     * @dev An event emitted when a message is received, providing information about the origin, sender, and message body.
     */
    event Received(uint32 origin, address sender, bytes body);

    address counterAddress;
    address tokenAddress;

    constructor(address _counterAddress, address _tokenAddress) {
        counterAddress = _counterAddress;
        tokenAddress = _tokenAddress;
    }

    /**
     * @notice This handle function is used to handle the interchain data(message) recieved from origin chain.
     * @dev This function decode the body and then further calls the counter contract to increment the value
     * and also sets allowance for the spender account by calling permit function. Also emit the Recieved event
     * if function call successfully.
     * @param _origin Domain ID of the chain from which the message came
     * @param _sender Address of the message sender on the origin chain as bytes32
     * @param _body Raw bytes content of message body
     */
    function handle(uint32 _origin, bytes32 _sender, bytes calldata _body) external {
        (uint256 value, address owner, address spender, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        = abi.decode(_body, (uint256, address, address, uint256, uint256, uint8, bytes32, bytes32));

        Counter counter = Counter(counterAddress);
        IERC20Permit token = IERC20Permit(tokenAddress);
        counter.increment(value);
        token.permit(owner, spender, amount, deadline, v, r, s);
        address sender = TypeCasts.bytes32ToAddress(_sender);
        emit Received(_origin, sender, _body);
    }
}
