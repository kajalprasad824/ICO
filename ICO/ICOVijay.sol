// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

library SafeMath {
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function decimals() external view returns (uint8);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract ICO is Ownable {
    using SafeMath for uint256;
    IERC20 KP_token;
    uint256 lockingTime;
    uint256 startingTime;
    uint256 minValue;
    uint256 public preSaleRate;
    uint256 public totalHardCap;
    uint256 lockingPeriod = 1 weeks;
    address payable public Owner;
    address private KPContractAddress;
    address[] private allBuyerAddress;

    struct roundTimeInfo {
        uint256 r1StartTime;
        uint256 r1EndTime;
        uint256 r2StartTime;
        uint256 r2EndTime;
        uint256 r3StartTime;
        uint256 r3EndTime;
    }
    roundTimeInfo public RoundTimeInfo;

    struct roundHardCapInfo {
        uint256 r1HardCap;
        uint256 r2HardCap;
        uint256 r3HardCap;
    }
    roundHardCapInfo public RoundHardCapInfo;

    struct roundTokenSaleInfo {
        uint256 r1SoldToken;
        uint256 r1TokenForSale;
        uint256 r2SoldToken;
        uint256 r2TokenForSale;
        uint256 r3SoldToken;
        uint256 r3TokenForSale;
        uint256 totalSoldToken;
    }
    roundTokenSaleInfo public RoundTokenSaleInfo;

    struct userInfo {
        uint256 KPBuyToken;
        uint256 bonusToken;
        uint256 totalToken;
        uint256 totalDollar;
        uint256 claimedToken;
        uint256 remainClaimedToken;
        uint256 totalVestingRound;
        uint256 currentVestingRound;
    }
    mapping(address => userInfo) public UserInfo;

    struct whiteListUser {
        bool allow;
    }
    mapping(address => whiteListUser) public WhiteListUser;

    struct ICOinfo {
        uint256 raisedTotaldollar;
        uint256 soldKPToken;
    }
    ICOinfo public ICOInfo;

    enum currencyType {
        native,
        token
    }

    constructor(
        address _KPContractAddress,
        uint256 _startingTime,
        uint256 _presaleRate
    ) {
        require(
            _startingTime >= block.timestamp,
            "ICO start time should be equal or greater than current time"
        );

        Owner = payable(msg.sender);
        KPContractAddress = _KPContractAddress;
        KP_token = IERC20(_KPContractAddress);
        preSaleRate = _presaleRate;

        minValue = 250 * 10000;

        totalHardCap = 222000000 * 10**KP_token.decimals();

        RoundTimeInfo.r1StartTime = _startingTime;
        RoundTimeInfo.r1EndTime = RoundTimeInfo.r1StartTime + 45 days - 1;
        RoundTimeInfo.r2StartTime = RoundTimeInfo.r1EndTime + 1;
        RoundTimeInfo.r2EndTime = RoundTimeInfo.r2StartTime + 45 days - 1;
        RoundTimeInfo.r3StartTime = RoundTimeInfo.r2EndTime + 1;
        RoundTimeInfo.r3EndTime = RoundTimeInfo.r3StartTime + 45 days;

        RoundHardCapInfo.r1HardCap = 59940000 * 10**KP_token.decimals();
        RoundHardCapInfo.r2HardCap = 73260000 * 10**KP_token.decimals();
        RoundHardCapInfo.r3HardCap = 88800000 * 10**KP_token.decimals();

        RoundTokenSaleInfo.r1TokenForSale = RoundHardCapInfo.r1HardCap;
        RoundTokenSaleInfo.r2TokenForSale = RoundHardCapInfo.r2HardCap;
        RoundTokenSaleInfo.r3TokenForSale = RoundHardCapInfo.r3HardCap;
    }

    //-------------------------------------Functions only Owner can call------------------------------------------------------

    //-------------------------Functions to update round sale timing-----------------------------

    //Function to update round 1 timing
    function updateRound1Time(uint256 _startTime, uint256 _endTime)
        public
        onlyOwner
        returns (bool)
    {
        require(
            _startTime < _endTime,
            "End Time should be greater than start time"
        );
        require(
            _endTime > block.timestamp,
            "End Time should be greater than Current Time"
        );

        if (block.timestamp > RoundTimeInfo.r1StartTime) {
            require(
                _startTime == RoundTimeInfo.r1StartTime,
                "You can not change the start time"
            );
        }
        RoundTimeInfo.r1StartTime = _startTime;
        RoundTimeInfo.r1EndTime = _endTime;

        return true;
    }

    //Function to update round 2 timing
    function updateRound2Time(uint256 _startTime, uint256 _endTime)
        public
        onlyOwner
        returns (bool)
    {
        require(
            _startTime < _endTime,
            "End Time should be greater than start time"
        );
        require(
            _endTime > block.timestamp,
            "End Time should be greater than Current Time"
        );

        if (block.timestamp > RoundTimeInfo.r2StartTime) {
            require(
                _startTime == RoundTimeInfo.r2StartTime,
                "You can not change the start time"
            );
        }
        RoundTimeInfo.r2StartTime = _startTime;
        RoundTimeInfo.r2EndTime = _endTime;

        return true;
    }

    //Function to update round 3 timing
    function updateRound3Time(uint256 _startTime, uint256 _endTime)
        public
        onlyOwner
        returns (bool)
    {
        require(
            _startTime < _endTime,
            "End Time should be greater than start time"
        );
        require(
            _endTime > block.timestamp,
            "End Time should be greater than Current Time"
        );

        if (block.timestamp > RoundTimeInfo.r3StartTime) {
            require(
                _startTime == RoundTimeInfo.r3StartTime,
                "You can not change the start time"
            );
        }
        RoundTimeInfo.r3StartTime = _startTime;
        RoundTimeInfo.r3EndTime = _endTime;

        return true;
    }

    //----------------------------------------------------------------------------

    //Function to update min value
    function updateMinValue(uint256 _minValue) public onlyOwner returns (bool) {
        minValue = _minValue;
        return true;
    }

    //----------------------------------------------------------------------------

    //function to update pre sale rate
    function updatePresaleRate(uint256 _presaleRate)
        public
        onlyOwner
        returns (bool)
    {
        preSaleRate = _presaleRate;
        return true;
    }

    //----------------------------------------------------------------------------

    //------------------Functions for White Listed User---------------------------

    //Function to Add White Listed User
    function whiteListedUser(address[] memory _buyers)
        public
        onlyOwner
        returns (bool)
    {
        for (uint256 i = 0; i < _buyers.length; i++) {
            if (WhiteListUser[_buyers[i]].allow == false) {
                WhiteListUser[_buyers[i]].allow = true;
            }
        }
        return true;
    }

    //Function to remove White Listed User
    function whiteListedUserRemove(address[] memory _buyers)
        public
        onlyOwner
        returns (bool)
    {
        for (uint256 i = 0; i < _buyers.length; i++) {
            if (WhiteListUser[_buyers[i]].allow == true) {
                WhiteListUser[_buyers[i]].allow = false;
            }
        }
        return true;
    }

    function retrieveStuckedERC20Token(
        address _tokenAddr,
        uint256 _amount,
        address _toWallet
    ) public onlyOwner returns (bool) {
        IERC20(_tokenAddr).transfer(_toWallet, _amount);
        return true;
    }

    //------------------------------------------------------------------------------------------

    function round()
        public
        view
        returns (string memory _round, uint256 endTime)
    {
        if (
            block.timestamp >= RoundTimeInfo.r1StartTime &&
            block.timestamp <= RoundTimeInfo.r1EndTime
        ) {
            string memory Round = "Round 1";
            return (Round, RoundTimeInfo.r1EndTime);
        } else if (
            block.timestamp >= RoundTimeInfo.r2StartTime &&
            block.timestamp <= RoundTimeInfo.r2EndTime
        ) {
            string memory Round = "Round 2";
            return (Round, RoundTimeInfo.r2EndTime);
        } else if (
            block.timestamp >= RoundTimeInfo.r3StartTime &&
            block.timestamp <= RoundTimeInfo.r3EndTime
        ) {
            string memory Round = "Round 3";
            return (Round, RoundTimeInfo.r3EndTime);
        } else {
            require(false, "Please check ICO time");
        }
    }

    function isICOOverRound1() public view returns (bool) {
        if (
            block.timestamp > RoundTimeInfo.r1EndTime ||
            RoundTokenSaleInfo.r1TokenForSale == 0
        ) {
            return true;
        } else {
            return false;
        }
    }

    function isICOOverRound2() public view returns (bool) {
        if (
            block.timestamp > RoundTimeInfo.r2EndTime ||
            RoundTokenSaleInfo.r2TokenForSale == 0
        ) {
            return true;
        } else {
            return false;
        }
    }

    function isICOOverRound3() public view returns (bool) {
        if (
            block.timestamp > RoundTimeInfo.r3EndTime ||
            RoundTokenSaleInfo.r3TokenForSale == 0
        ) {
            return true;
        } else {
            return false;
        }
    }

    //------------------------------------------------------------------------------------------

    function buy(
        uint256 _dollar,
        currencyType CurrencyType,
        address _tokenContractAddress
    ) public payable returns (bool) {
        require(
            _dollar >= minValue,
            "Please purchase at least minimum amount of tokens"
        );

        uint256 buyToken = (_dollar * 10**KP_token.decimals()) / preSaleRate;

        if (
            block.timestamp >= RoundTimeInfo.r1StartTime &&
            block.timestamp <= RoundTimeInfo.r1EndTime
        ) {
            require(
                buyToken <= RoundTokenSaleInfo.r1TokenForSale,
                "Not enough token for sale"
            );

            require(
                WhiteListUser[msg.sender].allow == true,
                "You are not a white listed user for round 1 sale"
            );

            require(isICOOverRound1() == false, "Sale Round 1 is already over");

            uint256 bonusToken = (buyToken * 30) / 100;
            uint256 totalToken = bonusToken + buyToken;
            if (UserInfo[msg.sender].KPBuyToken == 0) {
                UserInfo[msg.sender] = userInfo(
                    buyToken,
                    bonusToken,
                    totalToken,
                    _dollar,
                    0,
                    totalToken,
                    10,
                    0
                );
                allBuyerAddress.push(msg.sender);
            } else {
                UserInfo[msg.sender].KPBuyToken += buyToken;
                UserInfo[msg.sender].bonusToken += bonusToken;
                UserInfo[msg.sender].totalToken += totalToken;
                UserInfo[msg.sender].totalDollar += _dollar;
                UserInfo[msg.sender].remainClaimedToken += totalToken;
            }

            RoundTokenSaleInfo.r1TokenForSale -= buyToken;
            RoundTokenSaleInfo.r1SoldToken += buyToken;
        } else if (
            block.timestamp >= RoundTimeInfo.r2StartTime &&
            block.timestamp <= RoundTimeInfo.r2EndTime
        ) {
            require(
                buyToken <= RoundTokenSaleInfo.r2TokenForSale,
                "Not enough token for sale"
            );

            require(isICOOverRound2() == false, "Sale Round 2 is already over");
            uint256 bonusToken = (buyToken * 20) / 100;
            uint256 totalToken = bonusToken + buyToken;
            if (UserInfo[msg.sender].KPBuyToken == 0) {
                UserInfo[msg.sender] = userInfo(
                    buyToken,
                    bonusToken,
                    totalToken,
                    _dollar,
                    0,
                    totalToken,
                    10,
                    0
                );
                allBuyerAddress.push(msg.sender);
            } else {
                UserInfo[msg.sender].KPBuyToken += buyToken;
                UserInfo[msg.sender].bonusToken += bonusToken;
                UserInfo[msg.sender].totalToken += totalToken;
                UserInfo[msg.sender].totalDollar += _dollar;
                UserInfo[msg.sender].remainClaimedToken += totalToken;
            }

            RoundTokenSaleInfo.r2TokenForSale -= buyToken;
            RoundTokenSaleInfo.r2SoldToken += buyToken;
        } else if (
            block.timestamp >= RoundTimeInfo.r3StartTime &&
            block.timestamp <= RoundTimeInfo.r3EndTime
        ) {
            require(
                buyToken <= RoundTokenSaleInfo.r3TokenForSale,
                "Not enough token for sale"
            );

            require(isICOOverRound3() == false, "Sale Round 3 is already over");

            uint256 bonusToken = (buyToken * 10) / 100;
            uint256 totalToken = bonusToken + buyToken;

            if (UserInfo[msg.sender].KPBuyToken == 0) {
                UserInfo[msg.sender] = userInfo(
                    buyToken,
                    bonusToken,
                    totalToken,
                    _dollar,
                    0,
                    totalToken,
                    10,
                    0
                );
                allBuyerAddress.push(msg.sender);
            } else {
                UserInfo[msg.sender].KPBuyToken += buyToken;
                UserInfo[msg.sender].bonusToken += bonusToken;
                UserInfo[msg.sender].totalToken += totalToken;
                UserInfo[msg.sender].totalDollar += _dollar;
                UserInfo[msg.sender].remainClaimedToken += totalToken;
            }

            RoundTokenSaleInfo.r3TokenForSale -= buyToken;
            RoundTokenSaleInfo.r3SoldToken += buyToken;
        } else {
            require(false, "Please check ICO time");
        }

        RoundTokenSaleInfo.totalSoldToken += buyToken;

        ICOInfo.raisedTotaldollar += _dollar;
        ICOInfo.soldKPToken += buyToken;

        if (CurrencyType == currencyType.native) {
            payable(Owner).call{value: msg.value};
        } else {
            IERC20(_tokenContractAddress).transferFrom(
                msg.sender,
                Owner,
                msg.value
            );
        }

        return true;
    }

    function vesting() public returns (bool) {
        require(isICOOverRound3() == true, "Please wait for ICO to end");
        require(
            UserInfo[msg.sender].KPBuyToken > 0,
            "OOps, Its looks like you are not the buyer"
        );

        lockingTime =
            RoundTimeInfo.r3EndTime +
            lockingPeriod +
            UserInfo[msg.sender].currentVestingRound *
            lockingPeriod;

        if (block.timestamp >= lockingTime) {
            require(
                UserInfo[msg.sender].currentVestingRound <
                    UserInfo[msg.sender].totalVestingRound,
                "Your all vesting round is complete"
            );

            uint256 claimedToken = (10 * UserInfo[msg.sender].totalToken) / 100;
            KP_token.transfer(msg.sender, claimedToken);
            UserInfo[msg.sender].claimedToken += claimedToken;
            UserInfo[msg.sender].remainClaimedToken -= claimedToken;
            UserInfo[msg.sender].currentVestingRound += 1;
        } else {
            require(
                false,
                "You can not call vesting function. Please wait for locking period to end"
            );
        }
        return true;
    }
}

//["0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2","0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db"]
//["0x882c98AB4c5D3C5deC31a9737B5Ba0903D1614D5","0x2b1A680FA024997FB305A966C99954bD01fa5640","0x76a102F628A07C12719B875200e83811B28d4Fa5"]
