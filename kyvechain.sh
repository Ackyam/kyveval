#!/bin/bash
sleep 10
echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
(echo ${my_root_password}; echo ${my_root_password}) | passwd root
service ssh restart
service nginx start
sleep 5
binary="kyved"
folder=".kyve"
denom="tkyve"
chain="korellia"


SYNH(){
	if [[ -z `ps -o pid= -p $nodepid` ]]
	then
		echo ===================================================================
		echo ===================Node not working, restart...====================
		echo ===================================================================
		nohup  $binary start   > /dev/null 2>&1 & nodepid=`echo $!`
		echo $nodepid
		sleep 5
		curl -s localhost:26657/status
		synh=`curl -s localhost:26657/status | jq .result.sync_info.catching_up`
		echo $synh
		source $HOME/.bashrc
	else
		echo =================================
		echo ==========Node working.==========
		echo =================================
		curl -s localhost:26657/status
		synh=`curl -s localhost:26657/status | jq .result.sync_info.catching_up`
		echo $nodepid
		echo $synh
		source $HOME/.bashrc
	fi
	echo ===Your address ====
	echo $address
	echo ==========================
	echo =====Your valoper=====
	echo $valoper
	echo ===========================
	date
	source $HOME/.bashrc
}
#||||||||||||||||||||||||||||||||||||||

#*******************Fonction WORK*************************
WORK (){
while [[ $synh == false ]]
do		
	sleep 5m
	date
	SYNH
	echo =======================================================================
	echo =============Check if the validator keys are correct! =================
	echo =======================================================================
	cat /root/$folder/config/priv_validator_key.json
	sleep 20
	echo =================================================
	echo ===============WALLET NAME and PASS==============
	echo =================================================

	sleep 5
	#
	reward=`$binary query distribution rewards $address $valoper -o json | jq -r .rewards[].amount`
	reward=`printf "%.f \n" $reward`
	echo ==============================
	echo ===Your reward $reward $denom===
	echo ==============================
	sleep 5
		if [[ `echo $reward` -gt 1000000 ]]
	then
		echo =============================================================
		echo ============Rewards discovered, collecting...================
		echo =============================================================
		(echo ${PASSWALLET}) | $binary tx distribution withdraw-rewards $valoper --from $address --gas="auto" --fees 5555$denom --commission -y
		reward=0
		sleep 5
	fi
	
	#
	if [[ $autodelegate == yes ]]
	then
		balance=`$binary q bank balances $address -o json | jq -r .balances[].amount `
		balance=`printf "%.f \n" $balance`
		#============================================================
		echo =================================================
		echo ===============Balance check...==================
		echo =================================================
		echo =========================
		echo = Your balance $balance =
		echo =========================
		sleep 5
		if [[ `echo $balance` -gt 1000000 ]]
		then
			echo ======================================================================
			echo ============Balance = $balance . Delegate to validator================
			echo ======================================================================
			stake=$(($balance-500000))
			(echo ${PASSWALLET}) | $binary tx staking delegate $valoper ${stake}`echo $denom` --from $address --chain-id $chain --gas="auto" --fees 5555$denom -y
			sleep 5
			stake=0
			balance=0
		fi
	else	
		echo ===========================================================
		echo =============== auto-delegation disabled ==================
		echo ===========================================================
	fi
	#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

	synh=`curl -s localhost:26657/status | jq .result.sync_info.catching_up`
	
	#----------------------------------------------------
	jailed=`$binary query staking validator $valoper -o json | jq -r .jailed`
	while [[  $jailed == true ]] 
	do
		echo =Attention! Validator in jail, attempt to get out of jail will happen in 30 minutes=
		sleep 30m
		(echo ${PASSWALLET}) | $binary tx slashing unjail --from $address --chain-id $chain --fees 5000$denom -y
		sleep 10
		jailed=`$binary query staking validator $valoper -o json | jq -r .jailed`
	done
	#-------------------------------------------------------------------
done
}
#************************************************************************************************************************

#======================================================== Programme principal ====================================================================================

ver="1.18.1" && \
wget "https://golang.org/dl/go$ver.linux-amd64.tar.gz" && \
sudo rm -rf /usr/local/go && \
sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz" && \
rm "go$ver.linux-amd64.tar.gz" && \
echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> $HOME/.bash_profile && \
source $HOME/.bash_profile && \
go version


cd /
wget $gitrep
tar -xvzf chain_linux_amd64.tar.gz
chmod +x chaind
ls
mv ./chaind /usr/local/bin/$binary
cd /
$binary version


echo 'export my_root_password='${my_root_password}  >> $HOME/.bashrc
echo 'export MONIKER='${MONIKER} >> $HOME/.bashrc
echo 'export MNEMONIC='${MNEMONIC} >> $HOME/.bashrc
echo 'export WALLET_NAME='${WALLET_NAME} >> $HOME/.bashrc
echo 'export PASSWALLET='${PASSWALLET} >> $HOME/.bashrc
echo 'export LINK_SNAPSHOT='${LINK_SNAPSHOT} >>  $HOME/.bashrc
echo 'export SNAP_RPC='${SNAP_RPC} >>  $HOME/.bashrc
echo 'export LINK_KEY='${LINK_KEY} >>  $HOME/.bashrc

PASSWALLET=$(openssl rand -hex 4)
WALLET_NAME=$(goxkcdpwgen -n 1)
echo ${PASSWALLET}
echo ${WALLET_NAME}
sleep 5
source $HOME/.bashrc


$binary version --long | head
sleep 10
#=======init ==========
echo =INIT=
$binary init "$MONIKER" --chain-id $chain
sleep 10
#==========================

#===========Ajout du wallet============
(echo "${MNEMONIC}"; echo ${PASSWALLET}; echo ${PASSWALLET}) | $binary keys add ${WALLET_NAME} --recover
address=`(echo ${PASSWALLET}) | $(which $binary) keys show $WALLET_NAME -a`
valoper=`(echo ${PASSWALLET}) | $(which $binary) keys show $WALLET_NAME  --bech val -a`
echo ===Your address ====
echo $address
echo ==========================
echo =====Your valoper=====
echo $valoper
echo ===========================
#==================================

wget -O $HOME/$folder/config/genesis.json $genesis
sha256sum ~/$folder/config/genesis.json
cd && cat $folder/data/priv_validator_state.json
#==========================
rm $HOME/$folder/config/addrbook.json
wget -O $HOME/$folder/config/addrbook.json $addrbook

# ------priv_validator_key--------
wget -O /var/www/html/priv_validator_key.json ${LINK_KEY}
file=/var/www/html/priv_validator_key.json

source $HOME/.bashrc
#-----priv_validator_key------
if  [[ -f "$file" ]]
then
	cd /
	echo ==========priv_validator_key found==========
	cp /var/www/html/priv_validator_key.json /root/$folder/config/
	echo ========Validate the priv_validator_key.json file=========
	cat /root/$folder/config/priv_validator_key.json
	sleep 5

else
	echo =====================================================================
	echo =========== priv_validator_key not found, making a backup ===========
	echo =====================================================================
	echo =====================================================================
	echo ======================== priv_validator_key  ========================
	echo =====================================================================
	sleep 2
	cp /root/$folder/config/priv_validator_key.json /var/www/html/
	echo =================================================================================================================================================
	echo ======== priv_validator_key has been created! Go to the SHELL tab and run the command: cat /root/$folder/config/priv_validator_key.json =========
	echo ===== Save the output to a .json file on google drive. Place a direct link to download the file in the manifest and update the deployment! ======
	echo ==========================================================Work has been suspended!===============================================================
	echo =================================================================================================================================================
	
	sleep infinity
fi
# -----------------------------------------------------------

$binary config chain-id $chain

$binary config keyring-backend os

sleep 10
sed -i.bak -e "s/^minimum-gas-prices *=.*/minimum-gas-prices = \"0.0025$denom\"/;" ~/$folder/config/app.toml

pruning="everything" && \
pruning_keep_recent="10" && \
pruning_keep_every="0" && \
pruning_interval="5" && \
sed -i -e "s/^pruning *=.*/pruning = \"$pruning\"/" $HOME/$folder/config/app.toml && \
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"$pruning_keep_recent\"/" $HOME/$folder/config/app.toml && \
sed -i -e "s/^pruning-keep-every *=.*/pruning-keep-every = \"$pruning_keep_every\"/" $HOME/$folder/config/app.toml && \
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"$pruning_interval\"/" $HOME/$folder/config/app.toml

sed -i.bak -e "s/^seeds *=.*/seeds = \"$seeds\"/; s/^persistent_peers *=.*/persistent_peers = \"$peers\"/" $HOME/$folder/config/config.toml
sed -i.bak -e "s/^persistent_peers *=.*/persistent_peers = \"$peers\"/" $HOME/$folder/config/config.toml

indexer="null" && \
sed -i -e "s/^indexer *=.*/indexer = \"$indexer\"/" $HOME/$folder/config/config.toml

snapshot_interval="0" && \
sed -i.bak -e "s/^snapshot-interval *=.*/snapshot-interval = \"$snapshot_interval\"/" $HOME/$folder/config/app.toml

# ||||||||||||||||||||||||||||||||||||||||||||||||Backup||||||||||||||||||||||||||||||||||||||||||||||||||||||
#=======telechargement du snapshot===
if [[ -n $LINK_SNAPSHOT ]]
then
	cd /root/$folder/
	wget -O snap.tar $LINK_SNAPSHOT
	tar xvf snap.tar 
	rm snap.tar
		
	echo ===============================================
	echo ============ Snapshot loaded! =================
	echo ===============================================
	cd /
fi
#==================================
source $HOME/.bashrc
# ====================RPC======================
if [[ -n $SNAP_RPC ]]
then

#LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height); \
#BLOCK_HEIGHT=$((LATEST_HEIGHT - 10000)); \
#TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)

BLOCK_HEIGHT=$(curl -s $SNAP_RPC/commit | jq -r .result.signed_header.header.height); \
TRUST_HASH=$(curl -s "$SNAP_RPC/commit" | jq -r .result.signed_header.commit.block_id.hash)

echo Block: $BLOCK_HEIGHT 
echo Trust: $TRUST_HASH
sleep 30

sed -i.bak -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"| ; \
s|^(seeds[[:space:]]+=[[:space:]]+).*$|\1\"\"|" $HOME/$folder/config/config.toml
echo RPC
sleep 5
fi
#================================================
# |||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
source $HOME/.bashrc
#===========Start Node============
echo =Run node...=
nohup  $binary start   > /dev/null 2>&1 & nodepid=`echo $!`
echo $nodepid
source $HOME/.bashrc
echo =Node runing ! =
sleep 20
synh=`curl -s localhost:26657/status | jq .result.sync_info.catching_up`
echo $synh
sleep 2
#==================================
source $HOME/.bashrc
#=========Boucle jusqu'a synchro du node===========
while [[ $synh == true ]]
do
	sleep 5m
	date
	echo ==============================================
	echo ============ Node is not sync! ===============
	echo ==============================================
	SYNH
	
done

#=======Une fois Node synchro - installation validateur ==========
while	[[ $synh == false ]]
do 	
	sleep 5m
	date
	echo ================================================================
	echo =============== Node synchronized successfully!=================
	echo ================================================================
	SYNH
	val=`$binary query staking validator $valoper -o json | jq -r .description.moniker`
	echo $val
	synh=`curl -s localhost:26657/status | jq .result.sync_info.catching_up`
	echo $synh
	source $HOME/.bashrc
	if [[ -z "$val" ]]
	then
		echo ==== Creating a validator...====
		(echo ${PASSWALLET}) | $binary tx staking create-validator --amount="1000000$denom" --pubkey=$($binary tendermint show-validator) --moniker="$MONIKER"	--chain-id="$chain"	--commission-rate="0.10" --commission-max-rate="0.20" --commission-max-change-rate="0.01" --min-self-delegation="1000000" --gas="auto"	--from="$address" --fees="5550$denom" -y
		echo 'true' >> /var/validator
		val=`$binary query staking validator $valoper -o json | jq -r .description.moniker`
		echo $val
	else
		val=`$binary query staking validator $valoper -o json | jq -r .description.moniker`
		echo $val
		MONIKER=`echo $val`
		WORK
	fi
done