# Tekton Tutorial Pipeline

<https://github.com/openshift/pipelines-tutorial>

## Create Task

```bash

$ oc apply -f 01_pipeline/01_apply_manifest_task.yaml
$ oc apply -f 01_pipeline/02_update_deployment_task.yaml

```

## Create Pipeline

```bash
$ oc appply -f 01_pipeline/04_pipeline.yaml
```

## Create Triggers

```bash
$ oc apply -f 03_triggers/02_template.yaml
$ oc apply -f 03_triggers/03_tigger.yaml
$ oc apply -f 03_triggers/01_binding.yaml
$ oc apply -f 03_triggers/04_event_listener.yaml # https://github.com/tektoncd/triggers/blob/main/examples/v1beta1/gitlab/gitlab-push-listener.yaml

$ oc expose svc el-vote-app

```

## Add Webhooks in Gitlab UI

1. Get the webhook URL by running `oc  get route el-vote-app --template='http://{{.spec.host}}')`
2. Fill in the secret with "1234567"

## Known Issues

1. event type  is not allowed

    ```log
    {"severity":"info","timestamp":"2023-05-25T06:09:18.407Z","logger":"eventlistener","caller":"sink/sink.go:418","message":"interceptor stopped trigger processing: rpc error: code = FailedPrecondition desc = event type  is not allowed","commit":"ebff8e2","eventlistener":"vote-app","namespace":"pipelines-tutorial","/triggers-eventid":"a60cbd25-5eda-403d-99a6-9258c49960cd","eventlistenerUID":"1f0e0a79-2756-4482-8097-9197bd28be43","/triggers-eventid":"a60cbd25-5eda-403d-99a6-9258c49960cd","/trigger":"vote-trigger"}
    ```

    Solution: Change interceptors.ref.name to "gitlab"

    ```yaml
      interceptors:
    - ref:
        name: "gitlab" # Need to change from github to gitlab
    ```

2. event type Push Hook is not allowed

    ```log
    {"severity":"info","timestamp":"2023-05-25T06:33:58.155Z","logger":"eventlistener","caller":"sink/sink.go:418","message":"interceptor stopped trigger processing: rpc error: code = FailedPrecondition desc = event type Push Hook is not allowed","commit":"ebff8e2","eventlistener":"vote-app","namespace":"pipelines-tutorial","/triggers-eventid":"35a340c7-1be7-4d54-b5b0-67a86c2a57e2","eventlistenerUID":"1f0e0a79-2756-4482-8097-9197bd28be43","/triggers-eventid":"35a340c7-1be7-4d54-b5b0-67a86c2a57e2","/trigger":"vote-trigger"}
    ```

    Solution: Change eventTypes to Push Hook

    ```yaml
      interceptors:
    - ref:
        name: "gitlab" # Need to change from github to gitlab
      params:
        - name: "secretRef"
          value:
            secretName: gitlab-secret
            secretKey: secretToken
        - name: "eventTypes"
          value: ["Push Hook"] # Need to change from ["push"] to ["Push Hook"]
    ```

3. git fetch failed. In build log:

    ```log
    + git config --global --add safe.directory /workspace/output
    + /ko-app/git-init -url=git@gitlab.com:cchen9/pipelines-vote-api.git -revision=master -refspec= -path=/workspace/output/ -sslVerify=true -submodules=true -depth=1 -sparseCheckoutDirectories=
    {"level":"warn","ts":1684998235.0963361,"caller":"git/git.go:271","msg":"URL(\"git@gitlab.com:cchen9/pipelines-vote-api.git\") appears to need SSH authentication but no SSH credentials have been provided"}
    {"level":"error","ts":1684998235.2810924,"caller":"git/git.go:53","msg":"Error running git [fetch --recurse-submodules=yes --depth=1 origin --update-head-ok --force master]: exit status 128\nWarning: Permanently added 'gitlab.com,172.65.251.78' (ECDSA) to the list of known hosts.\r\ngit@gitlab.com: Permission denied (publickey).\r\nfatal: Could not read from remote repository.\n\nPlease make sure you have the correct access rights\nand the repository exists.\n","stacktrace":"github.com/tektoncd/pipeline/pkg/git.run\n\t/go/src/github.com/tektoncd/pipeline/pkg/git/git.go:53\ngithub.com/tektoncd/pipeline/pkg/git.Fetch\n\t/go/src/github.com/tektoncd/pipeline/pkg/git/git.go:156\nmain.main\n\t/go/src/github.com/tektoncd/pipeline/cmd/git-init/main.go:53\nruntime.main\n\t/usr/lib/golang/src/runtime/proc.go:250"}
    {"level":"fatal","ts":1684998235.2811527,"caller":"git-init/main.go:54","msg":"Error fetching git repository: failed to fetch [master]: exit status 128","stacktrace":"main.main\n\t/go/src/github.com/tektoncd/pipeline/cmd/git-init/main.go:54\nruntime.main\n\t/usr/lib/golang/src/runtime/proc.go:250"}
    ```

    Solution: Change 01_binding.yaml

    ```yaml
    spec:
        params:
        - name: git-repo-url
            value: $(body.repository.git_http_url) # Need to change from repository.url to repository.git_http_url
    ```

4. RFC 1123 subdomain

    ```log
    {"severity":"error","timestamp":"2023-05-25T06:50:52.561Z","logger":"eventlistener","caller":"sink/sink.go:583","message":"problem creating obj: &errors.errorString{s:\"couldn't create resource with group version kind \\\"tekton.dev/v1beta1, Resource=pipelineruns\\\": PipelineRun.tekton.dev \\\"build-deploy-Pipelines Vote Api-2t2rv\\\" is invalid: [metadata.generateName: Invalid value: \\\"build-deploy-Pipelines Vote Api-\\\": a lowercase RFC 1123 subdomain must consist of lower case alphanumeric characters, '-' or '.', and must start and end with an alphanumeric character (e.g. 'example.com', regex used for validation is '[a-z0-9]([-a-z0-9]*[a-z0-9])?(\\\\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*'), metadata.name: Invalid value: \\\"build-deploy-Pipelines Vote Api-2t2rv\\\": a lowercase RFC 1123 subdomain must consist of lower case alphanumeric characters, '-' or '.', and must start and end with an alphanumeric character (e.g. 'example.com', regex used for validation is '[a-z0-9]([-a-z0-9]*[a-z0-9])?(\\\\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*')]\"}","commit":"ebff8e2","eventlistener":"vote-app","namespace":"pipelines-tutorial","/triggers-eventid":"bf54d7e0-aa95-42c4-9e05-d93d903813d0","eventlistenerUID":"1f0e0a79-2756-4482-8097-9197bd28be43","/triggers-eventid":"bf54d7e0-aa95-42c4-9e05-d93d903813d0","/trigger":"vote-trigger"}
    ```

    Solution: Change the repo name to small letter with -
