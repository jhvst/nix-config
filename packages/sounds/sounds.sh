#!/usr/bin/env bash

curl -sX POST --data '{"jsonrpc":"2.0","method":"eth_getLogs","params":[{"topics":["0x81fb8daf8a05fc760e25f1447b0ca819bcf138a168ec6c1aaa0bd62b170bf32a"], "fromBlock": 17695077, "toBlock": 17795079}],"id":1}' -H 'Content-Type: application/json' http://192.168.100.10:8545 | jq -r '.result[] | .data' | xxd -r -p | strings | grep "^0ar" | cut -c7- | awk '{ print "https://arweave.net/" $0 "/0" }' > links.txt

cat links.txt | xargs curl -sLI | grep -E "HTTP" | grep -v "HTTP/2 302" | cut -d ' ' -f2 > codes.txt

paste codes.txt links.txt | grep "200" | cut -f2 | xargs curl -sL | jq -r '.losslessAudio' | grep "ar://" | sed 's/:\/\//\ /g' | awk '{ print "https://" $1 "/" $2 "/0" }' | grep "https://ar/" | sed 's/ar/arweave.net/g'
