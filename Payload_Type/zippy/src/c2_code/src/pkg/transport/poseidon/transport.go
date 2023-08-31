package poseidon

import (
	"ArchiMoebius/mythic_c2_websocket/pkg/logger"
	common "ArchiMoebius/mythic_c2_websocket/pkg/transport/common"
	model "ArchiMoebius/mythic_c2_websocket/pkg/transport/poseidon/model"
	"encoding/base64"
	"encoding/json"
	"fmt"
)

type Transport struct {
	common.BaseTransportConfig
	BindAddress  string `json:"bindaddress"`
	UseSSL       bool   `json:"usessl"`
	SSLKey       string `json:"sslkey"`
	SSLCert      string `json:"sslcert"`
	WebSocketURI string `json:"websocketuri"`
	DefaultPage  string `json:"defaultpage"`
	LogFile      string `json:"logfile"`
	Debug        bool   `json:"debug"`
}

func (d *Transport) UseMTLS() bool {
	return false
}

func (d *Transport) GetLogPath(string) string {
	return fmt.Sprintf("/Mythic/c2_code/%s", d.LogFile)
}

func (d *Transport) GetHTTPFilename() string {
	return d.DefaultPage
}

func (d *Transport) GetWebSocketFilename() string {
	return d.WebSocketURI
}

func (d *Transport) GetServerAddress() string {
	return d.BindAddress
}

func (d *Transport) ParseMythicResponse(blob []byte, meta []byte) ([]byte, error) {

	reply := model.BlobStructure{Client: false}

	if len(blob) == 0 {
		reply.Data = string(make([]byte, 1))
	} else {
		reply.Data = string(blob)
	}

	reply.Tag = string(meta)

	resp, err := json.Marshal(reply)

	if err != nil {
		return blob, err
	}

	return resp, nil
}

func (d *Transport) ParseClientMessage(blob []byte) ([]byte, []byte, error) {
	var messageAPI model.BlobStructure

	err := json.Unmarshal(blob, &messageAPI)

	if err != nil {
		logger.Log(fmt.Sprintf("Unable to unmarshal blob: %v", blob))
		return nil, nil, err
	}

	msg := make([]byte, len(messageAPI.Data)*len(messageAPI.Data)/base64.StdEncoding.DecodedLen(len(messageAPI.Data)))

	_, err = base64.StdEncoding.Decode(msg, []byte(messageAPI.Data))

	if err != nil {
		logger.Log(fmt.Sprintf("[!] Failed to base64 decode: %s", err.Error()))
		return blob, []byte(messageAPI.Tag), err
	}

	return msg, []byte(messageAPI.Tag), nil
}

func (d *Transport) Load() error {
	return nil
}

// MarshalString hack to return data as a json string
func (d *Transport) MarshalString() (string, error) {
	data, err := json.Marshal(d)

	if err != nil {
		return "", err
	}

	return string(data[:]), nil
}
