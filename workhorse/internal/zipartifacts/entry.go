package zipartifacts

import (
	"encoding/base64"
)

func DecodeFileEntry(entry string) (string, error) {
	decoded, err := base64.StdEncoding.DecodeString(entry)
	if err != nil {
		return "", err
	}
	return string(decoded), nil
}
