# Planejamento: Autenticação

## Contexto

O aplicativo será usado por três públicos:
- **Técnicos Cell Owner** — funcionários da Claro, nomes presentes na coluna `tecnico` da tabela `sites`
- **Técnicos STTE** — empresa parceira, também técnicos de campo
- **Visualizadores (Geral)** — outras pessoas da Claro com acesso somente leitura

---

## Regras de Negócio

- Cadastro **manual pelo admin (Rafael)** no Supabase Dashboard — usuários não se auto-cadastram pelo app
- Após cadastro, o Supabase envia um **e-mail automático** para o usuário redefinir a senha antes do primeiro acesso
- Somente e-mails dos domínios **@claro.com.br** e **@stte.com.br** são autorizados
- O login é feito com **número de login** (fornecido pelo técnico, cadastrado pelo admin) + **senha** definida pelo usuário via e-mail
- Toda ação de edição deve registrar **quem fez e quando** (auditoria)

---

## Perfis de Usuário

| Perfil | Visualiza sites | Visualiza fotos | Insere foto | Atualiza foto | Exclui foto | Campos futuros |
|--------|:-:|:-:|:-:|:-:|:-:|:-:|
| `cell_owner` | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| `geral` | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |

> `cell_owner` cobre tanto técnicos Claro quanto STTE com permissão de edição.
> `geral` é somente leitura — visualiza tudo mas não modifica nada.

---

## Fluxo de Autenticação

```
Admin cadastra usuário no Supabase Dashboard
    ↓
Supabase envia e-mail com link para redefinir senha
    ↓
Usuário define sua senha pelo link recebido
    ↓
Usuário abre o app → LoginScreen
    ├── Informa: número de login + senha
    └── App valida domínio do e-mail (@claro.com.br | @stte.com.br)
         ↓
    Supabase Auth valida credenciais
         ├── Sucesso → carrega perfil → redireciona para HomeScreen
         └── Falha  → exibe mensagem de erro inline
              ↓
    Sessão persistida automaticamente (supabase_flutter)
    Próxima abertura do app → vai direto para HomeScreen se sessão válida
```

---

## Arquitetura

```
LoginScreen
    ↓
AuthProvider (ChangeNotifier)
    ├── signIn(login, senha)
    ├── signOut()
    ├── session: Session?
    ├── isLoggedIn: bool
    └── profile: UserProfile?
    ↓
main.dart — verifica currentSession ao iniciar
    ├── Session válida → HomeScreen
    └── Sem session  → LoginScreen
```

### Tabela `profiles` no Supabase

```sql
create table profiles (
  id         uuid primary key references auth.users(id) on delete cascade,
  login      text not null unique,
  nome       text not null,
  email      text not null,
  role       text not null default 'geral', -- 'cell_owner' | 'geral'
  created_at timestamptz default now()
);
```

### Tabela `audit_log` — Registro de Edições

```sql
create table audit_log (
  id         bigserial primary key,
  user_id    uuid references auth.users(id),
  site_id    text references sites(site_id),
  action     text not null,  -- 'foto_add' | 'foto_update' | 'foto_delete'
  detail     text,
  created_at timestamptz default now()
);
```

### RLS — Políticas de Segurança

```sql
-- Remover policy anon de UPDATE (temporária)
drop policy if exists "Allow anon update" on sites;

-- Sites: apenas autenticados leem
create policy "Autenticados leem sites"
on sites for select to authenticated using (true);

-- Sites: apenas cell_owner atualiza
create policy "cell_owner atualiza sites"
on sites for update to authenticated
using (
  exists (
    select 1 from profiles
    where profiles.id = auth.uid()
    and profiles.role = 'cell_owner'
  )
);

-- Profiles: cada usuário lê apenas o próprio
alter table profiles enable row level security;

create policy "Usuário lê próprio profile"
on profiles for select using (auth.uid() = id);

-- Audit log
alter table audit_log enable row level security;

create policy "cell_owner insere audit"
on audit_log for insert to authenticated
with check (auth.uid() = user_id);

create policy "Autenticados leem audit"
on audit_log for select to authenticated using (true);
```

---

## Modelo `UserProfile`

```dart
class UserProfile {
  final String id;
  final String login;
  final String nome;
  final String email;
  final String role; // 'cell_owner' | 'geral'

  bool get isCellOwner => role == 'cell_owner';
}
```

---

## Arquivos a Criar/Modificar

| Arquivo | Mudança |
|---------|---------|
| `lib/models/user_profile.dart` | **Criar** — modelo do perfil |
| `lib/providers/auth_provider.dart` | **Criar** — session, login, logout, perfil |
| `lib/screens/login_screen.dart` | **Criar** — login com número de login + senha |
| `lib/main.dart` | Redirecionar conforme estado da sessão |
| `lib/screens/home_screen.dart` | Adicionar botão de logout |
| `lib/screens/site_detail_screen.dart` | Ocultar botões de foto para perfil `geral` |
| `lib/services/supabase_service.dart` | Adicionar `insertAuditLog()` |
| Supabase Dashboard | Criar tabelas `profiles` e `audit_log`, RLS |

---

## LoginScreen — UX

- Campo **Número de login**
- Campo **Senha** com toggle de visibilidade
- Botão **Entrar** com loading state
- Mensagem de erro inline (credenciais inválidas ou domínio não autorizado)
- Identidade visual Claro (vermelho `#EE1105`, fundo branco)
- Sem opção de cadastro — fluxo 100% pelo admin

---

## Pontos de Atenção

### Sessão persistente
`supabase_flutter` persiste a sessão via `SharedPreferences`. No startup o app
verifica `currentSession` — se válida, vai direto para `HomeScreen`.

### Validação de domínio
O Supabase não filtra domínio nativamente. A validação ocorre no app antes
de chamar `signIn`. O admin também deve cadastrar apenas e-mails autorizados.

### Cadastro de usuários
Admin cadastra via **Supabase Dashboard → Authentication → Users → Add user**.
O Supabase dispara o e-mail de convite. Após isso, o admin atualiza a tabela
`profiles` com `login`, `nome` e `role`.

### Auditoria
Toda chamada a `updateFoto()` e `deleteFoto()` deve chamar `insertAuditLog()`
com `user_id`, `site_id` e a ação realizada.

---

## Status

- [x] Planejamento documentado
- [ ] Criar tabelas `profiles` e `audit_log` no Supabase
- [ ] Configurar RLS para `authenticated` e `cell_owner`
- [ ] Criar `UserProfile` model
- [ ] Criar `AuthProvider`
- [ ] Criar `LoginScreen`
- [ ] Atualizar `main.dart` com redirecionamento por sessão
- [ ] Ocultar ações de edição para perfil `geral`
- [ ] Integrar `insertAuditLog` nas operações de foto
- [ ] Adicionar logout no `HomeScreen`
- [ ] Testar login, persistência de sessão e logout
