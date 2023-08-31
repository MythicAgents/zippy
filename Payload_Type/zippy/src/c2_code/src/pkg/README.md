# Mythic Websocket C2 Profile - server source

This project supports the Mythic websocket C2Profile.

Currently, there are two 'transports' which can be found at ./pkt/transport/:

1) prosaic (default)
    - Assumes message follow the C2 Profile structure

2) poseidon
    - Wraps messages in a custom structure as seen in ./pkg/transport/poseidon/model/blob.go

There is a config.json under each of the transports which contains the JSON required to create a transport of the type desired.

To add a transport, look at ./pkg/iface/iface.go interface TransportConfigData and the default transport (prosaic).

# F.A.Q.

Q: Why is the default transport named prosaic?
A: Because...'default' is a reserved keyword in Golang xD