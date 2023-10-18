import os
from flask import Flask, request, redirect, url_for, session
from flask_oauthlib.client import OAuth

app = Flask(__name__)
app.secret_key = os.urandom(24)

# Replace these with your OpenShift OAuth settings
OAUTH_CLIENT_ID = 'reverse-words'
OAUTH_CLIENT_SECRET = 'aaa'
OAUTH_AUTHORIZE_URL = 'https://oauth-openshift.apps.gcg-shift.cchen.work/oauth/authorize'
OAUTH_TOKEN_URL = 'https://oauth-openshift.apps.gcg-shift.cchen.work/oauth/token'
OAUTH_REDIRECT_URI = 'http://oauthclient-app-reverse-words.apps.gcg-shift.cchen.work/callback'

oauth = OAuth(app).remote_app(
    'openshift',
    consumer_key=OAUTH_CLIENT_ID,
    consumer_secret=OAUTH_CLIENT_SECRET,
    request_token_params={'scope': 'user:info'},
    base_url='https://oauth-openshift.apps.gcg-shift.cchen.work/oauth/',
    request_token_url=None,
    access_token_method='POST',
    access_token_url=OAUTH_TOKEN_URL,
    authorize_url=OAUTH_AUTHORIZE_URL,
)

@app.route('/')
def index():
    if 'openshift_token' in session:
        return 'You are logged in! <a href="/logout">Logout</a>'
    else:
        return '<a href="/login">Login to OpenShift</a>'

@app.route('/login')
def login():
    return oauth.authorize(callback=url_for('authorized', _external=True))

@app.route('/logout')
def logout():
    session.pop('openshift_token', None)
    return redirect('/')

@app.route('/callback')
def authorized():
    resp = oauth.authorized_response()
    if resp is None or resp.get('access_token') is None:
        return 'Access denied: reason={} error={}'.format(
            request.args['error_reason'],
            request.args['error_description']
        )

    session['openshift_token'] = (resp['access_token'], '')
    user_info = oauth.get('user').data

    # You can now use user_info to retrieve user information and perform user-specific actions
    return 'Logged in as: {}'.format(user_info['preferred_username'])

@oauth.tokengetter
def get_oauth_token():
    return session.get('openshift_token')

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)