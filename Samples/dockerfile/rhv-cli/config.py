import multiprocessing

workers = multiprocessing.cpu_count()
debug = True
loglevel = 'debug'
bind = "0.0.0.0:5000"
accesslog = "/var/log/gunicorn/access.log"
errorlog = "/var/log/gunicorn/error.log"
daemon = True