package logger

import (
	"github.com/fatih/color"
)

// Log a message to the console with color
func Log(message string) {

	switch string(message[1]) {
	case "I":
		color.Cyan(message)
	case "!":
		color.Red(message)
	case "D":
		color.Yellow(message)
	case "+":
		color.Green(message)
	default:
		color.Red("[-] Error: " + message)
	}
}
