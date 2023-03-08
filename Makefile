start-acedb:
	xhost +local:root
	docker-compose up -d --build acedb

start-curation:
	xhost +local:root
	docker-compose up -d --build curation