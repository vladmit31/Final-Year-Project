const fs = require('fs')
const {exec} = require('child_process')
const Web3 = require('web3')
const net = require('net');
const web3 = new Web3('\\\\.\\pipe\\geth.ipc', net);

const contractAddress = "0x3c2f3A8F15c51cB394e7fa44dCdb85393652a8e0"
var contractABI = [{"inputs":[],"stateMutability":"nonpayable","type":"constructor"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"}],"name":"infoList","outputs":[{"internalType":"uint8","name":"channelNo","type":"uint8"},{"internalType":"uint8","name":"percentageUsage","type":"uint8"},{"internalType":"uint256","name":"noStationsOnChannel","type":"uint256"},{"internalType":"uint256","name":"noStationsAffectingChannel","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"owner","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint8","name":"_channelNo","type":"uint8"},{"internalType":"uint8","name":"_percentage","type":"uint8"},{"internalType":"uint256","name":"_noStationsOnChannel","type":"uint256"},{"internalType":"uint256","name":"_noStationsAffectingChannel","type":"uint256"}],"name":"submitInfo","outputs":[],"stateMutability":"nonpayable","type":"function"}]

var oracleContract = new web3.eth.Contract(contractABI, contractAddress);

const unlockAccount = () => {
    
}

let channelsJSON;
let affectingChannelsJSON;
let mergedJSON;

const removeBOM = (str) => {
    return str.substring(2);
}

const cleanString = (str) =>{
    return str.replace(/[\x00-\x1F\x7F-\x9F]/g, "");
}


const scanAndRead = async () => {

    const scan = exec('WifiInfoView.exe /DisplayMode 2 /NumberOfScans 3 /sjson channels.json &; WifiInfoView.exe /DisplayMode 13 /NumberOfScans 3 /sjson affectingChannels.json &', (error, stdout, stderr) => {
        if (error) {
          console.error(`exec error: ${error}`);
          return;
        }
    })

    scan.on('close',  () => {
        console.log("JSON files generated")
        
        fs.readFile('channels.json', 'utf8', (err, result)=> {
            if(err){
                console.log(err);
                return;
            }

            channelsJSON = JSON.parse(cleanString(removeBOM(result)))
                .filter((elem)=> {
                return ['1','6','11'].includes(elem['Group Name'].split(' ')[1])
            });
            
            fs.readFile('affectingChannels.json', 'utf8', (err, result)=> {
                if(err){
                    console.log(err);
                    return;
                }
    
                affectingChannelsJSON = JSON.parse(cleanString(removeBOM(result)))
                    .filter((elem)=> {
                    return ['1','6','11'].includes(elem['Group Name'].split(' ')[1])
                })

                // console.log(affectingChannelsJSON)
                // console.log(channelsJSON)
                mergedJSON = channelsJSON;

                for(let i = 0; i< mergedJSON.length; i++)
                {
                    mergedJSON[i]["Stations affecting"] = affectingChannelsJSON[i]["Counter"]
                }

                mergedJSON = mergedJSON.map(function(item){
                    return {'Channel Number' : item["Group Name"].split(" ")[1],
                            'Counter' : item["Counter"],
                            'Percent' : item["Percent"],
                            'Stations affecting' : item["Stations affecting"]
                        }
                  });

                console.log(mergedJSON)
                web3.eth.personal.getAccounts().then((res)=> {
                    console.log("account unlocked")
                    web3.eth.personal.unlockAccount(res[0], 'wifiblockchain2020', 100).then(()=> {
                        oracleContract.methods.submitInfo(1, 13, 15, 21).send({from: res[0]}).then(()=>
                            oracleContract.methods.submitInfo(6, 11, 9, 11).send({from: res[0]}).then(()=>
                                oracleContract.methods.submitInfo(11, 27, 4, 5).send({from: res[0]}).then(()=>
                                    web3.eth.personal.lockAccount(res[0]).then(console.log("account locked"))
                                ).catch(err => console.log(err)
                            ).catch(err => console.log(err))
                        ).catch(err => console.log(err)))
                    }).catch(err => console.log(err)) 
                }).catch(err => console.log(err))
                
                


            })
        })
    })
    
}

scanAndRead();