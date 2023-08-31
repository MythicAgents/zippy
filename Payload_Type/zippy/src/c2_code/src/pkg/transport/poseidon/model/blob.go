package poseidon

import "encoding/json"

type BlobStructure struct {
	Tag    string `json:"tag"`
	Client bool   `json:"client"`
	Data   string `json:"data"`
}

// MarshalString hack to return data as a json string
func (d *BlobStructure) MarshalString() (string, error) {
	data, err := json.Marshal(d)

	if err != nil {
		return "", err
	}

	return string(data[:]), nil
}
