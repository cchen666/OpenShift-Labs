package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"

	"github.com/labstack/echo/v4"
	"github.com/labstack/echo/v4/middleware"
	"golang.org/x/oauth2"
)

var oauthConfig = &oauth2.Config{
	ClientID:     "reverse-words",
	ClientSecret: "aaa",
	RedirectURL:  "http://oauthclient-app-reverse-words.apps.gcg-shift.cchen.work/callback",
	Endpoint: oauth2.Endpoint{
		AuthURL:  "https://oauth-openshift.apps.gcg-shift.cchen.work/oauth/authorize",
		TokenURL: "https://oauth-openshift.apps.gcg-shift.cchen.work/oauth/token",
	},
	Scopes: []string{"user:info"},
}

func main() {
	e := echo.New()
	e.Use(middleware.Logger())
	e.Use(middleware.Recover())

	e.GET("/", handleMain)
	e.GET("/login", handleLogin)
	e.GET("/logout", handleLogout)
	e.GET("/callback", handleCallback)

	e.Logger.Fatal(e.Start(":5000"))
}

func handleMain(c echo.Context) error {
	token, ok := c.Get("openshift_token").(string)
	if ok && token != "" {
		return c.String(http.StatusOK, "You are logged in! <a href=\"/logout\">Logout</a>")
	}
	return c.String(http.StatusOK, "<a href=\"/login\">Login to OpenShift</a>")
}

func handleLogin(c echo.Context) error {
	URL := oauthConfig.AuthCodeURL("state", oauth2.AccessTypeOffline)
	return c.Redirect(http.StatusTemporaryRedirect, URL)
}

func handleLogout(c echo.Context) error {
	c.Set("openshift_token", "")
	return c.Redirect(http.StatusTemporaryRedirect, "/")
}

func handleCallback(c echo.Context) error {
	code := c.QueryParam("code")
	token, err := oauthConfig.Exchange(oauth2.NoContext, code)
	if err != nil {
		return c.String(http.StatusInternalServerError, "Code exchange failed: "+err.Error())
	}

	// Get user info
	userInfo, err := getUserInfo(token)
	if err != nil {
		return c.String(http.StatusInternalServerError, "Failed to retrieve user details: "+err.Error())
	}

	c.Set("openshift_token", token.AccessToken)
	return c.String(http.StatusOK, fmt.Sprintf("Logged in as: %s", userInfo.Metadata.Name))
}

type User struct {
	Metadata struct {
		Name string `json:"name"`
	} `json:"metadata"`
}

func getUserInfo(token *oauth2.Token) (*User, error) {
	client := &http.Client{}
	req, err := http.NewRequest("GET", "https://openshift-apiserver-url/apis/user.openshift.io/v1/users/~", nil)
	if err != nil {
		return nil, err
	}
	req.Header.Add("Authorization", "Bearer "+token.AccessToken)
	resp, err := client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	data, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	user := &User{}
	err = json.Unmarshal(data, user)
	if err != nil {
		return nil, err
	}

	return user, nil
}
