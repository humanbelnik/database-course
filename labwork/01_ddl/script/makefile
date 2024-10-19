all: gen drop create insert

gen:
	python3 main.py -gen

drop:
	python3 main.py -exec=../query/drop_tables.sql

create:
	python3 main.py -exec=../query/create_raw_tables.sql
	python3 main.py -exec=../query/add_constraint.sql

insert:
	python3 main.py -exec=../query/mockdata.sql
