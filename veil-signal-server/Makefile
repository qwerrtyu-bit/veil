.PHONY: build run clean docker-build docker-run

build:
	go build -o veil-server ./main.go

run:
	go run ./main.go

clean:
	rm -f veil-server
	rm -rf data/*.db data/*.db-journal data/*.db-wal

docker-build:
	docker-compose build

docker-run:
	docker-compose up -d

docker-stop:
	docker-compose down

docker-logs:
	docker-compose logs -f

test:
	go test -v ./...

mod-tidy:
	go mod tidy