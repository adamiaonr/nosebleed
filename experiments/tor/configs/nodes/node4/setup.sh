# script to setup authority server
# created by: antonior@andrew.cmu.edu

#!/bin/bash

PEM_FILE=/home/$USER/.ssh/node1.pem

TOR_CONFIG_DIR=/home/$USER/workbench/tor-configs
# default torrc file (should be used most of the times)
TOR_TORRC=torrc

TOR_DIR=/home/$USER/workbench/tor
TOR_OR_DIR=src/or
TOR_BINARY=tor

NODE_IPS=("172.31.100.10" "172.31.100.20" "172.31.100.30" "172.31.100.40" "172.31.100.60")
NODE_NAMES=("node1" "node2" "node3" "node4" "node6")
# besides the 5 tor nodes, this includes the server node (end)
NODE_INSTANCES=('i-b58aa97c' 'i-11a986ca' 'i-b8bc9363' 'i-59bb9482' 'i-5b4b6580' 'i-ed95b724')

SERVER_IP="172.31.100.50"

INDEX=0
AUTH_SERVER_INDEX=3

for IP in ${NODE_IPS[@]}; do

    # install essential packages
    ssh -i $PEM_FILE -t $USER@$IP bash -c "'sudo apt-get install git; sudo apt-get update --fix-missing; sudo apt-get install build-essential autoconf libevent-dev libssl-dev;'"    

    # install tor & nosebleed repositories
    ssh -i $PEM_FILE -t $USER@$IP bash -c "'git clone https://git.torproject.org/tor.git;'"
    ssh -i $PEM_FILE -t $USER@$IP bash -c "'git clone https://adamiaonr@bitbucket.org/devnullians/nosebleed.git;'"

    # autogen, configure and make tor
    ssh -i $PEM_FILE -t $USER@$IP bash -c "'cd $TOR_DIR; ./autogen.sh; ./configure --disable-asciidoc; make;'"

    # general tor node configuration
    AUX_CONFIG_STR="x 127.0.0.1:1 ffffffffffffffffffffffffffffffffffffffff"
    ssh -i $PEM_FILE -t $USER@$IP bash -c "'mkdir -p $TOR_CONFIG_DIR; cd $TOR_CONFIG_DIR; ../tor/src/or/tor --list-fingerprint --orport 1 --dirserver $AUX_CONFIG_STR --datadirectory /home/ubuntu/workbench/tor-configs/'"

    $((INDEX++))
done

# setup of authority server is more complicated...
ssh -i $PEM_FILE -t $USER@$IP bash -c "'mkdir -p $TOR_CONFIG_DIR/keys'"
ssh -i $PEM_FILE -t $USER@$IP bash -c "'$TOR_DIR/src/tools/tor-gencert --create-identity-key -m 12 -a ${NODE_IPS[$AUTH_SERVER_INDEX]}:7000 -i $TOR_CONFIG_DIR/keys/authority_identity_key -s $TOR_CONFIG_DIR/keys/authority_signing_key -c $TOR_CONFIG_DIR/keys/authority_certificate'"

# now, it would be cool to copy the base torrc files from the configs, 
# and update the files according to the keys generated by the auth server


exit 0
