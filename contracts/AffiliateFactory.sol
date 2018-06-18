pragma solidity ^0.4.18;

import 'zeppelin-solidity/contracts/ownership/Ownable.sol';
import 'zeppelin-solidity/contracts/math/SafeMath.sol';
import './Affiliate.sol';

contract AffiliateFactory is Ownable {

    event AffiliateDeployed(address affiliateAddress, address targetAddress);

    address public target;
    address public beneficiary;
    address public WETH;
    uint public beneficiaryStake;
    uint public senderStake;
    mapping(address => bool) affiliates;

    constructor(address _target, address _weth, uint _beneficiaryStake, uint _senderStake) public Ownable() {
       update(_target, msg.sender, _weth, _beneficiaryStake, _senderStake);
    }

    function update(address _target, address _beneficiary, address _weth, uint _beneficiaryStake, uint _senderStake) public onlyOwner {
        target = _target;
        beneficiary = _beneficiary;
        beneficiaryStake = _beneficiaryStake;
        senderStake = _senderStake;
        WETH = _weth;
    }

    function signUp(address[] _stakeHolders, uint256[] _stakes)
        external
        returns (address affiliateContract)
    {
        require(_stakeHolders.length > 0 && _stakeHolders.length == _stakes.length);
        affiliateContract = createProxyImpl(target);
        address[] memory stakeHolders = new address[](_stakeHolders.length + 1);
        uint[] memory shares = new uint[](stakeHolders.length);
        stakeHolders[0] = beneficiary;
        shares[0] = beneficiaryStake;
        uint256 stakesTotal = 0;

        for(uint i=0; i < _stakeHolders.length; i++) {
          require(_stakes[i] > 0);
          stakesTotal = SafeMath.add(stakesTotal, _stakes[i]);
        }
        require(stakesTotal > 0);
        for(i=0; i < _stakeHolders.length; i++) {
          stakeHolders[i+1] = _stakeHolders[i];
          // (user stake) / (total stake) * (available stake) ; but with integer math
          shares[i+1] = SafeMath.mul(_stakes[i], senderStake) / stakesTotal ;
        }
        require(Affiliate(affiliateContract).init(this, stakeHolders, shares, WETH));
        affiliates[affiliateContract] = true;
        emit AffiliateDeployed(affiliateContract, target);
    }

    function registerAffiliate(address[] stakeHolders, uint[] shares)
        external
        onlyOwner
        returns (address affiliateContract)
    {
        affiliateContract = createProxyImpl(target);
        require(Affiliate(affiliateContract).init(this, stakeHolders, shares, WETH));
        affiliates[affiliateContract] = true;
        emit AffiliateDeployed(affiliateContract, target);
    }

    function isAffiliated(address _affiliate) external view returns (bool)
    {
        return affiliates[_affiliate];
    }

    function createProxyImpl(address _target)
        internal
        returns (address proxyContract)
    {
        assembly {
            let contractCode := mload(0x40) // Find empty storage location using "free memory pointer"

            mstore(add(contractCode, 0x0b), _target) // Add target address, with a 11 bytes [i.e. 23 - (32 - 20)] offset to later accomodate first part of the bytecode
            mstore(sub(contractCode, 0x09), 0x000000000000000000603160008181600b9039f3600080808080368092803773) // First part of the bytecode, shifted left by 9 bytes, overwrites left padding of target address
            mstore(add(contractCode, 0x2b), 0x5af43d828181803e808314602f57f35bfd000000000000000000000000000000) // Final part of bytecode, offset by 43 bytes

            proxyContract := create(0, contractCode, 60) // total length 60 bytes
            if iszero(extcodesize(proxyContract)) {
                revert(0, 0)
            }
        }
    }
}
