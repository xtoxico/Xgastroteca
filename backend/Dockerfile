FROM golang:1.24-alpine

# Update and install system dependencies
RUN apk update && apk add --no-cache \
    ffmpeg \
    python3 \
    py3-pip \
    git \
    nodejs \
    gcc \
    musl-dev

# Install yt-dlp
RUN pip3 install --no-cache-dir --break-system-packages yt-dlp

WORKDIR /app

# Copy all files
COPY . .

# Tidy up dependencies (generates go.sum inside container)
RUN go mod tidy

# Build the Go app with CGO enabled
RUN CGO_ENABLED=1 go build -o server .

# Expose port 8080
EXPOSE 8080

# Command to run the executable
CMD ["./server"]
