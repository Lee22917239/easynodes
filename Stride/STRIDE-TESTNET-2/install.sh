#!/bin/bash

while true
do

# Logo

echo "============================================================"
curl -s https://raw.githubusercontent.com/ericet/easynodes/master/logo.sh | bash
echo "============================================================"


source ~/.profile

PS3='选择一个操作 '
options=(
"安装必要的环境" 
"安装节点" 
"创建钱包"
"节点日志" 
"查看节点状态" 
"水龙头获得测试币" 
"钱包余额" 
"创建验证人" 
"查看验证人"
"运行IBC Relayer"
"退出")
select opt in "${options[@]}"
               do
                   case $opt in
                   
"安装必要的环境")
echo "============================================================"
echo "准备开始。。。"
echo "============================================================"

#INSTALL DEPEND
echo "============================================================"
echo "Update and install APT"
echo "============================================================"
sleep 3
sudo apt update && sudo apt upgrade -y && \
sudo apt install curl tar wget clang pkg-config libssl-dev jq build-essential bsdmainutils git make ncdu gcc git jq chrony liblz4-tool -y

#INSTALL GO
echo "============================================================"
echo "Install GO 1.18.1"
echo "============================================================"
sleep 3
wget https://golang.org/dl/go1.18.1.linux-amd64.tar.gz; \
rm -rv /usr/local/go; \
tar -C /usr/local -xzf go1.18.1.linux-amd64.tar.gz && \
rm -v go1.18.1.linux-amd64.tar.gz && \
echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> ~/.profile && \
source ~/.profile && \
go version > /dev/null

echo "============================================================"
echo "服务器环境准备好了!"
echo "============================================================"
break
;;
            
"安装节点")
echo "============================================================"
echo "输入节点的名称:"
echo "============================================================"
                
read STRIDENODE
STRIDENODE=$STRIDENODE
echo 'export STRIDENODE='${STRIDENODE} >> $HOME/.profile

echo "============================================================"
echo "输入钱包名称:"
echo "============================================================"
               
read STRIDEWALLET
STRIDEWALLET=$STRIDEWALLET
echo 'export STRIDEWALLET='${STRIDEWALLET} >> $HOME/.profile
STRIDECHAIN="STRIDE-TESTNET-2"
echo 'export STRIDECHAIN='${STRIDECHAIN} >> $HOME/.profile
source $HOME/.profile

echo "============================================================"
echo "节点安装开始。。。"
echo "============================================================"

git clone https://github.com/Stride-Labs/stride.git
cd stride
git checkout 3cb77a79f74e0b797df5611674c3fbd000dfeaa1
make build
mv $HOME/stride/build/strided $HOME/go/bin/


strided init $STRIDENODE --chain-id $STRIDECHAIN

strided tendermint unsafe-reset-all --home $HOME/.stride
rm $HOME/.stride/config/genesis.json
curl -s https://raw.githubusercontent.com/Stride-Labs/testnet/main/poolparty/genesis.json > ~/.stride/config/genesis.json

# config pruning
indexer="null"
pruning="custom"
pruning_keep_recent="100"
pruning_keep_every="0"
pruning_interval="10"

sed -i -e "s/^indexer *=.*/indexer = \"$indexer\"/" $HOME/.stride/config/config.toml
sed -i -e "s/^pruning *=.*/pruning = \"$pruning\"/" $HOME/.stride/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"$pruning_keep_recent\"/" $HOME/.stride/config/app.toml
sed -i -e "s/^pruning-keep-every *=.*/pruning-keep-every = \"$pruning_keep_every\"/" $HOME/.stride/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"$pruning_interval\"/" $HOME/.stride/config/app.toml

wget -O $HOME/.stride/config/addrbook.json "https://api.nodes.guru/stride_addrbook.json"
SEEDS="c0b278cbfb15674e1949e7e5ae51627cb2a2d0a9@seedv2.poolparty.stridenet.co:26656"
PEERS="8e301628c3f86ba6f875e4978d73bf532198151b@34.170.216.198:26656,a4058280bdf7c7b5d9c452e3ae0027e6905f17be@159.223.227.15:16656,7ae3b00c50b17ec306db84155665bf7c598251d2@178.18.240.171:26656,4070d37bcdc121f6d3603ccd5608c6d00eb4c5b4@38.242.144.252:16656,237c3eaf5617a5e14164cbf9e6af928436f8c442@65.108.11.180:17656,10e1829f03abd7d945621b2986c95082e737e935@40.114.114.229:16656,d7b72c668e32bf1e5efa7d196047188d5a6f1db8@65.108.231.252:46656,9015b5674d890b5d6e89219576eac64309da79e5@146.19.24.34:36656,9fa7a4ec38074f5a2c7878c686785a8cbbb5998e@20.216.136.170:16656,cdc1aef42d8dc3a278bbc40651c0a2d0c609b38f@34.133.185.92:26656,548aa59f61206b469c551f74cc7bf0469ace886a@185.249.225.174:16656,ade0de29d1b4d6871366314b0a9d580c811b233b@144.91.77.189:36886,2a691eb4dc624eeb178dfc37ef18a9ac611239db@194.146.25.245:16656,390ff948ffbb9ad1793c3de91bf457750f3279b6@65.108.71.92:54356,60990219d79a5b497ae44cde0753979b2220501a@185.231.153.229:26656,3766ebe762f6825b3498e97a3b93f0ee1e8e0faa@34.171.211.242:26656,a2f991feac3dea5a12f1ebdd6c2bf5f30e0ccfba@65.108.11.234:26656"; \
sed -i.bak "s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/;" $HOME/.stride/config/config.toml
sed -i "s/^seeds *=.*/seeds = \"$SEEDS\"/;" $HOME/.stride/config/config.toml



tee $HOME/strided.service > /dev/null <<EOF
[Unit]
Description=Stride Testnet Daemon
After=network.target
[Service]
Type=simple
User=$USER
ExecStart=$(which strided) start
Restart=on-failure
RestartSec=10
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

sudo mv $HOME/strided.service /etc/systemd/system/

# start service
sudo systemctl daemon-reload
sudo systemctl enable strided
sudo systemctl restart strided

echo "============================================================"
echo "节点安装成功!"
echo "============================================================"
break
;;


"创建钱包")
echo "============================================================"
echo "请保存助记词!"
echo "============================================================"
               
strided keys add $STRIDEWALLET
STRIDEADDRWALL=$(strided keys show $STRIDEWALLET -a)
STRIDEVAL=$(strided keys show $STRIDEWALLET --bech val -a)
echo 'export STRIDEVAL='${STRIDEVAL} >> $HOME/.profile
echo 'export STRIDEADDRWALL='${STRIDEADDRWALL} >> $HOME/.profile
source $HOME/.profile

echo "============================================================"
echo "钱包地址: $STRIDEADDRWALL"
echo "验证人地址: $STRIDEVAL"
echo "============================================================"
               
break
;;

"查看节点状态")
echo "============================================================"
echo "节点catching_up为false的时候继续下一步"
echo "============================================================"
echo "节点状态 = $(curl -s localhost:26657/status | jq .result | jq .sync_info)"
echo "区块高度 = $(teritorid status 2>&1 | jq ."SyncInfo"."latest_block_height")"
echo "验证人状态 = $(strided q slashing signing-info $(strided tendermint show-validator))"
echo "============================================================"
break
;;

"创建验证人")
echo "============================================================"
echo "节点状态为false的时候继续下一步!"
echo "节点状态 = $(curl -s localhost:26657/status)"
echo "============================================================"
               
strided tx staking create-validator \
  --amount 1000000ustrd \
  --from $STRIDEWALLET \
  --commission-max-change-rate "0.05" \
  --commission-max-rate "0.20" \
  --commission-rate "0.05" \
  --min-self-delegation "1" \
  --pubkey $(strided tendermint show-validator) \
  --moniker $STRIDENODE \
  --chain-id $STRIDECHAIN \
  --gas 300000 \
  -y
break
;;

"钱包余额")
echo "============================================================"
echo "节点名称: $STRIDENODE"
echo "钱包地址: $STRIDEADDRWALL" 
echo "钱包余额: $(strided query bank balances $STRIDEADDRWALL)"
echo "============================================================"
break
;;

"查看验证人") 
echo "============================================================"
echo "Account request: $(strided q auth account $(strided keys show $STRIDEADDRWALL -a) -o text)"
echo "Validator info: $(strided q staking validator $STRIDEVAL)"
echo "============================================================"
break
;;

"水龙头获得测试币")
request=$request
echo "============================================================"
echo "进入Stride Discord https://discord.gg/rKFgXvKG 的 #token-faucet 频道"
echo "============================================================"
echo -e "复制粘贴 \033[32m !faucet-stride:$STRIDEADDRWALL \033[37m"
echo "============================================================"
break
;;

"节点日志")
journalctl -u strided -f -o cat
break
;;

"删除节点")
systemctl stop strided
systemctl disable strided
rm /etc/systemd/system/strided.service
rm -r .stride stride
break
;;

"运行IBC Relayer")
PS3='选择一个操作 '
options=(
"安装Hermes" 
"设置IBC" 
"Hermes日志" 
"退出")
select opt in "${options[@]}"
               do
                   case $opt in
                                   
"安装Hermes")
cd $HOME
mkdir -p $HOME/.hermes/bin
sudo apt install unzip -y
wget "https://github.com/informalsystems/ibc-rs/releases/download/v0.15.0/hermes-v0.15.0-x86_64-unknown-linux-gnu.tar.gz"
tar -C $HOME/.hermes/bin/ -vxzf hermes-v0.15.0-x86_64-unknown-linux-gnu.tar.gz
rm hermes-v0.15.0-x86_64-unknown-linux-gnu.tar.gz
echo "export PATH=$PATH:$HOME/.hermes/bin" >> $HOME/.profile
source $HOME/.profile
break
;;

"设置IBC")
STRIDE_RPC="stride.stake-take.com"
STRIDE_RPC_PORT="26657"
STRIDE_GRPC_PORT="9090"
STRIDE_CHAIN_ID="STRIDE-TESTNET-2"
STRIDE_ACC_PREFIX="stride"
STRIDE_DENOM="ustrd"
STRIDE_WALLET="stride-wallet"
GAIA_RPC="stride.stake-take.com"
GAIA_RPC_PORT="46657"
GAIA_GRPC_PORT="9490"
GAIA_CHAIN_ID="GAIA"
GAIA_ACC_PREFIX="cosmos"
GAIA_DENOM="uatom"
GAIA_WALLET="gaia-wallet"
echo "============================================================"
echo "输入你的Discord ID(xxxx#1234)"
echo "============================================================"
read memo
MEMO_PREFIX=$memo

echo "
export STRIDE_CHAIN_ID=${STRIDE_CHAIN_ID}
export STRIDE_DENOM=${STRIDE_DENOM}
export STRIDE_WALLET=${STRIDE_WALLET}
export GAIA_CHAIN_ID=${GAIA_CHAIN_ID}
export GAIA_DENOM=${GAIA_DENOM}
export GAIA_WALLET=${GAIA_WALLET}
export MEMO_PREFIX=${MEMO_PREFIX}
" >> $HOME/.profile
source $HOME/.profile

echo "[global]
log_level = 'info'
[mode]
[mode.clients]
enabled = true
refresh = true
misbehaviour = true
[mode.connections]
enabled = false
[mode.channels]
enabled = false
[mode.packets]
enabled = true
clear_interval = 100
clear_on_start = true
tx_confirmation = true
[rest]
enabled = true
host = '0.0.0.0'
port = 3000
[telemetry]
enabled = true
host = '0.0.0.0'
port = 3001
[[chains]]
id = '$STRIDE_CHAIN_ID'
rpc_addr = 'http://$STRIDE_RPC:$STRIDE_RPC_PORT'
grpc_addr = 'http://$STRIDE_RPC:$STRIDE_GRPC_PORT'
websocket_addr = 'ws://$STRIDE_RPC:$STRIDE_RPC_PORT/websocket'
rpc_timeout = '10s'
account_prefix = '$STRIDE_ACC_PREFIX'
key_name = '$STRIDE_WALLET'
store_prefix = 'ibc'
max_tx_size = 100000
max_gas = 20000000
gas_price = { price = 0.001, denom = '$STRIDE_DENOM' }
gas_adjustment = 0.1
max_msg_num = 15
clock_drift = '5s'
trusting_period = '1days'
memo_prefix='$MEMO_PREFIX'
trust_threshold = { numerator = '1', denominator = '3' }
[[chains]]
id = '$GAIA_CHAIN_ID'
rpc_addr = 'http://$GAIA_RPC:$GAIA_RPC_PORT'
grpc_addr = 'http://$GAIA_RPC:$GAIA_GRPC_PORT'
websocket_addr = 'ws://$GAIA_RPC:$GAIA_RPC_PORT/websocket'
rpc_timeout = '10s'
account_prefix = '$GAIA_ACC_PREFIX'
key_name = '$GAIA_WALLET'
store_prefix = 'ibc'
max_tx_size = 100000
max_gas = 30000000
gas_price = { price = 0.001, denom = '$GAIA_DENOM' }
gas_adjustment = 0.1
max_msg_num = 15
clock_drift = '5s'
trusting_period = '1days'
memo_prefix= '$MEMO_PREFIX'
trust_threshold = { numerator = '1', denominator = '3' }" > $HOME/.hermes/config.toml

hermes config validate

echo "============================================================"
echo "输入助记词（钱包里有STRD）"
echo "============================================================"
read mnemonic

hermes keys restore ${STRIDE_CHAIN_ID} -n $STRIDE_WALLET -m "${mnemonic}" 
hermes keys restore ${GAIA_CHAIN_ID} -n $GAIA_WALLET -m "${mnemonic}"

HERMES_STRIDE_GAIA_CHANNEL_ID="channel-0"
HERMES_GAIA_STRIDE_CHANNEL_ID="channel-0"

echo "
export HERMES_STRIDE_GAIA_CHANNEL_ID=${HERMES_STRIDE_GAIA_CHANNEL_ID}
export HERMES_GAIA_STRIDE_CHANNEL_ID=${HERMES_GAIA_STRIDE_CHANNEL_ID}
" >> $HOME/.profile

source $HOME/.profile

sudo tee /etc/systemd/system/hermesd.service > /dev/null <<EOF
[Unit]
Description=HERMES
After=network.target
[Service]
Type=simple
User=$USER
ExecStart=$(which hermes) start
Restart=on-failure
RestartSec=5
LimitNOFILE=6000
[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable hermesd
sudo systemctl restart hermesd && journalctl -u hermesd -f

break
;;

"Hermes日志")
journalctl -u hermesd -f
break
;;

"退出")
exit
;;

*) echo "invalid option $REPLY";;
esac
done
break
;; 

"退出")
exit
;;

*) echo "invalid option $REPLY";;
esac
done
done
