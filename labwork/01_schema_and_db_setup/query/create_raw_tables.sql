-- Tables without constraints and references. (Except PKs) 
--
-- 1-1: client-subscription
-- 1-M: gym-equipment
-- M-N: client-trainer

create extension if not exists "uuid-ossp";

create table if not exists "client" (
    "id" UUID primary key,
    "name" text,
    "age" smallint,
    "id_subscription" UUID
);

create table if not exists "trainer" (
    "id_origin" UUID primary key,
    "price_per_hour" numeric(10,2)
);

create table if not exists "client_trainer" (
    "id" UUID primary key,
    "id_trainer" UUID,
    "id_client" UUID,
    "id_gym" UUID,
    "date" timestamp
);

create table if not exists "subscription" (
    "id" UUID primary key,
    "expires_at" timestamp
);

create table if not exists "gym" (
    "id" UUID primary key,
    "location" text
);

create table if not exists "equipment" (
    "id" UUID primary key,
    "name" text,
    "id_gym" UUID
);
