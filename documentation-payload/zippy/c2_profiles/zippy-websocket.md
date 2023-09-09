+++
title = "zippy-websocket"
chapter = false
weight = 102
+++

## Summary

The zippy implementation of the websocket C2 profile has no deviations. 

### Profile Option Deviations

### Building an Agent

#### Build an agent with debug turned on

This will print debug information on stdout/stderr - which you might want...or not...

#### Enable TLS certificate verification

This will enable mTLS certificate verification - maybe...

#### Target architecture

x86_64 / x86_32 for both Windows and Linux executables.

#### Callback Host

The URL for the redirector or Mythic server. This must include the protocol to use (e.g. `ws://` or `wss://` - if the latter is used, ensure the C2 profile is using TLS).

#### Callback Interval in seconds

How many seconds the agent should sleep before calling back to the Mythic server for tasking.

#### Callback Jitter in seconds

How many seconds should be used as the maximum jitter time added to callback interval to blend callback times with 'normal' traffic.

#### Callback Port

The C2 Profiles listening port should match this value...duh!

#### Crypto type

AES256-HMAC or None - if none...well, bold move cotton.

#### Host header value for domain fronting

Not really used much...eh?

#### User Agent

The User-Agent header used for communication with the Mythic server.

#### Websockets Endpoint

The C2 endpoint for websockets - default is `socket` - change your C2 profile if you change this - duh...