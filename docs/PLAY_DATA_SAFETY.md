# Formulário de Segurança dos Dados — Play Console

Respostas para *Política > Conteúdo do app > Segurança dos dados*.
Fonte da verdade: `AndroidManifest.xml` (permissões), `supabase_service.dart`,
`cloudinary_service.dart`, `secure_session_storage.dart`.

## Seção 1 — Coleta e compartilhamento

| Pergunta | Resposta |
|---|---|
| Seu app coleta ou compartilha algum dos tipos de dados exigidos? | **Sim** |
| Todos os dados são criptografados em trânsito? | **Sim** (HTTPS; `usesCleartextTraffic="false"`) |
| Você fornece uma forma de o usuário solicitar a exclusão dos dados? | **Sim** — por e-mail (contas geridas por admin, sem auto-cadastro) |

## Seção 2 — Tipos de dados

Marcar **exatamente** estes quatro. Todos são *coletados*, nenhum é *compartilhado*
(no sentido do Play: enviado a terceiro para uso próprio dele — Supabase e Cloudinary
são operadores de infraestrutura, o que **não** conta como compartilhamento).

### Informações pessoais > Nome
- Coletado: Sim · Compartilhado: Não
- Obrigatório: Sim
- Vinculado ao usuário: Sim · Usado para rastrear: Não
- Finalidade: **Gerenciamento de contas**

### Informações pessoais > Endereço de e-mail
- Coletado: Sim · Compartilhado: Não
- Obrigatório: Sim
- Vinculado ao usuário: Sim · Usado para rastrear: Não
- Finalidade: **Gerenciamento de contas**

### Informações pessoais > IDs do usuário
> Cobre o número de login e o identificador usado no `audit_log`.
- Coletado: Sim · Compartilhado: Não
- Obrigatório: Sim
- Vinculado ao usuário: Sim · Usado para rastrear: Não
- Finalidade: **Gerenciamento de contas**, **Funcionalidade do app**

### Fotos e vídeos > Fotos
- Coletado: Sim · Compartilhado: Não
- Obrigatório: Não (o usuário só envia se quiser)
- Vinculado ao usuário: Sim · Usado para rastrear: Não
- Finalidade: **Funcionalidade do app**

## Seção 3 — NÃO marcar

| Tipo | Por quê |
|---|---|
| Localização (aproximada ou precisa) | Sem permissão de GPS no manifest. As coordenadas são dos sites, não do dispositivo. Abrir o Google Maps por link não é coleta. |
| Informações financeiras | Não há pagamento no app |
| Mensagens, contatos, calendário | Sem permissões correspondentes |
| Atividade no app / histórico de pesquisa | Sem analytics; o `audit_log` é registro de edição de dado técnico, não telemetria de uso |
| Registros de falhas / diagnósticos | Nenhum SDK de crash reporting integrado |
| Arquivos e documentos | Só imagens, já declaradas |

## Práticas de segurança (checkboxes finais)

- [x] Os dados são criptografados em trânsito
- [x] Você pode solicitar a exclusão dos dados
- [x] Comprometido com a Política de Famílias do Google Play — **não aplicável** (público 18+)
- [ ] Auditado de forma independente — não

## Campos relacionados fora do formulário

- **Política de privacidade (URL):** a página em `docs/privacidade/`
- **Acesso ao app:** marcar *"Partes do app têm acesso restrito"* e fornecer login e senha
  de um usuário de teste com perfil `geral` no Supabase de **produção**
- **Anúncios:** o app não contém anúncios
- **Público-alvo:** 18 e mais
