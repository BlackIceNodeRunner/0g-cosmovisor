#!/bin/bash

LOGO="https://raw.githubusercontent.com/BlackIceNodeRunner/BlackIceGuides/main/logo.sh"
source <(curl -s $LOGO)
bold=$(tput bold)
normal=$(tput sgr0)

clear
logo

set -e

read -p "Enter 0G_MONIKER name:" 0G_MONIKER
export 0G_MONIKER=$0G_MONIKER
0G_PORT=26
read -p "Enter 0G_WALLET name:" 0G_WALLET
export 0G_WALLET=$0G_WALLET
0G_CHAIN_ID="zgtendermint_16600-2"

#SEEDs and PEERs
PEERS="e396f55133cb93ff2f2333f379fe9ad76074e005@136.243.9.249:24556,e371f26305869fd8294f6e57dc01ffbbd394a5ac@156.67.80.182:26656,ffa3714c696cda448e9174b29eb98c9b6d45ba00@156.67.81.113:12656,399329896764fce054d96d74e761dc01f408803d@161.97.78.6:26656,7da685b1aca1f88dd36f152d2107fc462eceaa83@194.163.146.132:13456,3ceb228c6f031b7a68cf7c6ebe7e317b542587c9@62.171.183.248:12656,8af551c4554639f52097d096bdbc59ab9e0c2b19@38.242.238.22:12656,ad189adc600e7b8a472560bed60b356701b1736f@176.105.85.3:12656,c68a84b468bcfd48132933939477048badbddad7@148.113.17.55:21156,e2572fec2675e92a2c16572d0e59df4faac079ee@38.242.151.106:12656,4831925b70074e630a896156adfb37779f04eceb@65.109.30.35:56656,302adfd4a043d6494b8262dab846efcee6f0e6ba@185.250.37.5:26656,f89eefd1b00754ae2c6033f5cc60eeb0d6bf62a9@212.90.120.230:12656,3a4612bab7aafd6f57ff857bf83a0fb447a47a75@65.21.114.39:56656,7baa9325f18259079d701d649d22221232dd7a8d@116.202.51.84:26656"
SEEDS="81987895a11f6689ada254c6b57932ab7ed909b6@54.241.167.190:26656,010fb4de28667725a4fef26cdc7f9452cc34b16d@54.176.175.48:26656,e9b4bc203197b62cc7e6a80a64742e752f4210d5@54.193.250.204:26656,68b9145889e7576b652ca68d985826abd46ad660@18.166.164.232:26656"

#Set Vars
echo "export 0G_MONIKER=$0G_MONIKER" >> $HOME/.bash_profile
echo "export 0G_PORT=$0G_PORT" >> $HOME/.bash_profile
echo "export 0G_WALLET=$0G_WALLET" >> $HOME/.bash_profile
echo "export 0G_CHAIN_ID=$0G_CHAIN_ID" >> $HOME/.bash_profile

header() {
    echo -e "\033[92m "
    echo "${bold}=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=${normal}"
    echo "${bold}-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-${normal}"
    echo -e "               $1"
    echo "${bold}=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=${normal}"
    echo "${bold}-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-${normal}"
    echo " \033[0m"
    sleep 2
}
#GO LANG install
go_install() {
    cd $HOME &&
    ver="1.22.4"
    wget "https://golang.org/dl/go$ver.linux-amd64.tar.gz"
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz"
    rm "go$ver.linux-amd64.tar.gz"
    echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> ~/.bash_profile
    source ~/.bash_profile
}

# Install Cosmovisor
cosmovisor_install() {
    go install cosmossdk.io/tools/cosmovisor/cmd/cosmovisor@latest
}

# Downloading 0G Labs
0g_download() {
    git clone -b v0.2.5 https://github.com/0glabs/0g-chain.git
    cd 0g-chain
    make install
    0gchaind version
}

# Configing node
node_config() {
    cd $HOME
    0gchaind init $0G_MONIKER --chain-id $OG_CHAIN_ID
    0gchaind config chain-id $OG_CHAIN_ID
    0gchaind config node tcp://localhost:${OG_PORT}657
    0gchaind config keyring-backend os
    sleep 2

    sudo rm $HOME/.0gchain/config/genesis.json
    wget https://github.com/0glabs/0g-chain/releases/download/v0.2.3/genesis.json -O $HOME/.0gchain/config/genesis.json
}

header "GoLang-Instal"
go_install
sleep 5
clear

logo
header "Cheking GO version"
go version
sleep 5
clear

logo
header "Donwloading and installing 0G Labs"
cosmovisor_install
0g_download
sleep 5
clear

logo
header "Doing some Magic things"
node_config
sed -i.bak -e "s/^seeds *=.*/seeds = \"${SEEDS}\"/" $HOME/.0gchain/config/config.toml
sed -i -e "s|^persistent_peers *=.*|persistent_peers = \"$PEERS\"|" $HOME/.0gchain/config/config.toml

sed -i.bak -e "s%:26658%:${OG_PORT}658%g;
s%:26657%:${OG_PORT}657%g;
s%:6060%:${OG_PORT}060%g;
s%:26656%:${OG_PORT}656%g;
s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${OG_PORT}656\"%;
s%:26660%:${OG_PORT}660%g" $HOME/.0gchain/config/config.toml

sed -i "s/^minimum-gas-prices *=.*/minimum-gas-prices = \"0ua0gi\"/" $HOME/.0gchain/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.0gchain/config/config.toml

# Cosmoviser folders
mkdir -p $HOME/.0gchain/cosmovisor/genesis/bin
mkdir -p $HOME/.0gchain/cosmovisor/upgrades
mkdir -p $HOME/.0gchain/cosmovisor/backup
cp $HOME/go/bin/0gchaind $HOME/.0gchain/cosmovisor/genesis/bin

COSMOVISER_HOME=$(which cosmovisor)
0G_HOME=$(find $HOME -type d -name ".0gchain")
COSMOVISER_BACKUP=$(find $HOME/.0gchain/cosmovisor -type d -name "backup")
echo "export DAEMON_NAME=0gchaind" >> $HOME/.bash_profile
echo "export DAEMON_HOME=$(find $HOME -type d -name ".0gchain")" >> $HOME/.bash_profile
echo "export DAEMON_DATA_BACKUP_DIR=$(find $HOME/.0gchain/cosmovisor -type d -name "backup")" >> $HOME/.bash_profile
source $HOME/.bash_profile

# Creating service file

sudo tee /etc/systemd/system/0gchaind.service > /dev/null <<EOF
[Unit]
Description=Cosmovisor 0G Node by BlackIceNodeRunner
After=network.target

[Service]
User=$USER
Type=simple
ExecStart=$COSMOVISER_HOME run start --log_output_console
Restart=on-failure
LimitNOFILE=65535
Environment="DAEMON_NAME=0gchaind"
Environment="DAEMON_HOME=0G_HOME"
Environment="DAEMON_ALLOW_DOWNLOAD_BINARIES=true"
Environment="DAEMON_RESTART_AFTER_UPGRADE=true"
Environment="DAEMON_DATA_BACKUP_DIR=COSMOVISER_BACKUP"
Environment="UNSAFE_SKIP_BACKUP=true"

[Install]
WantedBy=multi-user.target
EOF

clear
logo
sleep 2

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable 0gchaind
sudo systemctl restart 0gchaind
sudo systemctl status 0gchaind
