CuidarBem Pro v2

ARQUIVOS
- cuidados-idoso-pro-v2.html  -> aplicação completa com login/cadastro, grupo compartilhado e exportação PDF.
- schema-cuidador-supabase-v2.sql -> estrutura do banco no Supabase.

COMO TESTAR
1. Abra seu projeto no Supabase.
2. Vá em SQL Editor.
3. Rode o arquivo schema-cuidador-supabase-v2.sql.
4. Em Authentication > Providers, deixe o Email habilitado.
5. Se o projeto estiver exigindo confirmação por e-mail, confirme o e-mail antes do login.
6. Abra o arquivo cuidados-idoso-pro-v2.html no navegador.
7. Cadastre o primeiro usuário escolhendo “Criar novo grupo”.
8. Depois, no celular da cuidadora, faça novo cadastro escolhendo “Entrar em grupo existente” e informe o código do grupo.

COMO PUBLICAR
- Netlify: arraste o HTML para um site novo.
- Vercel: crie um projeto estático simples e publique o HTML.
- Também pode testar localmente no computador abrindo o arquivo no navegador.

RECURSOS DESTA VERSÃO
- cadastro de usuário com Supabase Auth
- grupo compartilhado entre familiar e cuidadora
- paciente centralizado
- tarefas
- medicamentos
- registro de doses
- histórico de atividades
- relatório PDF semanal ou mensal
- escolha de classificações para exportar no PDF

OBSERVAÇÕES
- esta versão foi montada para teste rápido em produção simples
- para uso mais robusto, o ideal é evoluir depois para projeto com arquivos separados, revisão de UX e telas extras
