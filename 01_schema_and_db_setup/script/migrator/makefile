

all: create-tables add-constraint insert-sub insert-client insert-trainer insert-gym insert-eq insert-cltr

create-tables:
	go run main.go -path=../../query/create_raw_tables.sql

add-constraint:
	go run main.go -path=../../query/add_constraint.sql

insert-sub:
	go run main.go -path=../../query/insert_subscription.sql

insert-gym:
	go run main.go -path=../../query/insert_gym.sql

insert-client:
	go run main.go -path=../../query/insert_client.sql

insert-trainer:
	go run main.go -path=../../query/insert_trainer.sql

insert-eq:
	go run main.go -path=../../query/insert_equipment.sql

insert-cltr:
	go run main.go -path=../../query/insert_client_trainer.sql

