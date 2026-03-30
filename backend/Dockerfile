# Use the official Golang image to create a build artifact.
FROM golang:1.25-alpine as builder

# Create and change to the app directory.
WORKDIR /app

# Retrieve application dependencies.
COPY go.mod go.sum ./
RUN go mod download

# Copy local code to the container image.
COPY . ./

# Build the binary.
RUN go build -v -o server

# Use a Docker multi-stage build to create a lean production image.
FROM alpine:latest
RUN apk add --no-cache ca-certificates

# Copy the binary to the production image from the builder stage.
COPY --from=builder /app/server /server

# Run the web service on container startup.
CMD ["/server"]
