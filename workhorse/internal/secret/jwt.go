package secret

import (
	"fmt"

	"github.com/golang-jwt/jwt/v4"
)

var (
	DefaultClaims = jwt.StandardClaims{Issuer: "gitlab-workhorse"}
)

func JWTTokenString(claims jwt.Claims) (string, error) {
	secretBytes, err := Bytes()
	if err != nil {
		return "", fmt.Errorf("secret.JWTTokenString: %v", err)
	}

	tokenString, err := jwt.NewWithClaims(jwt.SigningMethodHS256, claims).SignedString(secretBytes)
	if err != nil {
		return "", fmt.Errorf("secret.JWTTokenString: sign JWT: %v", err)
	}

	return tokenString, nil
}
