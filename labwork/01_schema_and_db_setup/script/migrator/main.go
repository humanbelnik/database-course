package main

import (
	"context"
	"database/sql"
	"flag"
	"os"
	"time"

	_ "github.com/lib/pq"
)

func main() {
	const connStr = "host=localhost user=admin password=admin dbname=postgres port=5432 sslmode=disable"

	db, err := sql.Open("postgres", connStr)
	if err != nil {
		panic(err)
	}
	defer db.Close()

	qpath := flag.String("path", "", "Path to the SQL query file")
	flag.Parse()

	qByte, err := os.ReadFile(*qpath)
	if err != nil {
		panic(err)
	}

	q := string(qByte)
	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer cancel()

	_, err = db.ExecContext(ctx, q)
	if err != nil {
		panic(err)
	}

}
