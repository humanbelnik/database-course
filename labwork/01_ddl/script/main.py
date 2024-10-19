from faker import Faker
import uuid
import random
import psycopg2
import argparse
from datetime import datetime, timedelta

NUM_CLIENTS = 1000
NUM_TRAINERS = 20
NUM_GYMS = 10
NUM_SUBSCRIPTIONS = 1000
NUM_EQUIPMENT = 500
NUM_WORKOUTS = 10000

fake = Faker()

def generate_data():
    clients = []
    trainers = []
    gyms = []
    subscriptions = []
    equipment = []
    workouts = []

    for _ in range(NUM_SUBSCRIPTIONS):
        sub_id = str(uuid.uuid4())
        expires_at = datetime.now() + timedelta(days=random.randint(30, 365))
        subscriptions.append(f"INSERT INTO subscription (id, expires_at) VALUES ('{sub_id}', '{expires_at}');")
    
    for _ in range(NUM_CLIENTS):
        client_id = str(uuid.uuid4())
        name = fake.name()
        age = random.randint(18, 60)
        id_subscription = random.choice([sub.split("'")[1] for sub in subscriptions])
        clients.append(f"INSERT INTO client (id, name, age, id_subscription) VALUES ('{client_id}', '{name}', {age}, '{id_subscription}');")

    for _ in range(NUM_TRAINERS):
        trainer_id = random.choice([c.split("'")[1] for c in clients])
        price_per_hour = round(random.uniform(20, 100), 2)
        level = random.randint(1, 5)
        trainers.append(f"INSERT INTO trainer (id_origin, price_per_hour, level) VALUES ('{trainer_id}', {price_per_hour}, {level});")

    for _ in range(NUM_GYMS):
        gym_id = str(uuid.uuid4())
        location = fake.city()  
        is_mma_zone = random.choice([True, False])
        is_crossfit_zone = random.choice([True, False])
        gyms.append(f"INSERT INTO gym (id, location, is_mma_zone, is_crossfit_zone) VALUES ('{gym_id}', '{location}', {is_mma_zone}, {is_crossfit_zone});")

    equipment_types = ["Treadmill", "Bench Press", "Dumbbells", "Barbell", "Kettlebell", "Rowing Machine", "Stationary Bike", "Leg Press", "Smith Machine", "Pull-up Bar"]
    for _ in range(NUM_EQUIPMENT):
        equip_id = str(uuid.uuid4())
        name = random.choice(equipment_types)  
        id_gym = random.choice([g.split("'")[1] for g in gyms])
        equipment.append(f"INSERT INTO equipment (id, name, id_gym) VALUES ('{equip_id}', '{name}', '{id_gym}');")

    for _ in range(NUM_WORKOUTS):
        workout_id = str(uuid.uuid4())
        id_trainer = random.choice([t.split("'")[1] for t in trainers])
        id_client = random.choice([c.split("'")[1] for c in clients if c.split("'")[1] != id_trainer])  
        id_gym = random.choice([g.split("'")[1] for g in gyms])
        date = datetime.now() - timedelta(days=random.randint(0, 100))
        workouts.append(f"INSERT INTO workout (id, id_trainer, id_client, id_gym, date) VALUES ('{workout_id}', '{id_trainer}', '{id_client}', '{id_gym}', '{date}');")

    with open("../query/mockdata.sql", "w") as f:
        f.write("\n".join(subscriptions) + "\n")
        f.write("\n".join(clients) + "\n")
        f.write("\n".join(trainers) + "\n")
        f.write("\n".join(gyms) + "\n")
        f.write("\n".join(equipment) + "\n")
        f.write("\n".join(workouts) + "\n")

def execute_sql_file(filename):
    try:
        conn = psycopg2.connect(
            dbname="postgres",
            user="admin",
            password="admin",
            host="localhost"
        )
        cursor = conn.cursor()

        with open(filename, 'r') as file:
            sql = file.read()
            cursor.execute(sql)
            conn.commit()

        cursor.close()
        conn.close()
        print(f"Successfully executed {filename}")
    except Exception as e:
        print(f"Error executing {filename}: {e}")

def main():
    parser = argparse.ArgumentParser(description="Generate or execute SQL data")
    parser.add_argument("-gen", action="store_true", help="Generate SQL file with test data")
    parser.add_argument("-exec", type=str, help="Execute SQL file")

    args = parser.parse_args()

    if args.gen:
        generate_data()
        print("SQL file generated: generated_data.sql")

    if args.exec:
        execute_sql_file(args.exec)

if __name__ == "__main__":
    main()
