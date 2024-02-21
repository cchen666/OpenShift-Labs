package main

import (
	"bufio"
	"bytes"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"os"
)

// Define a struct to match the JSON payload structure for requests
type AIRequest struct {
	Model    string    `json:"model"`
	Messages []Message `json:"messages"`
}

// Define a struct to represent each message part of the request
type Message struct {
	Role    string `json:"role"`
	Content string `json:"content"`
}

// Define a struct to match the structure of the JSON response from the AI

type AIResponse struct {
	ID      string `json:"id"`
	Choices []struct {
		Message struct {
			Role    string `json:"role"`
			Content string `json:"content"`
		} `json:"message"`
	} `json:"choices"`
}

func main() {
	// Your AI backend endpoint
	endpoint := "http://localhost:8080/v1/chat/completions"

	for {
		fmt.Print("You: ")
		reader := bufio.NewReader(os.Stdin)
		userInput, _ := reader.ReadString('\n')

		// Populate the request data
		requestData := AIRequest{
			Model: "phi-2",
			Messages: []Message{
				{
					Role:    "user",
					Content: userInput,
				},
			},
		}

		// Marshal request data to JSON
		jsonData, err := json.Marshal(requestData)
		if err != nil {
			fmt.Println("Error marshalling request data:", err)
			continue
		}

		// Make the HTTP request with json payload
		resp, err := http.Post(endpoint, "application/json", bytes.NewBuffer(jsonData))
		if err != nil {
			fmt.Println("Error making request:", err)
			continue
		}
		defer resp.Body.Close()

		// Read the response body
		body, err := ioutil.ReadAll(resp.Body)
		if err != nil {
			fmt.Println("Error reading response body:", err)
			continue
		}
		// Unmarshal the response data
		var aiResponse AIResponse
		err = json.Unmarshal(body, &aiResponse)
		if err != nil {
			fmt.Println("Error unmarshalling response data:", err)
			continue
		}

		// Output the AI's response
		fmt.Printf("AI: %v\n", aiResponse.Choices[0].Message.Content)
	}
}
