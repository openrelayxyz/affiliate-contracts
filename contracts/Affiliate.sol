pragma solidity ^0.4.4;

import 'zeppelin-solidity/contracts/math/SafeMath.sol';
import 'zeppelin-solidity/contracts/token/ERC20/ERC20.sol';
import './WETH9.sol';

interface Registry {
    function isAffiliated(address _affiliate) external returns (bool);
}

contract Affiliate {
  struct Share {
      address shareholder;
      uint stake;
  }

  Share[] shares;
  uint public totalShares;
  address registry;
  WETH9 weth;

  event Payout(address indexed token, uint amount);

  function init(address _registry, address[] shareholders, uint[] stakes, address _weth) public returns (bool) {
    require(totalShares == 0);
    require(shareholders.length == stakes.length);
    weth = WETH9(_weth);
    totalShares = 0;
    for(uint i=0; i < shareholders.length; i++) {
        shares.push(Share({shareholder: shareholders[i], stake: stakes[i]}));
        totalShares += stakes[i];
    }
    registry = _registry;
    return true;
  }
  function payout(address[] tokens) public {
      // Payout all stakes at once, so we don't have to do bookkeeping on who has
      // claimed their shares and who hasn't. If the number of shareholders is large
      // this could run into some gas limits. In most cases, I expect two
      // shareholders, but it could be a small handful. This also means the caller
      // must pay gas for everyone's payouts.
      for(uint i=0; i < tokens.length; i++) {
          ERC20 token = ERC20(tokens[i]);
          uint balance = token.balanceOf(this);
          for(uint j=0; j < shares.length; j++) {
              token.transfer(shares[j].shareholder, SafeMath.mul(balance, shares[j].stake) / totalShares);
          }
          emit Payout(tokens[i], balance);
      }
  }
  function isAffiliated(address _affiliate) public returns (bool)
  {
      return Registry(registry).isAffiliated(_affiliate);
  }

  function() public payable {
    // If we get paid in ETH, convert to WETH so payouts work the same.
    // Converting to WETH also makes payouts a bit safer, as we don't have to
    // worry about code execution if the stakeholder is a contract.
    weth.deposit.value(msg.value)();
  }

}
