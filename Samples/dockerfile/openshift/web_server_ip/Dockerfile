# Use the Red Hat UBI with Golang to build the application
FROM registry.access.redhat.com/ubi8/go-toolset:1.21.9-3.1719304739 as builder

# Set the working directory
WORKDIR /app

# Copy the source code
COPY . .

# Build the Go application
RUN go mod init pod-ip-printer && go mod tidy
RUN go build -o pod-ip-printer

# Use a minimal Red Hat UBI image to run the application
FROM registry.access.redhat.com/ubi8/ubi-minimal:8.6

# Copy the binary from the builder image
COPY --from=builder /app/pod-ip-printer /usr/local/bin/pod-ip-printer

# Expose the port the application runs on
EXPOSE 8080

# Run the application
CMD ["/usr/local/bin/pod-ip-printer"]
