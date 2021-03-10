import trustme

# Create a CA

ca = trustme.CA()

# CA issues the certificate

server_cert = ca.issue_cert(u"localhost")
client_cert = ca.issue_cert(u"client-a")

# Save the CA cert

ca.cert_pem.write_to_path("ca.crt")

# Save server, client cert and key

server_cert.private_key_pem.write_to_path("server.key")
server_cert.cert_chain_pems[0].write_to_path("server.crt")
client_cert.private_key_pem.write_to_path("client.key")
client_cert.cert_chain_pems[0].write_to_path("client.crt")