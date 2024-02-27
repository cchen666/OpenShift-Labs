package main

import (
	"bufio"
	"bytes"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"os"
	"strings"
)

type RequestPayload struct {
	Model  string `json:"model"`
	Prompt string `json:"prompt"`
	Stream bool   `json:"stream"`
}

type ResponsePayload struct {
	Model              string `json:"model"`
	CreatedAt          string `json:"created_at"`
	Response           string `json:"response"`
	Done               bool   `json:"done"`
	Context            []int  `json:"context"`
	TotalDuration      int64  `json:"total_duration"`
	LoadDuration       int64  `json:"load_duration"`
	PromptEvalCount    int    `json:"prompt_eval_count"`
	PromptEvalDuration int64  `json:"prompt_eval_duration"`
	EvalCount          int    `json:"eval_count"`
	EvalDuration       int64  `json:"eval_duration"`
}

func main() {
	reader := bufio.NewReader(os.Stdin)

	for { // Infinite loop
		fmt.Print("You: ")
		userInput, err := reader.ReadString('\n')
		if err != nil {
			fmt.Println("Error reading input:", err)
			continue
		}
		userInput = strings.TrimSpace(userInput) // Remove the newline character

		url := "http://10.0.111.25:11434/api/generate"
		requestBody := RequestPayload{
			Model:  "gemma:2b",
			Prompt: userInput,
			Stream: false,
		}

		jsonData, err := json.Marshal(requestBody)
		if err != nil {
			fmt.Println("Error encoding request data:", err)
			continue
		}

		resp, err := http.Post(url, "application/json", bytes.NewBuffer(jsonData))
		if err != nil {
			fmt.Println("Error sending request:", err)
			continue
		}
		defer resp.Body.Close()

		body, err := ioutil.ReadAll(resp.Body)
		if err != nil {
			fmt.Println("Error reading response body:", err)
			continue
		}

		var responsePayload ResponsePayload
		if err := json.Unmarshal(body, &responsePayload); err != nil {
			fmt.Println("Error decoding response data:", err)
			continue
		}

		// Process the response to handle \n for newline and ** for bold
		responseText := responsePayload.Response
		responseText = strings.ReplaceAll(responseText, "\\n", "\n")
		responseText = strings.ReplaceAll(responseText, "**", "*") // Simple replacement, consider more sophisticated markdown rendering

		fmt.Println("AI:", responseText)
	}
}
