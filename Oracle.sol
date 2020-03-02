pragma solidity 0.6.3;

contract Oracle{
    
    address public owner;
    
    modifier onlyOwner {
        require(msg.sender == owner, "Not authorized");
        _;
    }
    
    modifier validChannel (uint8 _channelNo){
        require(_channelNo == 1 || _channelNo == 6 || _channelNo==11, "Channel is not valid");
        _;
    }
    
    struct ChannelInfo {
        uint8 channelNo;
        uint8 percentageUsage;
        uint256 noStationsOnChannel;
        uint256 noStationsAffectingChannel;
    }
    
    ChannelInfo[3] public infoList;
    
    mapping(uint8 => uint8) channelToIndex;
    
    constructor () public {
        owner = msg.sender;
        
        channelToIndex[1] = 0;
        channelToIndex[6] = 1;
        channelToIndex[11] = 2;
        
        infoList[0] = ChannelInfo(1,0,0,0);
        infoList[1] = ChannelInfo(6,0,0,0);
        infoList[2] = ChannelInfo(11,0,0,0);
        
    }
    
    function submitInfo(uint8 _channelNo,
                        uint8 _percentage, 
                        uint256 _noStationsOnChannel, 
                        uint256 _noStationsAffectingChannel) 
    public onlyOwner validChannel(_channelNo){
        
        infoList[channelToIndex[_channelNo]] = ChannelInfo(_channelNo,_percentage,_noStationsOnChannel, _noStationsAffectingChannel);
    }
}
