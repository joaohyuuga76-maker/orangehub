create extension if not exists pgcrypto;
create table if not exists public.profiles (id uuid primary key references auth.users(id) on delete cascade, display_name text not null);
create table if not exists public.tasks (id uuid primary key default gen_random_uuid(),title text not null,assigned_to uuid references public.profiles(id),recurrence text not null default 'none' check(recurrence in ('none','daily','weekly')),created_by uuid not null references public.profiles(id),created_at timestamptz not null default now());
create table if not exists public.task_completions (task_id uuid not null references public.tasks(id) on delete cascade,occurrence_date text not null,completed_by uuid not null references public.profiles(id),completed_at timestamptz not null default now(),primary key(task_id,occurrence_date));
create table if not exists public.sales (id uuid primary key default gen_random_uuid(),amount numeric(12,2) not null check(amount>=0),cost numeric(12,2) not null check(cost>=0),fees numeric(12,2) not null check(fees>=0),sold_at timestamptz not null default now(),created_by uuid not null references public.profiles(id));
create or replace function public.is_team_member() returns boolean language sql stable security definer set search_path='' as $$ select exists(select 1 from public.profiles p where p.id=(select auth.uid())); $$;
revoke all on function public.is_team_member() from public;
grant execute on function public.is_team_member() to authenticated;
alter table public.profiles enable row level security;alter table public.tasks enable row level security;alter table public.task_completions enable row level security;alter table public.sales enable row level security;
create policy "team read profiles" on public.profiles for select to authenticated using(public.is_team_member());
create policy "team read tasks" on public.tasks for select to authenticated using(public.is_team_member());
create policy "team add tasks" on public.tasks for insert to authenticated with check(public.is_team_member() and created_by=(select auth.uid()));
create policy "team read completions" on public.task_completions for select to authenticated using(public.is_team_member());
create policy "team add completions" on public.task_completions for insert to authenticated with check(public.is_team_member() and completed_by=(select auth.uid()));
create policy "team delete completions" on public.task_completions for delete to authenticated using(public.is_team_member());
create policy "team read sales" on public.sales for select to authenticated using(public.is_team_member());
create policy "team add sales" on public.sales for insert to authenticated with check(public.is_team_member() and created_by=(select auth.uid()));
-- Cadastre dois usuários em Supabase Auth e insira seus UUIDs em profiles manualmente.
