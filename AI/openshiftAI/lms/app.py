from flask import Flask, request
import pickle

app = Flask(__name__)
# Load model
with open('mymodel.pkl', 'rb') as f:
    model = pickle.load(f)

model_name = "Time to purchase amount predictor"
model_file = 'model.plk'
version = "v1.0.0"


@app.route('/info', methods=['GET'])
def info():
    """Return model information, version how to call"""
    result = {}

    result["name"] = model_name
    result["version"] = version

    return result


@app.route('/health', methods=['GET'])
def health():
    """REturn service health"""
    return 'ok'


@app.route('/predict', methods=['POST'])
def predict():
    feature_dict = request.get_json()
    if not feature_dict:
        return {
            'error': 'Body is empty.'
        }, 500

    try:
        return {
            'status': 200,
            'prediction': int(model(feature_dict['time']))
        }
    except ValueError as e:
        return {'error': str(e).split('\n')[-1].strip()}, 500


if __name__ == '__main__':
    app.run(host='0.0.0.0')
