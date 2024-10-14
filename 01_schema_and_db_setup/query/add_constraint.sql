alter table "client"
add constraint "fk_client_subscribtion" FOREIGN KEY ("id_subscription") REFERENCES subscription ("id") on delete cascade,
alter column "id" set default uuid_generate_v4(),
alter column "name" set not null,
alter column "age" set not null,
add check ("age" > 0);

alter table "trainer"
add constraint "fk_id_origin" FOREIGN KEY ("id_origin") REFERENCES client ("id") on delete cascade,
alter column "price_per_hour" set not null,
alter column "id_origin" set not null,
add check ("price_per_hour" > 0);

alter table "client_trainer"
add constraint "fk_to_client" FOREIGN KEY ("id_client") REFERENCES client ("id") on delete cascade,
add constraint "fk_to_trainer" FOREIGN KEY ("id_trainer") REFERENCES trainer ("id_origin") on delete cascade,
add constraint "fk_to_gym" FOREIGN KEY ("id_gym") REFERENCES gym ("id") on delete cascade,
add constraint "no_self_trainers" check ("id_trainer" != "id_client"),
alter column "date" set not null;

alter table "subscription"
alter column "id" set default uuid_generate_v4(),
alter column "expires_at" set not null;

alter table "gym"
alter column "id" set default uuid_generate_v4(),
alter column "location" set not null;

alter table "equipment"
add constraint "fk_to_gym" FOREIGN KEY ("id_gym") REFERENCES gym ("id") on delete cascade,
alter column "id" set default uuid_generate_v4(),
alter column "name" set not null;