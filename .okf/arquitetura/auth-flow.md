---
type: Fluxo
title: Fluxo de Autenticação
description: Login via RPC, sessão persistida pelo supabase_flutter e reset de senha via deep link.
tags: [auth, supabase, deep-link]
timestamp: 2026-07-29T00:00:00Z
---

# Overview

O app inicializa em `main.dart → _AppEntry` e decide a tela de entrada com base no estado de autenticação:

- `auth.isPasswordRecovery` → `ResetPasswordScreen`
- `auth.isLoggedIn` → `HomeScreen`
- (nenhum) → `LoginScreen`

O login usa número de login (não e-mail): a RPC `get_email_by_login` no [Supabase](../servicos/supabase-service.md) traduz o número para o e-mail real, que é passado ao `signInWithPassword`.

`AuthProvider` escuta `onAuthStateChange` e deep links via `app_links`. A sessão é persistida automaticamente entre reinicializações do app.

O reset de senha é iniciado pelo usuário via e-mail. O Supabase envia um link com token; o app captura via deep link `com.claro.moveltracker://login-callback/`, chama `getSessionFromUrl` e exibe `ResetPasswordScreen`.

Apenas domínios `@claro.com.br` e `@stte.com.br` são autorizados — ver [Perfis de Acesso](../acesso/roles.md).

# Arquivos Relevantes

| Arquivo | Responsabilidade |
|---------|-----------------|
| `lib/providers/auth_provider.dart` | Estado de sessão, login, logout, reset |
| `lib/screens/login_screen.dart` | UI de login com número + senha |
| `lib/screens/reset_password_screen.dart` | Redefinição de senha via token |
