# Zippy

<p align="center">
  <img alt="Zippy Logo" src="documentation-payload/zippy/zippy.svg" height="30%" width="30%">
</p>

Zippy is an agent that compiles into a Linux or Windows executable. It's an "IT training tool" - not ransomware...

It leverages the [Godot game engine](https://godotengine.org/) to cross compile for the supported operating systems. This Zippy instance supports Mythic 3.0 and will be updated as necessary. It does not support versions of Mythic lower than 3.0!

## Commands

The agent support the following commands: cat, **clipboard**, **cover**, cp, **curl**, cwd, download, exit, kill, ls, mv, **ransom**, record, rm, sleep, **socks**, spawn, upload, and whoami.

## How to install

Within Mythic you can run the `mythic-cli` binary to install this agent from the main branch:
```bash
sudo ./mythic-cli install github https://github.com/MythicAgents/zippy
```

## Documentation

The Zippy documentation source code can be found in the `documenation-payload/zippy` directory.
View the rendered documentation by clicking on **Docs -> Agent Documentation** in the upper right-hand corner of the Mythic
interface. 

## Building Outside of Mythic

Use the [Godot v4.1 + editor](https://github.com/godotengine/godot/releases/download/4.1.1-stable/Godot_v4.1.1-stable_linux.x86_64.zip) to load the agent_code directory.

## Developing

Use the [Godot v4.1 + editor](https://github.com/godotengine/godot/releases/download/4.1.1-stable/Godot_v4.1.1-stable_linux.x86_64.zip) and have Mythic setup - generate an agent, copy the details into the provided 'config_zippy-websocket.json' file and press F5.

## Zippy's Icon

Zippy's icon was made with Gimp. If you're an artist - feel free to make something snazzier.
