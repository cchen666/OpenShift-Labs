for entry in `crictl ps -o json | jq -c  '.containers[] | {id: .id, name: .metadata.name}'`; do
    name=`echo $entry | jq .name`
    longid=`echo $entry | jq .id`
    id=${longid:1:14}
    for i in $(seq 1 5); do
        crictl stop $id
        sleep 5
        crictl ps | grep $name
        if [ $? -ne 0 ]; then
            echo "Stopped $id"
            break
        fi
    done
    result=`ping 10.74.251.171 -c 10 | grep time=0. | wc -l`
    if [ $result -ne 10 ]; then
        echo "$name ping is slow"
    else
        echo "$name ping is fast"
    fi
done

crictl ps -o json | jq -c  '.containers[] | {id: .id, name: .metadata.name}'

{"id":"83b525d7ca1b8dfacb7560c17665cb937fbd92c1eb572f6d01ec6f01c0ebd5d9","name":"node-ca"}
{"id":"d4fa1c74dc492e525be7f0158e1c79b3363b654609212f454488ad6d4b0eb35f","name":"machine-config-daemon"}
{"id":"e31bce8f932acac9453a18775ff3dcaea8c3afb9ef187b22c003e1ecd9fb0160","name":"sdn"}
{"id":"18a6db41d35013a2617696ca18b42d87e4353ffe550bdcedfb2cd28949836afb","name":"router"}
{"id":"c5cdfda9283030ba13db722cd1eb0fc5c71e1a089ebe3d8d104e2faa5c05cd4f","name":"tuned"}