FROM golang:1.12 AS builder
WORKDIR /app
COPY main.go go.mod go.sum ./
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -installsuffix cgo -o app .

FROM alpine:latest

RUN apk update \
	&& apk add ca-certificates tzdata \
	&& update-ca-certificates \
	&& apk add shadow \
	&& groupadd -r app \
	&& useradd -r -g app -s /sbin/nologin -c "Docker image user" app

USER app
WORKDIR /app

COPY --from=builder /app/app ./app
EXPOSE 3000
CMD ["./app"]
