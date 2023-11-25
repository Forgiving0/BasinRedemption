//SPDX-License-Identifier: None
pragma solidity =0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract BasinRedemption {
    address private owner;
    IERC20 private BASIN = IERC20(0x4788de271F50EA6f5D5D2a5072B8D3C61d650326);
    IERC20 private DAI = IERC20(0x50c5725949A6F0c72E6C4a641F24049A917DB0Cb);
    uint256 public redemptionPrice = 830000000000000000; // $0.83 redemption price

    address public treasury = 0x23014067c5bAb5f89d3f97727C06AFBffB4867c8;
    uint256 private supply;
    uint256 public totalRedeemed = 0;

    address[] private paymentRecipients;
    uint256[] private paymentAmounts;

    bool private _locked = false;

    constructor(uint256 _supply, address[] memory _paymentRecipients, uint256[] memory _paymentAmounts) {
        require(_paymentRecipients.length == _paymentAmounts.length, "Redemption: mismatch");
        owner = msg.sender;
        supply = _supply;
        paymentRecipients = new address[](_paymentRecipients.length);
        paymentAmounts = new uint256[](_paymentAmounts.length);

        for (uint256 i = 0; i < _paymentRecipients.length; i++) {
            paymentRecipients[i] = _paymentRecipients[i];
            paymentAmounts[i] = _paymentAmounts[i];
        }
    }

    modifier onlyOwner {
        require(owner == msg.sender, "Redemption: caller is not the owner");
        _;
    }

    modifier noReentrancy {
        require(!_locked, "Reentrancy: reentrant call invalid");
        _locked = true;
        _;
        _locked = false;
    }

    function redeem(uint256 _amount) external noReentrancy {
        require(totalRedeemed < supply, "all claimed");
        totalRedeemed += _amount;
        BASIN.transferFrom(msg.sender, treasury, _amount);
        DAI.transfer(msg.sender, (_amount * redemptionPrice) / 1e18);
    }

    function distributePayment() external {
        bool valid = false;
        uint256 i;
        for (uint256 j = 0; j < paymentRecipients.length; j++) {
            if (msg.sender == paymentRecipients[j]) {
                valid = true;
                i = j;
            }
        }

        require(valid, "Redemption: caller not eligible");
        DAI.transfer(paymentRecipients[i], paymentAmounts[i]);
        paymentAmounts[i] = 0;
    }

    function recover(address _token, uint256 _amount) external onlyOwner {
        IERC20 token = IERC20(_token);
        token.transfer(owner, _amount);
    }

    function call(address payable _to, uint256 _value, bytes calldata _data) external payable onlyOwner returns (bytes memory) {
        (bool success, bytes memory result) = _to.call{value: _value}(_data);
        require(success, "Redemption: external call failed");
        return result;
    }
}
