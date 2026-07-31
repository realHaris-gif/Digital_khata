-- Enable UUID extension
create extension if not exists "uuid-ossp";

create table if not exists public.profiles (
  id uuid references auth.users on delete cascade not null primary key,
  email text unique,
  username text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.profiles enable row level security;

create policy "Public profiles are viewable by everyone."
  on profiles for select
  using ( true );

create policy "Users can insert their own profile."
  on profiles for insert
  with check ( auth.uid() = id );

create policy "Users can update own profile."
  on profiles for update
  using ( auth.uid() = id );

create table if not exists public.customers (
  id uuid primary key default uuid_generate_v4(),
  name text not null,
  phone text not null,
  unique_id text unique not null,
  created_by uuid references auth.users not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.customers enable row level security;

create policy "Users can view own customers."
  on customers for select
  using ( auth.uid() = created_by );

create policy "Users can insert own customers."
  on customers for insert
  with check ( auth.uid() = created_by );

create policy "Users can update own customers."
  on customers for update
  using ( auth.uid() = created_by );

create policy "Users can delete own customers."
  on customers for delete
  using ( auth.uid() = created_by );

create table if not exists public.transactions (
  id uuid primary key default uuid_generate_v4(),
  customer_id uuid references public.customers(id) on delete cascade not null,
  type text not null check (type in ('GIVEN', 'RECEIVED')),
  item text,
  amount numeric not null,
  description text,
  time timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.transactions enable row level security;

create policy "Users can view transactions for their customers."
  on transactions for select
  using (
    exists (
      select 1 from public.customers
      where customers.id = transactions.customer_id
        and customers.created_by = auth.uid()
    )
  );

create policy "Users can insert transactions for their customers."
  on transactions for insert
  with check (
    exists (
      select 1 from public.customers
      where customers.id = transactions.customer_id
        and customers.created_by = auth.uid()
    )
  );

create policy "Users can update transactions for their customers."
  on transactions for update
  using (
    exists (
      select 1 from public.customers
      where customers.id = transactions.customer_id
        and customers.created_by = auth.uid()
    )
  );

create policy "Users can delete transactions for their customers."
  on transactions for delete
  using (
    exists (
      select 1 from public.customers
      where customers.id = transactions.customer_id
        and customers.created_by = auth.uid()
    )
  );
