package upstream

import (
	"bytes"
	"compress/gzip"
	"fmt"
	"io/ioutil"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/stretchr/testify/require"
)

func TestGzipEncoding(t *testing.T) {
	resp := httptest.NewRecorder()

	var b bytes.Buffer
	w := gzip.NewWriter(&b)
	fmt.Fprint(w, "test")
	w.Close()

	body := ioutil.NopCloser(&b)

	req, err := http.NewRequest("POST", "http://address/test", body)
	require.NoError(t, err)
	req.Header.Set("Content-Encoding", "gzip")

	contentEncodingHandler(http.HandlerFunc(func(_ http.ResponseWriter, r *http.Request) {
		require.IsType(t, &gzip.Reader{}, r.Body, "body type")
		require.Empty(t, r.Header.Get("Content-Encoding"), "Content-Encoding should be deleted")
	})).ServeHTTP(resp, req)

	require.Equal(t, 200, resp.Code)
}

func TestNoEncoding(t *testing.T) {
	resp := httptest.NewRecorder()

	var b bytes.Buffer
	body := ioutil.NopCloser(&b)

	req, err := http.NewRequest("POST", "http://address/test", body)
	require.NoError(t, err)
	req.Header.Set("Content-Encoding", "")

	contentEncodingHandler(http.HandlerFunc(func(_ http.ResponseWriter, r *http.Request) {
		require.Equal(t, body, r.Body, "Expected the same body")
		require.Empty(t, r.Header.Get("Content-Encoding"), "Content-Encoding should be deleted")
	})).ServeHTTP(resp, req)

	require.Equal(t, 200, resp.Code)
}

func TestInvalidEncoding(t *testing.T) {
	resp := httptest.NewRecorder()

	req, err := http.NewRequest("POST", "http://address/test", nil)
	require.NoError(t, err)
	req.Header.Set("Content-Encoding", "application/unknown")

	contentEncodingHandler(http.HandlerFunc(func(_ http.ResponseWriter, _ *http.Request) {
		t.Fatal("it shouldn't be executed")
	})).ServeHTTP(resp, req)

	require.Equal(t, 500, resp.Code)
}
