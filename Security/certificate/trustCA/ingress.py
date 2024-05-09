# Recommend to create python venv 3.10 first and install trustme package
import trustme
import datetime

# Create a CA

ca = trustme.CA()

# CA issues the certificate
expires=datetime.datetime(2035, 12, 1, 8, 10, 10)

server_cert = ca.issue_cert(u"*.apps.gcg-shift.cchen.work", not_after=expires)

# Save the CA cert

ca.cert_pem.write_to_path("ca.crt")

# Save server, client cert and key

server_cert.private_key_pem.write_to_path("server.key")
server_cert.cert_chain_pems[0].write_to_path("server.crt")