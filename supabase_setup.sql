-- =====================================================================
-- Vortek Concilia — setup do Supabase
-- Rode este script inteiro no SQL Editor do Supabase (Project → SQL Editor)
-- =====================================================================

-- ---------- tabelas ----------
create table if not exists usuarios (
  email text primary key,
  ativo boolean not null default true
);

create table if not exists categorias (
  nome text primary key,
  tipo text default 'ambos',
  ordem int default 99,
  ativo boolean not null default true
);

create table if not exists competencias (
  id text primary key, -- 'YYYY-MM'
  qtd int default 0,
  entradas numeric default 0,
  saidas numeric default 0,
  saldo_inicial numeric,
  saldo_final numeric,
  atualizado_em timestamptz
);

create table if not exists lancamentos (
  id text primary key,
  data date not null,
  competencia text not null,
  historico text,
  documento text,
  valor numeric not null,
  saldo numeric,
  origem text,
  categoria_sugerida text,
  categoria text,
  observacao text,
  anotacao text,
  arquivos jsonb not null default '[]',
  conferido boolean not null default false,
  ordem int,
  importacao_id text,
  criado_em timestamptz,
  criado_por text,
  atualizado_em timestamptz,
  atualizado_por text
);
create index if not exists lancamentos_competencia_idx on lancamentos (competencia);

create table if not exists importacoes (
  id text primary key,
  arquivo text,
  competencia text,
  linhas int,
  novos int,
  repetidos int,
  saldo_inicial numeric,
  saldo_final numeric,
  em timestamptz,
  por text
);

-- ---------- controle de acesso ----------
alter table usuarios enable row level security;
alter table categorias enable row level security;
alter table competencias enable row level security;
alter table lancamentos enable row level security;
alter table importacoes enable row level security;

create or replace function is_authorized() returns boolean
language sql stable as $$
  select exists (
    select 1 from usuarios u
    where lower(u.email) = lower(coalesce(auth.jwt() ->> 'email', ''))
      and coalesce(u.ativo, true) is not false
  );
$$;

drop policy if exists "ler usuarios autenticado" on usuarios;
create policy "ler usuarios autenticado" on usuarios for select
  using (auth.role() = 'authenticated');

drop policy if exists "acesso total autorizado" on categorias;
create policy "acesso total autorizado" on categorias for all
  using (is_authorized()) with check (is_authorized());

drop policy if exists "acesso total autorizado" on competencias;
create policy "acesso total autorizado" on competencias for all
  using (is_authorized()) with check (is_authorized());

drop policy if exists "acesso total autorizado" on lancamentos;
create policy "acesso total autorizado" on lancamentos for all
  using (is_authorized()) with check (is_authorized());

drop policy if exists "acesso total autorizado" on importacoes;
create policy "acesso total autorizado" on importacoes for all
  using (is_authorized()) with check (is_authorized());

-- ---------- realtime (sincronização ao vivo) ----------
alter publication supabase_realtime add table lancamentos, categorias, competencias;

-- ---------- storage (comprovantes) ----------
insert into storage.buckets (id, name, public)
values ('comprovantes', 'comprovantes', false)
on conflict (id) do nothing;

drop policy if exists "comprovantes select autorizado" on storage.objects;
create policy "comprovantes select autorizado" on storage.objects for select
  using (bucket_id = 'comprovantes' and is_authorized());

drop policy if exists "comprovantes insert autorizado" on storage.objects;
create policy "comprovantes insert autorizado" on storage.objects for insert
  with check (bucket_id = 'comprovantes' and is_authorized());

drop policy if exists "comprovantes delete autorizado" on storage.objects;
create policy "comprovantes delete autorizado" on storage.objects for delete
  using (bucket_id = 'comprovantes' and is_authorized());

-- ---------- primeira conta liberada ----------
insert into usuarios (email, ativo) values ('mh7781555@gmail.com', true)
on conflict (email) do update set ativo = true;

-- ---------- categorias padrão ----------
insert into categorias (nome, tipo, ordem, ativo) values
  ('A CLASSIFICAR', 'ambos', 0, true),
  ('APLICACAO', 'ambos', 1, true),
  ('BOLETO PIX', 'ambos', 2, true),
  ('CARTAO SOCIO', 'ambos', 3, true),
  ('CHEQUE', 'ambos', 4, true),
  ('COMBUSTIVEL', 'ambos', 5, true),
  ('DESPESA OPERACIONAL', 'ambos', 6, true),
  ('DESPESA SOCIO', 'ambos', 7, true),
  ('EMPRESTIMO', 'ambos', 8, true),
  ('ESTORNO', 'ambos', 9, true),
  ('FORNECEDOR', 'ambos', 10, true),
  ('HONORARIOS', 'ambos', 11, true),
  ('IMPOSTO', 'ambos', 12, true),
  ('LIQ COBRANCA', 'ambos', 13, true),
  ('MAQUININHA', 'ambos', 14, true),
  ('MARKETING', 'ambos', 15, true),
  ('PAGAMENTO PF', 'ambos', 16, true),
  ('PEDAGIO', 'ambos', 17, true),
  ('RECIBIMENTO CLIENTE', 'ambos', 18, true),
  ('SAQUE', 'ambos', 19, true),
  ('SOCIO', 'ambos', 20, true),
  ('TARIFA BANCO', 'ambos', 21, true),
  ('TRANSF ENTRE CONTAS SICREDI', 'ambos', 22, true),
  ('VEICULO', 'ambos', 23, true),
  ('VENDEDOR', 'ambos', 24, true)
on conflict (nome) do nothing;

-- =====================================================================
-- PRÓXIMO PASSO (fora do SQL Editor):
-- Vá em Authentication → Users → "Add user", crie a conta com o e-mail
-- mh7781555@gmail.com e uma senha, e marque "Auto Confirm User" para não
-- depender de e-mail de confirmação. Repita para cada pessoa que precisar
-- de acesso, sempre adicionando o e-mail também na tabela `usuarios`
-- (pode ser pela aba Table Editor, sem precisar de SQL).
-- =====================================================================
