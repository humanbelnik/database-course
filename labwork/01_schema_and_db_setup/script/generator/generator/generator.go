package generator

import (
	"fmt"
	"math/rand"
	"os"

	"github.com/brianvoe/gofakeit/v7"
	_flag "github.com/humanbelnik/db-class/01_init/flag"
)

const (
	IDAmount      = 200000
	TrainerAmount = 20
	GymAmount     = 20
)

type Generator func([]string, int)

func Client(ids []string, amount int) {
	const path = "../../query/insert_client.sql"

	Subscribtions(ids, amount)

	file := getFile(path)
	defer file.Close()

	q := "insert into \"client\" (\"id\", \"name\", \"age\", \"id_subscription\") values\n"
	for i := range amount {
		q += fmt.Sprintf("('%s', '%s', %d, '%s')%s\n", ids[i], gofakeit.Name(), gofakeit.Number(10, 100), ids[i], getLastChar(i, amount))
	}

	fmt.Fprint(file, q)
}

func Subscribtions(ids []string, amount int) {
	const path = "../../query/insert_subscription.sql"

	file := getFile(path)
	defer file.Close()

	q := "insert into \"subscription\" (\"id\", \"expires_at\") values\n"
	for i := range amount {
		q += fmt.Sprintf("('%s', '%s')%s\n", ids[i], getDate(), getLastChar(i, amount))
	}

	fmt.Fprint(file, q)

	Trainer(ids, TrainerAmount)
}

func Trainer(ids []string, amount int) {
	const path = "../../query/insert_trainer.sql"

	file := getFile(path)
	defer file.Close()

	q := "insert into \"trainer\" (\"id_origin\", \"price_per_hour\") values\n"
	for i := range TrainerAmount {
		q += fmt.Sprintf("('%s', %f)%s\n", ids[i], gofakeit.Float32Range(1000, 5000), getLastChar(i, amount))
	}

	fmt.Fprint(file, q)
}

func ClientTrainer(ids []string, amount int) {
	const path = "../../query/insert_client_trainer.sql"

	Gym(ids, amount)

	file := getFile(path)
	defer file.Close()

	q := "insert into \"client_trainer\" (\"id\", \"id_trainer\", \"id_client\", \"id_gym\",\"date\") values\n"
	// for i := range amount {
	// 	q += fmt.Sprintf("('%s','%s','%s','%s','%s')%s\n", ids[i], ids[i%TrainerAmount], ids[(i%TrainerAmount)+200], ids[i%GymAmount], getDate(), getLastChar(i, amount))
	// }

	trainerDistribution := generateTrainerDistribution(TrainerAmount, amount)
	for i := 0; i < amount; i++ {
		clientIndex := i + TrainerAmount
		trainerID := ids[trainerDistribution[i]%20]
		clientID := ids[clientIndex%1000]

		if trainerID == clientID {
			clientID = ids[(clientIndex+1)%1000]
		}

		q += fmt.Sprintf("('%s','%s','%s','%s','%s')%s\n",
			ids[i], trainerID, clientID, ids[i%GymAmount], getDate(), getLastChar(i, amount))
	}

	fmt.Fprint(file, q)
}

func generateTrainerDistribution(trainerCount, amount int) []int {
	weights := []int{40, 30, 20, 15, 10, 5, 3, 2, 1, 1}
	distribution := make([]int, 0, amount)

	for i, weight := range weights {
		for j := 0; j < weight; j++ {
			distribution = append(distribution, i)
		}
	}

	for len(distribution) < amount {
		distribution = append(distribution, rand.Intn(trainerCount))
	}

	rand.Shuffle(len(distribution), func(i, j int) {
		distribution[i], distribution[j] = distribution[j], distribution[i]
	})

	return distribution
}

func Gym(ids []string, amount int) {
	const path = "../../query/insert_gym.sql"

	file := getFile(path)
	defer file.Close()

	q := "insert into \"gym\" (\"id\", \"location\") values\n"
	for i := range GymAmount {
		q += fmt.Sprintf("('%s','%s')%s\n", ids[i], gofakeit.City(), getLastChar(i, GymAmount))
	}

	fmt.Fprint(file, q)
}

func Equipment(ids []string, amount int) {
	const path = "../../query/insert_equipment.sql"

	equipment := []string{
		"threadmill",
		"squat rack",
		"dumbbellls",
		"barbell",
		"cycle",
	}

	file := getFile(path)
	defer file.Close()

	q := "insert into \"equipment\" (\"id\", \"name\", \"id_gym\") values\n"
	for i := range amount {
		q += fmt.Sprintf("('%s','%s','%s')%s\n", ids[i], equipment[i%len(equipment)], ids[i%GymAmount], getLastChar(i, amount))
	}

	fmt.Fprint(file, q)
}

func getLastChar(i int, amount int) string {
	if i == amount-1 {
		return ";"
	}
	return ","
}

func getDate() string {
	return gofakeit.Date().Format("2006-01-02 15:04:05")
}

func getFile(path string) *os.File {
	file, err := os.Create(path)
	if err != nil {
		panic(err)
	}

	return file
}

func IDs() []string {
	ids := make([]string, IDAmount)
	for i := range IDAmount {
		ids[i] = gofakeit.UUID()
	}

	return ids
}

func MapGenerators() map[string]Generator {
	return map[string]Generator{
		_flag.ClFlag:   Client,
		_flag.CltrFlag: ClientTrainer,
		_flag.EqFlag:   Equipment,
	}
}
