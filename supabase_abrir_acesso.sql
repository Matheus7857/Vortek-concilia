-- =====================================================================
-- Vortek Concilia — remove a exigência de login
-- Rode este script no SQL Editor do Supabase (projeto excbvlodvhrzyfzmnxez)
-- ATENÇÃO: depois disso, qualquer pessoa com a URL do Supabase e a chave
-- publishable (ambas já ficam visíveis no código do index.html) consegue
-- ler e escrever em todos os lançamentos, categorias e comprovantes, sem
-- senha nenhuma. Não tem volta fácil depois que alguém acessar os dados.
-- =====================================================================

drop policy if exists "acesso total autorizado" on categorias;
create policy "acesso total aberto" on categorias for all using (true) with check (true);

drop policy if exists "acesso total autorizado" on competencias;
create policy "acesso total aberto" on competencias for all using (true) with check (true);

drop policy if exists "acesso total autorizado" on lancamentos;
create policy "acesso total aberto" on lancamentos for all using (true) with check (true);

drop policy if exists "acesso total autorizado" on importacoes;
create policy "acesso total aberto" on importacoes for all using (true) with check (true);

drop policy if exists "comprovantes select autorizado" on storage.objects;
create policy "comprovantes select aberto" on storage.objects for select
  using (bucket_id = 'comprovantes');

drop policy if exists "comprovantes insert autorizado" on storage.objects;
create policy "comprovantes insert aberto" on storage.objects for insert
  with check (bucket_id = 'comprovantes');

drop policy if exists "comprovantes delete autorizado" on storage.objects;
create policy "comprovantes delete aberto" on storage.objects for delete
  using (bucket_id = 'comprovantes');

-- a tabela `usuarios` e sua policy de leitura não são mais usadas pelo
-- app, mas não precisam ser apagadas — ficam só sem uso.
