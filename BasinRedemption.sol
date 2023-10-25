//SPDX-License-Identifier: None
pragma solidity =0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract BasinRedemption {
    address public owner;
    IERC20 public BASIN = IERC20(0x4788de271F50EA6f5D5D2a5072B8D3C61d650326);
    IERC20 public DAI = IERC20(0x50c5725949A6F0c72E6C4a641F24049A917DB0Cb);
    uint256 public redemptionPrice = 830000000000000000; // $0.83 redemption price

    address[] public admin = [0x6e1D1ca17cEb36d5A41EFc5743F4B26D497cC266, 0x6fE9A453Fa576991B564B40F153F18E2F17A0796];
    bool[] public adminSkim = [false, false];

    address public treasury = 0x23014067c5bAb5f89d3f97727C06AFBffB4867c8;
    uint256 public supply;
    uint256 public daiToRedeem = supply * redemptionPrice;
    uint256 public excess = (DAI.balanceOf(address(this)) - daiToRedeem);


    constructor(uint256 _supply) {
        owner = msg.sender;
        supply = _supply;
    }

    modifier onlyOwner {
        require(owner == msg.sender, "Caller is not the owner");
        _;
    }

    modifier onlyAdmin(uint256 _id) {
        require(msg.sender == admin[_id], "caller is not admin");
    }

    function redeem(uint256 _amount) external {
        BASIN.transferFrom(msg.sender, treasury, _amount);
        DAI.transfer(msg.sender, (_amount * redemptionPrice));
    }

    function skim(uint256 _id) external onlyAdmin {
        require(!adminSkim[_id], "already claimed");

        DAI.transfer(admin[_id], excess / 2 - 1);

        adminSkim[_id] = true;
    }

    function recover(address _token, uint256 _amount) external onlyOwner {
        IERC20 token = IERC20(_token);
        token.transfer(owner, _amount);
    }

    function call(address payable _to, uint256 _value, bytes calldata _data) external payable onlyOwner returns (bytes memory) {
        (bool success, bytes memory result) = _to.call{value: _value}(_data);
        require(success, "External call failed");
        return result;
    }
}
