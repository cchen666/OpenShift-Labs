# git clone https://github.com/cchen666/openshift-flask/
# podman build .
# podman tag <id> quay.io/cchenlp/helloworld:2.1
# podman push
FROM registry.redhat.io/rhel8/python-38
COPY templates /templates
ADD app.py /
ADD requirements.txt /
RUN pip install -r /requirements.txt
CMD [ "python", "/app.py" ]
