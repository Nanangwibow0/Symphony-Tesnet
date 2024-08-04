#!/bin/bash

# Fungsi untuk menampilkan logo 0xRUCIKA
show_logo() {
    echo "   ___       _____            _ _         "
    echo "  / _ \     |  __ \          (_) |        "
    echo " | | | |_  _| |__) |   _  ___ _| | ____ _ "
    echo " | | | \ \/ /  _  / | | |/ __| | |/ / _\` |"
    echo " | |_| |>  <| | \ \ |_| | (__| |   < (_| |"
    echo "  \___//_/\_\_|  \_\__,_|\___|_|_|\_\__,_|"
    echo "                                          "
    echo "         JP nya Mengalir Terus            "
    echo "                                          "
}

# Fungsi untuk menampilkan menu
show_menu() {
    echo "Pilihan:"
    echo "1. Install Node          10. Reload Service"
    echo "2. Create Wallet         11. Enable Service"
    echo "3. Import Wallet         12. Disable Service"
    echo "4. Check Balance         13. Start Service"
    echo "5. Create Validator      14. Stop Service"
    echo "6. Edit Validator        15. Restart Service"
    echo "7. Delegate Tokens       16. Check Service Status"
    echo "8. Withdraw All Rewards  17. Check Service Logs"
    echo "9. Send Tokens           18. Exit"
}

# Fungsi untuk menginstal node
install_node() {
    sudo apt update && sudo apt upgrade -y
    sudo apt install make curl git wget htop tmux build-essential jq make lz4 gcc unzip -y

    # Install GO
    ver="1.22.2"
    wget "https://golang.org/dl/go$ver.linux-amd64.tar.gz"
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz"
    rm "go$ver.linux-amd64.tar.gz"
    echo "export PATH=\$PATH:/usr/local/go/bin:\$HOME/go/bin" >> $HOME/.bash_profile
    source $HOME/.bash_profile
    go version

    cd $HOME
    rm -rf symphony
    git clone https://github.com/Orchestra-Labs/symphony
    cd symphony
    git checkout v0.2.1
    make install

    cd $HOME
    MONIKER=gantimonikermu
    echo "export MONIKER=$MONIKER" >> $HOME/.bash_profile
    echo "export CHAIN_ID=symphony-testnet-2" >> $HOME/.bash_profile
    echo "export SYMPHONY_PORT=15" >> $HOME/.bash_profile
    source $HOME/.bash_profile

    symphonyd init $MONIKER --chain-id $CHAIN_ID

    wget -O $HOME/.symphonyd/config/genesis.json https://files.nodesync.top/Symphony/symphony-genesis.json
    wget -O $HOME/.symphonyd/config/addrbook.json https://files.nodesync.top/Symphony/symphony-addrbook.json

    SEEDS=""
    PEERS="688b148e0a99b45c6b6ca6fbeae42f7a86c8ad4b@65.21.202.124:24856,adc09b9238bc582916abda954b081220d6f9cbc2@34.172.132.224:26656,eea2dc7e9abfd18787d4cc2c728689ad658cd3a2@35.184.9.159:26656,785f5e73e26623214269909c0be2df3f767fbe50@35.225.73.240:26656,8df964c61393d33d11f7c821aba1a72f428c0d24@34.41.129.120:26656"
    sed -i -e "s/^seeds *=.*/seeds = \"$SEEDS\"/; s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.symphonyd/config/config.toml
    sed -i -e "s/^minimum-gas-prices *=.*/minimum-gas-prices = \"0.025note\"/" $HOME/.symphonyd/config/app.toml
    sed -i -e 's|^indexer *=.*|indexer = "null"|' $HOME/.symphonyd/config/config.toml
    sed -i 's|^prometheus *=.*|prometheus = true|' $HOME/.symphonyd/config/config.toml

    pruning="custom"
    pruning_keep_recent="100"
    pruning_keep_every="0"
    pruning_interval="10"
    sed -i -e "s/^pruning *=.*/pruning = \"$pruning\"/" $HOME/.symphonyd/config/app.toml
    sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"$pruning_keep_recent\"/" $HOME/.symphonyd/config/app.toml
    sed -i -e "s/^pruning-keep-every *=.*/pruning-keep-every = \"$pruning_keep_every\"/" $HOME/.symphonyd/config/app.toml
    sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"$pruning_interval\"/" $HOME/.symphonyd/config/app.toml

    sed -i.bak -e "s%:1317%:${SYMPHONY_PORT}317%g;
    s%:8080%:${SYMPHONY_PORT}080%g;
    s%:9090%:${SYMPHONY_PORT}090%g;
    s%:9091%:${SYMPHONY_PORT}091%g;
    s%:8545%:${SYMPHONY_PORT}545%g;
    s%:8546%:${SYMPHONY_PORT}546%g;
    s%:6065%:${SYMPHONY_PORT}065%g" $HOME/.symphonyd/config/app.toml
    sed -i.bak -e "s%:26658%:${SYMPHONY_PORT}658%g;
    s%:26657%:${SYMPHONY_PORT}657%g;
    s%:6060%:${SYMPHONY_PORT}060%g;
    s%:26656%:${SYMPHONY_PORT}656%g;
    s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${SYMPHONY_PORT}656\"%;
    s%:26660%:${SYMPHONY_PORT}660%g" $HOME/.symphonyd/config/config.toml
    sed -i \
      -e 's|^chain-id *=.*|chain-id = "symphony-testnet-2"|' \
      -e 's|^keyring-backend *=.*|keyring-backend = "test"|' \
      -e 's|^node *=.*|node = "tcp://localhost:15657"|' \
      $HOME/.symphonyd/config/client.toml

    sudo tee /etc/systemd/system/symphonyd.service > /dev/null <<EOF
[Unit]
Description=symphony-testnet
After=network-online.target

[Service]
User=$USER
ExecStart=$(which symphonyd) start --home $HOME/.symphonyd
Restart=on-failure
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable symphonyd
}

# Fungsi untuk membuat wallet
create_wallet() {
    symphonyd keys add wallet
}

# Fungsi untuk mengimpor wallet
import_wallet() {
    symphonyd keys add wallet --recover
}

# Fungsi untuk memeriksa saldo
check_balance() {
    symphonyd q bank balances $(symphonyd keys show wallet -a)
}

# Fungsi untuk membuat validator
create_validator() {
    symphonyd tx staking create-validator \
    --amount 1000000note \
    --pubkey $(symphonyd tendermint show-validator) \
    --moniker "your-moniker-name" \
    --identity "your-keybase-id" \
    --details "your-details" \
    --website "your-website" \
    --security-contact "your-email" \
    --chain-id symphony-testnet-2 \
    --commission-rate 0.05 \
    --commission-max-rate 0.20 \
    --commission-max-change-rate 0.01 \
    --min-self-delegation 1 \
    --from wallet \
    --gas-adjustment 1.4 \
    --gas auto \
    --fees 800note \
    -y
}

# Fungsi untuk mengedit validator
edit_validator() {
    symphonyd tx staking edit-validator \
    --new-moniker="YOUR MONIKER" \
    --identity="KEYBASE ID" \
    --website="LINK WEBSITE" \
    --chain-id=symphony-testnet-2 \
    --from=wallet \
    --gas-adjustment=1.5 \
    --gas="auto" \
    --gas-prices=1note \
    -y
}

# Fungsi untuk mendelegasikan token
delegate_tokens() {
    symphonyd tx staking delegate $(symphonyd keys show wallet --bech val -a) 100000note --from wallet --chain-id symphony-testnet-2 --gas-adjustment 1.5 --gas auto --gas-prices 1note
}

# Fungsi untuk menarik semua reward
withdraw_all_rewards() {
    symphonyd tx distribution withdraw-all-rewards --from wallet --chain-id symphony-testnet-2 --gas-adjustment 1.5 --gas auto --gas-prices 1note
}

# Fungsi untuk mengirim token
send_tokens() {
    echo "Enter the recipient address:"
    read recipient
    echo "Enter the amount to send:"
    read amount
    symphonyd tx bank send wallet $recipient ${amount}note --chain-id symphony-testnet-2 --gas-adjustment 1.5 --gas auto --gas-prices 1note
}

# Fungsi untuk memuat ulang layanan
reload_service() {
    sudo systemctl daemon-reload
}

# Fungsi untuk mengaktifkan layanan
enable_service() {
    sudo systemctl enable symphonyd
}

# Fungsi untuk menonaktifkan layanan
disable_service() {
    sudo systemctl disable symphonyd
}

# Fungsi untuk memulai layanan
start_service() {
    sudo systemctl start symphonyd
}

# Fungsi untuk menghentikan layanan
stop_service() {
    sudo systemctl stop symphonyd
}

# Fungsi untuk me-restart layanan
restart_service() {
    sudo systemctl restart symphonyd
}

# Fungsi untuk memeriksa status layanan
check_service_status() {
    sudo systemctl status symphonyd
}

# Fungsi untuk memeriksa log layanan
check_service_logs() {
    sudo journalctl -u symphonyd -f --no-hostname -o cat
}

# Loop menu utama
while true; do
    show_logo
    show_menu
    read -p "Pilih opsi: " choice
    case $choice in
        1) install_node ;;
        2) create_wallet ;;
        3) import_wallet ;;
        4) check_balance ;;
        5) create_validator ;;
        6) edit_validator ;;
        7) delegate_tokens ;;
        8) withdraw_all_rewards ;;
        9) send_tokens ;;
        10) reload_service ;;
        11) enable_service ;;
        12) disable_service ;;
        13) start_service ;;
        14) stop_service ;;
        15) restart_service ;;
        16) check_service_status ;;
        17) check_service_logs ;;
        18) exit 0 ;;
        *) echo "Opsi tidak valid, coba lagi." ;;
    esac
done
