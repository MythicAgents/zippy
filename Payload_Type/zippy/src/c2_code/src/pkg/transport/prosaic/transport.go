package prosaic

import (
	common "ArchiMoebius/mythic_c2_websocket/pkg/transport/common"
	"crypto/tls"
	"crypto/x509"
	"encoding/json"
	"errors"
	"fmt"
	"io/ioutil"
)

// Transport for default configuration params
type Transport struct {
	common.BaseTransportConfig
	CertificateFile          string `json:"server_certificate"`
	KeyFile                  string `json:"server_key"`
	CertificateAuthorityFile string `json:"server_certificate_authority"`
	GeneratePKI              bool   `json:"server_generate_pki"`
	VerifyTLS                bool   `json:"server_verify_tls"`
	MTLS                     bool   `json:"server_mtls"`
	Host                     string `json:"server_host"`
	Port                     int    `json:"server_port"`
	DomainName               string `json:"domain_name"`
	WebsocketFilename        string `json:"websocket_filename"`
	HTTPFilename             string `json:"http_filename"`
	LogPath                  string `json:"log_path"`
}

func (d *Transport) UseMTLS() bool {
	return d.MTLS
}

func (d *Transport) GetLogPath(string) string {
	return d.LogPath
}

func (d *Transport) GetHTTPFilename() string {
	return d.HTTPFilename
}

func (d *Transport) GetWebSocketFilename() string {
	return d.WebsocketFilename
}

func (d *Transport) GetServerAddress() string {
	return fmt.Sprintf("%s:%d", d.Host, d.Port)
}

func (d *Transport) ParseClientMessage(blob []byte) ([]byte, []byte, error) {
	// No custom parsing required ; )
	return blob, nil, nil
}

func (d *Transport) ParseMythicResponse(blob []byte, meta []byte) ([]byte, error) {
	// No custom parsing required ; )
	return blob, nil
}

func (d *Transport) Load() error {

	if !d.GeneratePKI && d.CertificateFile == "" && d.KeyFile == "" {
		return nil // Plain'ol HTTP requested
	}

	if d.GeneratePKI && (d.CertificateFile != "" || d.KeyFile != "") {
		return errors.New("server_generate_pki and (server_key, server_certificate) are mutually exclusive options")
	}

	d.Verify = d.VerifyTLS

	if d.GeneratePKI {

		caBytes, publicKey, privateKey, err := common.GenerateCertificate(d.Host, d.DomainName)

		if err != nil {
			return err
		}

		serverCert, err := tls.X509KeyPair(*publicKey, *privateKey)

		if err != nil {
			return err
		}

		d.TransportCertificate = append(d.TransportCertificate, serverCert)

		d.TransportCertificatePool = x509.NewCertPool()
		d.TransportCertificatePool.AppendCertsFromPEM(*caBytes)

		return nil
	}

	if (d.CertificateFile != "" || d.KeyFile != "") && (d.CertificateFile == "" || d.KeyFile == "") {
		return errors.New("You must define both a cert and a key")
	}

	if d.MTLS && d.CertificateAuthorityFile == "" {
		return errors.New("You must provide a ca if using mTLS")
	}

	d.TransportCertificatePool = nil

	serverCert, auth, err := common.LoadPKI(d.CertificateFile, d.KeyFile, d.CertificateAuthorityFile)

	if err != nil {
		return err
	}

	d.TransportCertificate = append(d.TransportCertificate, *serverCert)
	d.TransportCertificatePool = auth

	if d.CertificateAuthorityFile != "" {
		caCert, err := ioutil.ReadFile(d.CertificateAuthorityFile) // #nosec G304

		if err != nil {
			return err
		}

		d.TransportCertificatePool = x509.NewCertPool()
		d.TransportCertificatePool.AppendCertsFromPEM(caCert)
	}

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
