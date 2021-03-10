from flask import Flask, jsonify, request
import commands
from os import environ

app = Flask(__name__)

# curl 10.72.37.235:5000/vm/cchen/detail
@app.route('/vm/<string:name>/detail')
def vm_list(name):
    result = commands.getoutput("titamu list -p " + name) + '\n'
    return result

@app.route('/vm/<string:name>/stop', methods=['POST'])
def vm_stop(name):
    result = commands.getoutput("titamu stop " + name) + '\n'
    return result

@app.route('/vm/<string:name>/start', methods=['POST'])
def vm_start(name):
    result = commands.getoutput("titamu start " + name) + '\n'
    return result

@app.route('/vm/<string:name>/show')
def vm_show(name):
    result = commands.getoutput("titamu show " + name)+'\n'
    return result

@app.route('/vm/<string:name>/delete', methods=['DELETE'])
def vm_delete(name):
    result = commands.getoutput("titamu delete " + name)+'\n'
    return result

@app.route('/vm/<string:name>/console')
def vm_console(name):
    result = commands.getoutput("titamu get-console " + name)+'\n'
    return result

# curl -H "Content-Type: application/json" -X POST -d
# '{"name":"cchen-ttt","comment": "test flask"}' 10.72.37.235:5000/vm
@app.route('/vm/boot', methods=['POST'])
def vm_boot():
    request_data = request.get_json()
    try:
        if request_data['comment'] is not None:
            vm_comment = request_data['comment']
    except KeyError:
        vm_comment = " "
    try:
        if request_data['dc'] is not None:
            vm_dc = request_data['dc']
    except KeyError:
        vm_dc = "TestEnvCluster"
    try:
        if request_data['template'] is not None:
            vm_template = request_data['template']
    except KeyError:
        vm_template = environ.get("TITAMU_DEFAULT_TEMPLATE")
    command = "titamu boot" + " -c " + "\'" + vm_comment + "\'" + " -d " + vm_dc + " -t " + vm_template + " " + request_data['name']
    result = commands.getoutput(command) + '\n'
    return result

app.run(port=5000, host='0.0.0.0', debug=False)
#app.run(debug=True)