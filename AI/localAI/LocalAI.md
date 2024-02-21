# LocalAI

## Installation

```bash
$ podman run -ti -p 8080:8080 localai/localai:v2.8.2-ffmpeg-core phi-2
```

## API

```bash
$ curl http://localhost:8080/v1/chat/completions -H "Content-Type: application/json" -d '{
    "model": "phi-2",
    "messages": [{"role": "user", "content": "What is your job"}]
}'

{"created":1708485559,"object":"chat.completion","id":"3a5753c5-dd7e-4b48-80cb-6523de24267b","model":"phi-2","choices":[{"index":0,"finish_reason":"stop","message":{"role":"assistant","content":"Hello, my name is John and I am a teacher."}}],"usage":{"prompt_tokens":0,"completion_tokens":0,"total_tokens":0}}
```

## UI

```bash
$ go run main.go
You: What is 65lbs to kg?
AI: 65lbs is equal to 29.48kg.
You:
```
