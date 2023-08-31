package main

import (
	"context"
	"flag"
	"fmt"
	"log"
	"os"
	"os/signal"
	"syscall"
	"time"

	pkg "ArchiMoebius/mythic_c2_websocket/pkg"
	"ArchiMoebius/mythic_c2_websocket/pkg/logger"
)

var config = "./config.json"

// @title Mythic Websocket C2 Profile
// @description This is a C2 profile which proxies traffic to the Mythic API
// @license.name GNU GENERAL PUBLIC LICENSE
// @license.url http://www.gnu.org/licenses/

func main() {
	verbose := flag.Bool("v", false, "Enable verbose output")
	debug := flag.Bool("d", false, "Show debug messages")

	flag.StringVar(&config, "config", config, "The config - by default looks in the current directory for config.json")

	flag.Usage = usage
	flag.Parse()

	commonConfig, err := pkg.LoadAndParseConfig(config, *verbose, *debug)

	if err != nil {
		log.Fatal(err.Error())
	}

	err = commonConfig.Run()

	if err != nil {
		log.Fatal(err.Error())
	}

	quit := make(chan os.Signal, 1)

	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	fmt.Println()
	logger.Log("[+] Shutting down the Mythic Websocket C2")

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)

	defer cancel()

	if err := commonConfig.Shutdown(ctx); err != nil {
		logger.Log(fmt.Sprintf("[!] Server Shutdown Failure: %s", err.Error()))
	} else {
		logger.Log("[+] Server Shutdown Success")
	}

	shutdown()
}

func shutdown() {
	logger.Log("[+] Shutdown Mythic Websocket C2")
}

func usage() {
	fmt.Println("Mythic Websocket C2")
	flag.PrintDefaults()
}
