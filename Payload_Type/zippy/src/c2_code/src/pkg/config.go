package config

import (
	iface "ArchiMoebius/mythic_c2_websocket/pkg/iface"
	"ArchiMoebius/mythic_c2_websocket/pkg/logger"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
)

// LoadAndParseConfig loads and parses the config for a transport
func LoadAndParseConfig(configFile string, verbose bool, debug bool) (*iface.TransportConfig, error) {
	logger.Log("[+] Websocket configuration loading")

	if configFile == "" {
		log.Fatal("You shouldn't be calling load and parse until things are more setup - read the docs my dude...")
	}

	config, err := ioutil.ReadFile(configFile) // #nosec G304

	if err != nil {
		logger.Log(fmt.Sprintf("Unable to read config file: %s", err))
		return nil, err
	}

	var apiConfig iface.TransportConfig

	err = json.Unmarshal([]byte(config), &apiConfig)

	if err != nil {
		logger.Log(fmt.Sprintf("Unable to unmarshal config: %s", err))
		return nil, err
	}

	apiConfig.Verbose = verbose
	apiConfig.Debug = debug

	logger.Log("[+] Websocket configuration loaded")

	return &apiConfig, nil
}
