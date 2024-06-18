from http.server import BaseHTTPRequestHandler, HTTPServer

class SimpleHTTPRequestHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        client_ip = self.client_address[0]
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b'Client IP: ' + client_ip.encode())
        print(f"Received request from: {client_ip}")

httpd = HTTPServer(('0.0.0.0', 30888), SimpleHTTPRequestHandler)
print("Starting server on port 30888")
httpd.serve_forever()
