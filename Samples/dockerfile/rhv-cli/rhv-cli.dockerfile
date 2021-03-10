FROM python:2.7
ADD api.py .
ADD config.py .
RUN pip install titamu gunicorn flask --no-cache-dir
ENV TITAMU_URL='https://lab-rhevm.gsslab.pek2.redhat.com/ovirt-engine/api'
ENV TITAMU_USERNAME='XXXXXX@XXXXXX'
ENV TITAMU_PASSWORD='XXXXXX'
ENV TITAMU_VM_PREFIX='cchen'
ENV TITAMU_DEFAULT_TEMPLATE='cchen7u6'
EXPOSE 5000
CMD ["python", "api.py"]