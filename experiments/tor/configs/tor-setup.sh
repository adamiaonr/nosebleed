# script to run (and measure stuff from) tor ORs, from node-gw in one stroke
# created by: antonior@andrew.cmu.edu

#!/bin/bash

PEM_FILE=/home/$USER/.ssh/node1.pem

TOR_DATA_DIR=/home/$USER/workbench/tor-configs
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

FILE_1MB="1MB.txt"
FILE_100kb="100kb.txt"

usage () {
    echo "usage: ./tor-setup.sh [(-w) --with-wget || (-p) --pem-file <.pem file> || (-i) --with-inet-connection || --start-instances || --stop-instances || (-s) --stop-tor]"
}

W_WGET=0
W_INET_CONNECTION=0

START_INSTANCES=0
STOP_INSTANCES=0

STOP_TOR=0

# for now, hardcode the number of tests to do
NUM_TESTS=50
    
while [ "$1" != "" ]; do
    
    case $1 in

        -w | --with-wget )              W_WGET=1
                                        ;;

        -p | --pem-file )               shift
                                        PEM_FILE=$1
                                        ;;
        -i | --with-inet-connection )   W_INET_CONNECTION=1
                                        ;;
        --start-instances )             START_INSTANCES=1
                                        ;;
        --stop-instances )              STOP_INSTANCES=1
                                        ;;
        -s | --stop-tor )               STOP_TOR=1
                                        ;;
        -h | --help )                   usage
                                        exit
                                        ;;
        * )                             usage
                                        exit 1
        esac
        shift

done

# 1) start or stop AWS EC2 instances
if [[ $START_INSTANCES -eq 1 ]]; then
    
    for INSTANCE in ${NODE_INSTANCES[@]}; do

        echo $INSTANCE
        ec2-start-instances $INSTANCE
    done

    # no point going on...
    exit 0

elif [[ $STOP_INSTANCES -eq 1 ]]; then
    
    for INSTANCE in ${NODE_INSTANCES[@]}; do

        ec2-stop-instances $INSTANCE
    done    

    # no point going on...
    exit 0

elif [[ $STOP_TOR -eq 1 ]]; then

    # 1.3) stop tor on all machines
    for IP in ${NODE_IPS[@]}; do

        ssh -i $PEM_FILE $USER@$IP bash -c "'killall $TOR_BINARY'"

    done

    exit 0
fi

START_INSTANCES=0
STOP_INSTANCES=0

# 1) if specified, setup node-gw as an Internet gateway for the private Tor 
# network
# TODO

# 2) start tor on diff. machines
INDEX=0

for IP in ${NODE_IPS[@]}; do

    # 2.1) if tcpdumps are to be collected, start them now...
    if [[ $W_TCP_DUMP -eq 1 ]]; then

        ssh -i $PEM_FILE $USER@$IP bash -c "'tcpdump -i eth0 -s 0 -n -w $TOR_DATA_DIR/${NODE_NAMES[$INDEX]}.cap'"
    fi

    # 2.2) if the client node, also restart privoxy, just in case: the 
    # objective is to have all network applications making HTTP requests (e.g. 
    # wget, curl) going through privoxy, which in turn passes them to 
    # 127.0.0.1:9011, where Tor is listening (why don't we do it directly? 
    # it doesn't work, and i don't know why...)
    #
    # e.g. just run:
    # $ wget http://172.31.100.50
    #
    # to communicate with an apache2 server running in node-server, and fecth 
    # the index.html page via Tor...
    if [[ $INDEX -eq 0 ]]; then

        ssh -i $PEM_FILE -t $USER@$IP bash -c "'sudo service privoxy stop; sudo service privoxy start;'"
    fi

    # 2.3) start tor using the configurations on the torrc file
    ssh -i $PEM_FILE $USER@$IP bash -c "'$TOR_DIR/$TOR_OR_DIR/$TOR_BINARY -f $TOR_DATA_DIR/$TOR_TORRC'"

    $((INDEX++))
done

# 3) keep downloading and deleting file from a web server for repeated tests
if [[ $W_WGET -eq 1 ]]; then

    cd $TOR_DATA_DIR

    # infinite loop (don't judge me...)
    KEEP_LOOPIN=$NUM_TESTS

    while [[ $KEEP_LOOPIN -ge 1 ]]; do

        # do a wget download on node1
        INDEX=0
        ssh -i $PEM_FILE $USER@${NODE_IPS[$INDEX]} bash -c "'wget http://$SERVER_IP/$FILE_1MB'"

        # ... and remove it!
        ssh -i $PEM_FILE $USER@${NODE_IPS[$INDEX]} bash -c "'rm $FILE_1MB*'"

        # sleep for 180 secs before trying another download
        sleep 10

        $((KEEP_LOOPIN--))
    done

    # stop the instances (to save money)
    for INSTANCE in ${NODE_INSTANCES[@]}; do

        ec2-stop-instances $INSTANCE
    done    
fi

exit 0
