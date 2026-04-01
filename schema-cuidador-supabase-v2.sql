create extension if not exists pgcrypto;

-- =========================
-- Tabelas principais
-- =========================
create table if not exists public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null,
  email text,
  role text default 'other',
  created_at timestamptz not null default now()
);

create table if not exists public.care_groups (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  invite_code text not null unique,
  owner_user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table if not exists public.care_group_members (
  id uuid primary key default gen_random_uuid(),
  care_group_id uuid not null references public.care_groups(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text default 'other',
  created_at timestamptz not null default now(),
  unique (care_group_id, user_id)
);

create table if not exists public.patients (
  id uuid primary key default gen_random_uuid(),
  care_group_id uuid not null references public.care_groups(id) on delete cascade,
  full_name text not null,
  age integer,
  weight numeric(10,2),
  conditions text,
  primary_caregiver text,
  updated_by uuid references auth.users(id),
  created_at timestamptz not null default now()
);

create table if not exists public.tasks (
  id uuid primary key default gen_random_uuid(),
  care_group_id uuid not null references public.care_groups(id) on delete cascade,
  patient_id uuid not null references public.patients(id) on delete cascade,
  description text not null,
  task_time text,
  category text,
  priority text default 'normal',
  responsible text,
  notes text,
  is_done boolean not null default false,
  created_by uuid references auth.users(id),
  updated_by uuid references auth.users(id),
  created_at timestamptz not null default now()
);

create table if not exists public.medications (
  id uuid primary key default gen_random_uuid(),
  care_group_id uuid not null references public.care_groups(id) on delete cascade,
  patient_id uuid not null references public.patients(id) on delete cascade,
  name text not null,
  dosage text,
  route text,
  condition_label text,
  schedule_times text[] not null default '{}',
  notes text,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now()
);

create table if not exists public.dose_logs (
  id uuid primary key default gen_random_uuid(),
  care_group_id uuid not null references public.care_groups(id) on delete cascade,
  patient_id uuid not null references public.patients(id) on delete cascade,
  medication_id uuid references public.medications(id) on delete cascade,
  medication_name text,
  scheduled_time text,
  administered_at timestamptz not null default now(),
  recorded_by uuid references auth.users(id)
);

create table if not exists public.activity_logs (
  id uuid primary key default gen_random_uuid(),
  care_group_id uuid not null references public.care_groups(id) on delete cascade,
  patient_id uuid not null references public.patients(id) on delete cascade,
  log_type text not null,
  message text not null,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now()
);

create index if not exists idx_care_group_members_user on public.care_group_members(user_id);
create index if not exists idx_patients_group on public.patients(care_group_id);
create index if not exists idx_tasks_group_patient on public.tasks(care_group_id, patient_id);
create index if not exists idx_medications_group_patient on public.medications(care_group_id, patient_id);
create index if not exists idx_dose_logs_group_patient on public.dose_logs(care_group_id, patient_id);
create index if not exists idx_activity_logs_group_patient on public.activity_logs(care_group_id, patient_id);

-- =========================
-- Função auxiliar de acesso
-- =========================
create or replace function public.user_belongs_to_group(group_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.care_group_members m
    where m.care_group_id = group_id
      and m.user_id = auth.uid()
  )
  or exists (
    select 1
    from public.care_groups g
    where g.id = group_id
      and g.owner_user_id = auth.uid()
  );
$$;

-- =========================
-- RLS
-- =========================
alter table public.profiles enable row level security;
alter table public.care_groups enable row level security;
alter table public.care_group_members enable row level security;
alter table public.patients enable row level security;
alter table public.tasks enable row level security;
alter table public.medications enable row level security;
alter table public.dose_logs enable row level security;
alter table public.activity_logs enable row level security;


-- remove políticas anteriores para permitir reexecução segura
 drop policy if exists "profiles_select_own" on public.profiles;
 drop policy if exists "profiles_insert_own" on public.profiles;
 drop policy if exists "profiles_update_own" on public.profiles;
 drop policy if exists "care_groups_select_authenticated" on public.care_groups;
 drop policy if exists "care_groups_insert_owner" on public.care_groups;
 drop policy if exists "care_groups_update_owner_or_member" on public.care_groups;
 drop policy if exists "members_select_own_or_group" on public.care_group_members;
 drop policy if exists "members_insert_self" on public.care_group_members;
 drop policy if exists "members_update_own" on public.care_group_members;
 drop policy if exists "patients_access_by_group" on public.patients;
 drop policy if exists "tasks_access_by_group" on public.tasks;
 drop policy if exists "medications_access_by_group" on public.medications;
 drop policy if exists "dose_logs_access_by_group" on public.dose_logs;
 drop policy if exists "activity_logs_access_by_group" on public.activity_logs;

-- profiles
create policy "profiles_select_own" on public.profiles
for select to authenticated
using (user_id = auth.uid());

create policy "profiles_insert_own" on public.profiles
for insert to authenticated
with check (user_id = auth.uid());

create policy "profiles_update_own" on public.profiles
for update to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

-- care_groups
create policy "care_groups_select_authenticated" on public.care_groups
for select to authenticated
using (true);

create policy "care_groups_insert_owner" on public.care_groups
for insert to authenticated
with check (owner_user_id = auth.uid());

create policy "care_groups_update_owner_or_member" on public.care_groups
for update to authenticated
using (public.user_belongs_to_group(id))
with check (public.user_belongs_to_group(id));

-- care_group_members
create policy "members_select_own_or_group" on public.care_group_members
for select to authenticated
using (user_id = auth.uid() or public.user_belongs_to_group(care_group_id));

create policy "members_insert_self" on public.care_group_members
for insert to authenticated
with check (user_id = auth.uid());

create policy "members_update_own" on public.care_group_members
for update to authenticated
using (user_id = auth.uid() or public.user_belongs_to_group(care_group_id))
with check (user_id = auth.uid() or public.user_belongs_to_group(care_group_id));

-- patients
create policy "patients_access_by_group" on public.patients
for all to authenticated
using (public.user_belongs_to_group(care_group_id))
with check (public.user_belongs_to_group(care_group_id));

-- tasks
create policy "tasks_access_by_group" on public.tasks
for all to authenticated
using (public.user_belongs_to_group(care_group_id))
with check (public.user_belongs_to_group(care_group_id));

-- medications
create policy "medications_access_by_group" on public.medications
for all to authenticated
using (public.user_belongs_to_group(care_group_id))
with check (public.user_belongs_to_group(care_group_id));

-- dose_logs
create policy "dose_logs_access_by_group" on public.dose_logs
for all to authenticated
using (public.user_belongs_to_group(care_group_id))
with check (public.user_belongs_to_group(care_group_id));

-- activity_logs
create policy "activity_logs_access_by_group" on public.activity_logs
for all to authenticated
using (public.user_belongs_to_group(care_group_id))
with check (public.user_belongs_to_group(care_group_id));
