pragma solidity 0.6.3;


contract Simplified{
    
    address owner;
    
    struct AP{
        address ethaddr;
        uint8 channel; 
    }
    
    struct scanInfo{
        uint8 channelNo;
        uint256 totalInterference;
        uint256 noOfStationsScanned;
    }
    
    mapping(address => scanInfo[3]) public scan;
    mapping(address => bool) public submitted;
    mapping(address => uint8) public accessPointChAllocation;
    
    
    AP[] public ListOfAPs;
    
    modifier onlyRegisteredAPs(){
        require(
            checkIfValidAddress(msg.sender),
            "Only registered APs can call this function."
        );
        _;
    }
    
    constructor () public{
        
        owner = msg.sender;
    }
    
    function addAP(address _addr, uint8 _currentChannel) public
    {
        ListOfAPs.push(AP(_addr, _currentChannel));
    }
    


    function submitScanInfo(uint8[3] memory channelNo, uint256[3] memory totalInterference, uint256[3] memory noOfStationsScanned) public onlyRegisteredAPs(){
        
        
        for(uint8 i = 0; i < 3; i++)
        {
            scan[msg.sender][i] = scanInfo(channelNo[i], totalInterference[i], noOfStationsScanned[i]);
        }
        
        submitted[msg.sender] = true;
        
        
        if(checkIfAllSubmitted() == true){
            // emit AllHaveSubmitted();
            allocateChannels();
        }
    }
    
    function allocateChannels() private {
        
        AP[] memory discoloredNodes = ListOfAPs;
        
        
        
        for(uint8 i = 0; i< discoloredNodes.length - 1; i++)
        {
            if(getTotalNumberOfAPs(discoloredNodes[i]) < getTotalNumberOfAPs(discoloredNodes[i+1]))
            {
                AP memory temp = discoloredNodes[i+1];
                discoloredNodes[i+1] = discoloredNodes[i];
                discoloredNodes[i] = temp;
            }
        }
        
         while (discoloredNodes.length > 0)
        {
            AP memory selectedNode = discoloredNodes[0];
            
            uint8[] memory freeChannels;
            
            for(uint8 i = 0; i< 3; i++)
            {
                if(scan[selectedNode.ethaddr][i].noOfStationsScanned == 0)
                    freeChannels[freeChannels.length] = scan[selectedNode.ethaddr][i].channelNo;
            }
            
            if(freeChannels.length > 0)
            {
                accessPointChAllocation[selectedNode.ethaddr] = freeChannels[0];
            }
            else{
                
                accessPointChAllocation[selectedNode.ethaddr] = getChannelWithLeastInterference(scan[selectedNode.ethaddr]);
            }
            
            delete discoloredNodes[0];
            
            for(uint8 i = 0; i< ListOfAPs.length; i++){
                ListOfAPs[i].channel = accessPointChAllocation[ListOfAPs[i].ethaddr];
            }
        }
    }
    
    
    function getChannelWithLeastInterference(scanInfo[3] memory scanList) private pure returns (uint8 channelNo){
        
        uint256 minValue = scanList[0].totalInterference;
        channelNo = scanList[0].channelNo;
        
        for(uint8 i = 1; i< 3; i++)
        {
            if(scanList[i].totalInterference < minValue)
            {
                minValue = scanList[i].totalInterference;
                channelNo = scanList[i].channelNo;
            }
        }
        
        return channelNo;
    }
    
    
    function getTotalNumberOfAPs(AP memory ap) private view returns (uint256 noOfAPs) {
        
        noOfAPs = 0;
        for(uint8 i = 0; i < 3; i++)
        {
            noOfAPs = noOfAPs + scan[ap.ethaddr][i].noOfStationsScanned; 
        }
        
        return noOfAPs;
        
    }
    
    function checkIfValidAddress(address addr) private view returns (bool isValid){
        
        isValid = false;
        for(uint8 i= 0 ; i < ListOfAPs.length; i++)
        {
            if(addr == ListOfAPs[i].ethaddr)
                isValid = true;
        }
        
        return isValid;
    }
    
    function checkIfAllSubmitted() private view returns (bool allSubmitted){
        
        allSubmitted = true;
        for(uint8 i= 0 ; i < ListOfAPs.length; i++)
        {
            if(submitted[ListOfAPs[i].ethaddr] == false)
                allSubmitted = false;
            
            if(allSubmitted == false)
                break;
        }
        
        return allSubmitted;
    }
}
