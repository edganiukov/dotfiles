.PHONY: all install test clean

all: pimux

pimux: $(wildcard *.go) go.mod
	CGO_ENABLED=0 go build -trimpath -o $@ .

install:
	CGO_ENABLED=0 go install -trimpath .

test: pimux
	go test ./...
	PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s tests -v

clean:
	rm -f pimux
