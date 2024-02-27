# Ollama

<https://github.com/ollama/ollama>

## Installation

```bash
$ podman pull docker.io/ollama/ollama
```

## Run the Ollama Daemon/Tool

```bash
$ alias ollama="podman run -d -v ollama:/root/.ollama -p 11434:11434 --name ollama ollama/ollama"

$ ollama

$ podman ps
CONTAINER ID  IMAGE                           COMMAND     CREATED        STATUS        PORTS                     NAMES
0f7ba468d397  docker.io/ollama/ollama:latest  serve       7 seconds ago  Up 7 seconds  0.0.0.0:11434->11434/tcp  ollama

$ podman logs 0f7ba468d397
Couldn't find '/root/.ollama/id_ed25519'. Generating new private key.
Your new public key is:

ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBYt/8yS3gjyb8vV2qxfEWqE8DY/Wl8P2dkO/K1mUAMZ

time=2024-02-27T08:05:42.427Z level=INFO source=images.go:710 msg="total blobs: 0"
time=2024-02-27T08:05:42.427Z level=INFO source=images.go:717 msg="total unused blobs removed: 0"
time=2024-02-27T08:05:42.428Z level=INFO source=routes.go:1019 msg="Listening on [::]:11434 (version 0.1.27)"
time=2024-02-27T08:05:42.428Z level=INFO source=payload_common.go:107 msg="Extracting dynamic libraries..."
time=2024-02-27T08:05:45.854Z level=INFO source=payload_common.go:146 msg="Dynamic LLM libraries [rocm_v5 cpu_avx cpu_avx2 cpu rocm_v6 cuda_v11]"
time=2024-02-27T08:05:45.854Z level=INFO source=gpu.go:94 msg="Detecting GPU type"
time=2024-02-27T08:05:45.854Z level=INFO source=gpu.go:265 msg="Searching for GPU management library libnvidia-ml.so"
time=2024-02-27T08:05:45.855Z level=INFO source=gpu.go:311 msg="Discovered GPU libraries: []"
time=2024-02-27T08:05:45.855Z level=INFO source=gpu.go:265 msg="Searching for GPU management library librocm_smi64.so"
time=2024-02-27T08:05:45.855Z level=INFO source=gpu.go:311 msg="Discovered GPU libraries: []"
time=2024-02-27T08:05:45.855Z level=INFO source=cpu_common.go:11 msg="CPU has AVX2"
time=2024-02-27T08:05:45.855Z level=INFO source=routes.go:1042 msg="no GPU detected"

```

## Run the Model

```bash
# podman exec -it 0f7ba468d397 /bin/bash
root@0f7ba468d397:/# ollama run gemma:2b
pulling manifest
pulling c1864a5eb193... 100% ▕████████████████████████████████████████████████████████████████████████████████████▏ 1.7 GB
pulling 097a36493f71... 100% ▕████████████████████████████████████████████████████████████████████████████████████▏ 8.4 KB
pulling 109037bec39c... 100% ▕████████████████████████████████████████████████████████████████████████████████████▏  136 B
pulling 22a838ceb7fb... 100% ▕████████████████████████████████████████████████████████████████████████████████████▏   84 B
pulling 887433b89a90... 100% ▕████████████████████████████████████████████████████████████████████████████████████▏  483 B
verifying sha256 digest
writing manifest
removing any unused layers
success
>>> Send a message (/? for help)
>>> How are you
As a large language model, I do not have physical experiences or feelings. I am a computer program trained on a massive amount of text data.

I am here to assist you with a wide range of tasks and provide information based on the knowledge I have been trained on. How can I help you
today?

```

## Run the Golang CLI

```bash
$ go run main.go
You: How are you
AI: I am doing well and functioning as usual. I am here to assist you with any questions or tasks you may have. How are you doing?
You: Fine thanks. What's weather in Dalian today
AI: I do not have access to real-time weather information, therefore I cannot answer this question. For the most up-to-date weather conditions, please check a weather forecast on a reputable website such as Weather.com, National Weather Service, or AccuWeather.
You: Give me the link of it
AI: I'm unable to provide links or access external content, so I cannot provide the link you requested.
You: What is OpenShift
AI: *OpenShift* is an open-source platform for building, running, and managing containerized applications on a shared, decentralized infrastructure. It is designed to be *highly scalable, resilient, and cost-effective*.

*Key features of OpenShift:*

* *Container registry:* Stores and manages container images.
* *Containerized applications:* Packages applications into containers for portability.
* *Networking:* Provides secure and efficient communication between containers.
* *Configuration management:* Manages application configurations and secrets.
* *CI/CD:* Automates application development, testing, and deployment.
* *Monitoring and logging:* Provides insights into application performance and health.
* *Security:* Enforces security policies and controls access to containers.

*Benefits of OpenShift:*

* *Reduced development time and costs:* Simplifies application development and deployment.
* *Improved security and compliance:* Enforces security best practices and complies with regulations.
* *Enhanced scalability and reliability:* Provides automatic scaling and high availability.
* *Reduced operational overhead:* Automates tasks and simplifies management.
* *Community support:* Benefit from a large and active community of developers and vendors.

*Use cases for OpenShift:*

* *Microservices and serverless applications*
* *Cloud-native development and operations*
* *High-performance computing*
* *Data analytics and machine learning*
* *Agile software development*

*Overall, OpenShift is a powerful platform for building, managing, and running modern containerized applications.*

*Additional resources:*

* *OpenShift website:* openshift.com
* *OpenShift documentation:* docs.openshift.com
* *OpenShift tutorials:* openshift.com/ tutorials
``
