+++
title = "socks"
chapter = false
weight = 116
hidden = false
+++

## Summary

This establishes a SOCKS5 proxy through the Zippy agent, permitting tooling to be proxied through the compromised host.
  
- Needs Admin: False
- Version: 1  
- Author: @ArchiMoebius  

### Arguments

action - start or stop
port - 7001-7009 by default

## Usage

```
socks start/stop port
```

## MITRE ATT&CK Mapping

- T1059  

## Detailed Summary

Provide connectivity via the Zippy agent to internal systems.