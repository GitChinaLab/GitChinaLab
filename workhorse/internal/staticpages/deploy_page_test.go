package staticpages

import (
	"io/ioutil"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"testing"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/testhelper"

	"github.com/stretchr/testify/require"
)

func TestIfNoDeployPageExist(t *testing.T) {
	dir, err := ioutil.TempDir("", "deploy")
	if err != nil {
		t.Fatal(err)
	}
	defer os.RemoveAll(dir)

	w := httptest.NewRecorder()

	executed := false
	st := &Static{DocumentRoot: dir}
	st.DeployPage(http.HandlerFunc(func(_ http.ResponseWriter, _ *http.Request) {
		executed = true
	})).ServeHTTP(w, nil)
	if !executed {
		t.Error("The handler should get executed")
	}
}

func TestIfDeployPageExist(t *testing.T) {
	dir, err := ioutil.TempDir("", "deploy")
	if err != nil {
		t.Fatal(err)
	}
	defer os.RemoveAll(dir)

	deployPage := "DEPLOY"
	ioutil.WriteFile(filepath.Join(dir, "index.html"), []byte(deployPage), 0600)

	w := httptest.NewRecorder()

	executed := false
	st := &Static{DocumentRoot: dir}
	st.DeployPage(http.HandlerFunc(func(_ http.ResponseWriter, _ *http.Request) {
		executed = true
	})).ServeHTTP(w, nil)
	if executed {
		t.Error("The handler should not get executed")
	}
	w.Flush()

	require.Equal(t, 200, w.Code)
	testhelper.RequireResponseBody(t, w, deployPage)
}
