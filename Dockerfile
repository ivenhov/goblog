
############################
# STEP 1 build executable binary
############################
# FROM golang:latest as builder
FROM golang:1.13-stretch as builder

# Install git.
# Git is required for fetching the dependencies.
#RUN apk update && apk add --no-cache git

COPY accountservice ./src/github.com/callistaenterprise/goblog/accountservice
COPY healthchecker ./src/github.com/callistaenterprise/goblog/healthchecker

WORKDIR /go/src/github.com/callistaenterprise/goblog/healthchecker
RUN go get -d -v
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags="-w -s" -o /go/bin/healthchecker-linux-amd64


WORKDIR /go/src/github.com/callistaenterprise/goblog/accountservice
# Fetch dependencies. Using go get.
RUN go get -d -v
# Build the binary.
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags="-w -s" -o /go/bin/accountservice-linux-amd64


############################
# STEP 2 build a small image
############################
FROM scratch
# FROM alpine

EXPOSE 6767

# Copy our static executable.
COPY --from=builder /go/bin/accountservice-linux-amd64 / 
COPY --from=builder /go/bin/healthchecker-linux-amd64 / 

HEALTHCHECK --interval=3s --timeout=3s CMD ["./healthchecker-linux-amd64", "-port=6767"] || exit 1

# Run the hello binary.
ENTRYPOINT ["/accountservice-linux-amd64"]


