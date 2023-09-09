package common

import (
	"ArchiMoebius/mythic_c2_websocket/pkg/logger"
	"bytes"
	"crypto/rand"
	"crypto/rsa"
	"crypto/tls"
	"crypto/x509"
	"crypto/x509/pkix"
	"encoding/pem"
	"errors"
	"fmt"
	"io/ioutil"
	"math/big"
	"net"
	"time"

	websocket "github.com/gorilla/websocket"
)

var Upgrader = websocket.Upgrader{}

// BaseTransportConfig another lightweight plug
type BaseTransportConfig struct {
	Type                     string `json:"type"`
	TransportCertificate     []tls.Certificate
	TransportCertificatePool *x509.CertPool
	Verify                   bool
}

// GetType hack to return type and get dynamic json
func (d *BaseTransportConfig) GetType() string {
	return d.Type
}

func (d *BaseTransportConfig) GetVerify() bool {
	return d.Verify
}

func (d *BaseTransportConfig) GetCertificates() []tls.Certificate {
	return d.TransportCertificate
}

func (d *BaseTransportConfig) GetCertificateAuthority() *x509.CertPool {
	return d.TransportCertificatePool
}

func (d *BaseTransportConfig) HasCertificateAuthority() bool {
	return d.TransportCertificatePool != nil
}

func (d *BaseTransportConfig) HasCertificateAndKey() bool {
	return len(d.TransportCertificate) > 0
}

func LoadPKI(publicKeyPath string, privateKeyPath string, authorityPath string) (*tls.Certificate, *x509.CertPool, error) {
	var cert *tls.Certificate = nil
	var caPool *x509.CertPool = nil

	if publicKeyPath != "" && privateKeyPath != "" {
		c, err := tls.LoadX509KeyPair(publicKeyPath, privateKeyPath)

		if err != nil {
			return nil, nil, err
		}

		cert = &c
	} else if authorityPath != "" || privateKeyPath != "" {
		return nil, nil, errors.New("You must define both a cert and a key")
	}

	if authorityPath != "" {
		caCert, err := ioutil.ReadFile(authorityPath) // #nosec G304

		if err != nil {
			return nil, nil, err
		}

		caPool = x509.NewCertPool()
		caPool.AppendCertsFromPEM(caCert)
	}

	return cert, caPool, nil
}

// GenerateCertificate create a certifcate authority, public key and private key - returning the bytes for each or an error
func GenerateCertificate(hostIP string, domainName string) (*[]byte, *[]byte, *[]byte, error) {

	logger.Log(fmt.Sprintf("[I] GenerateCertificate for IP %s and domain %s", hostIP, domainName))

	ip := net.ParseIP(hostIP)

	// set up our CA certificate
	ca := &x509.Certificate{
		SerialNumber: big.NewInt(2022),
		Subject: pkix.Name{
			Organization:  []string{""},
			Country:       []string{""},
			Province:      []string{""},
			Locality:      []string{""},
			StreetAddress: []string{""},
			PostalCode:    []string{""},
		},
		NotBefore:             time.Now(),
		NotAfter:              time.Now().AddDate(10, 0, 0),
		IsCA:                  true,
		ExtKeyUsage:           []x509.ExtKeyUsage{x509.ExtKeyUsageClientAuth, x509.ExtKeyUsageServerAuth},
		KeyUsage:              x509.KeyUsageDigitalSignature | x509.KeyUsageCertSign,
		BasicConstraintsValid: true,
	}

	// create our private and public key
	caPrivKey, err := rsa.GenerateKey(rand.Reader, 4096)
	if err != nil {
		return nil, nil, nil, err
	}

	// create the CA
	caBytes, err := x509.CreateCertificate(rand.Reader, ca, ca, &caPrivKey.PublicKey, caPrivKey)
	if err != nil {
		return nil, nil, nil, err
	}

	// pem encode
	caPEM := new(bytes.Buffer)

	err = pem.Encode(caPEM, &pem.Block{
		Type:  "CERTIFICATE",
		Bytes: caBytes,
	})

	if err != nil {
		return nil, nil, nil, err
	}

	caPrivKeyPEM := new(bytes.Buffer)
	if err := pem.Encode(caPrivKeyPEM, &pem.Block{
		Type:  "RSA PRIVATE KEY",
		Bytes: x509.MarshalPKCS1PrivateKey(caPrivKey),
	}); err != nil {
		return nil, nil, nil, err
	}

	// set up our server certificate
	cert := &x509.Certificate{
		SerialNumber: big.NewInt(2022),
		Subject: pkix.Name{
			Organization:  []string{""},
			Country:       []string{""},
			Province:      []string{""},
			Locality:      []string{""},
			StreetAddress: []string{""},
			PostalCode:    []string{""},
		},
		IPAddresses:  []net.IP{ip, net.IPv4(127, 0, 0, 1), net.IPv6loopback},
		NotBefore:    time.Now(),
		NotAfter:     time.Now().AddDate(10, 0, 0),
		SubjectKeyId: []byte{1, 2, 3, 4, 6},
		ExtKeyUsage:  []x509.ExtKeyUsage{x509.ExtKeyUsageClientAuth, x509.ExtKeyUsageServerAuth, x509.ExtKeyUsageAny},
		KeyUsage:     x509.KeyUsageDigitalSignature,
	}

	cert.DNSNames = append(cert.DNSNames, domainName)

	certPrivKey, err := rsa.GenerateKey(rand.Reader, 4096)
	if err != nil {
		return nil, nil, nil, err
	}

	certBytes, err := x509.CreateCertificate(rand.Reader, cert, ca, &certPrivKey.PublicKey, caPrivKey)
	if err != nil {
		return nil, nil, nil, err
	}

	certPEM := new(bytes.Buffer)
	err = pem.Encode(certPEM, &pem.Block{
		Type:  "CERTIFICATE",
		Bytes: certBytes,
	})
	if err != nil {
		return nil, nil, nil, err
	}

	certPrivKeyPEM := new(bytes.Buffer)
	err = pem.Encode(certPrivKeyPEM, &pem.Block{
		Type:  "RSA PRIVATE KEY",
		Bytes: x509.MarshalPKCS1PrivateKey(certPrivKey),
	})
	if err != nil {
		return nil, nil, nil, err
	}

	publicKey := certPEM.Bytes()
	privateKey := certPrivKeyPEM.Bytes()

	logger.Log(fmt.Sprintf("[+] Success GenerateCertificate for IP %s and domain %s", hostIP, domainName))

	return &caBytes, &publicKey, &privateKey, nil
}
