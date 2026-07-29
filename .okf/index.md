---
okf_version: "0.1"
---

# Movel Tracker — Knowledge Bundle

Aplicativo Android para técnicos de campo da Claro no Maranhão. Permite consultar informações técnicas de sites (torres), navegar via GPS e gerenciar fotos.

# Arquitetura

* [Visão Geral](arquitetura/) - Estrutura de camadas e fluxos principais do app
* [Fluxo de Autenticação](arquitetura/auth-flow.md) - Login, sessão e reset de senha via deep link
* [Fluxo de Upload de Foto](arquitetura/foto-upload-flow.md) - Picker → Cloudinary → Supabase
* [Fluxo Operacional](arquitetura/operacional-flow.md) - Edição de chaves, fontes e baterias

# Dados

* [Modelo Site](dados/) - Campos, regras de negócio e padrões do modelo principal
* [Site](dados/site.md) - Entidade central com sentinel copyWith e imageUrls fixo
* [UserProfile](dados/user-profile.md) - Perfil de usuário com roles de acesso
* [Tabelas Supabase](dados/supabase-tables.md) - sites, profiles e audit_log

# Serviços

* [Serviços](servicos/) - Integrações externas e camada de dados
* [SupabaseService](servicos/supabase-service.md) - CRUD sites/fotos e audit log
* [CloudinaryService](servicos/cloudinary-service.md) - Upload e transformação de imagens
* [SiteRepository](servicos/site-repository.md) - Carregamento com fallback mock

# Acesso e Segurança

* [Controle de Acesso](acesso/) - Roles, RLS e domínios autorizados
* [Perfis de Acesso](acesso/roles.md) - cell_owner vs geral
* [RLS Supabase](acesso/rls.md) - Políticas de Row Level Security
