# Zippy

<p align="center">
  <img alt="Zippy Logo" src="documentation-payload/zippy/zippy.svg" height="30%" width="30%">
</p>

Zippy is an agent that compiles into Linux, (MacOS, and Windows - at some point) executables. It's an "IT training tool" - not ransomware...and is currently a WIP.

It leverages the [Godot](godotengine.org/) to cross compile for the supported operating systems. This Zippy instance supports Mythic 2.3 and will be updated as necessary. It does not support Mythic 2.2 and lower.

The agent has `mythic_payloadtype_container==0.1.8` PyPi package installed and reports to Mythic as version "12".

## Zippy's Icon

zippy's icon made with Gimp

## How to install an agent in this format within Mythic

TODO

When it's time for you to test out your install or for another user to install your agent, it's pretty simple. Within Mythic you can run the `mythic-cli` binary to install this in one of three ways:

* `sudo ./mythic-cli install github https://github.com/ArchiMoebius/zippy` to install the main branch
* `sudo ./mythic-cli install github https://github.com/ArchiMoebius/zippy main` to install a specific branch of that repo
* `sudo ./mythic-cli install folder /path/to/local/folder/cloned/from/github` to install from an already cloned down version of an agent repo

Now, you might be wondering _when_ should you or a user do this to properly add your agent to their Mythic instance. There's no wrong answer here, just depends on your preference. The three options are:

* Mythic is already up and going, then you can run the install script and just direct that agent's containers to start (i.e. `sudo ./mythic-cli payload start agentName` and if that agent has its own special C2 containers, you'll need to start them too via `sudo ./mythic-cli c2 start c2profileName`).
* Mythic is already up and going, but you want to minimize your steps, you can just install the agent and run `sudo ./mythic-cli mythic start`. That script will first _stop_ all of your containers, then start everything back up again. This will also bring in the new agent you just installed.
* Mythic isn't running, you can install the script and just run `sudo ./mythic-cli mythic start`. 

## Documentation

The Zippy documentation source code can be found in the `documenation-payload/zippy` directory.
View the rendered documentation by clicking on **Docs -> Agent Documentation** in the upper right-hand corner of the Mythic
interface. 

## Building Outside of Mythic

TODO

## Developing

TODO
