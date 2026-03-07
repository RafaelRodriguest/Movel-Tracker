# GITFLOW.md

Regras de desenvolvimento seguro para o projeto Movel Tracker.
O objetivo é garantir que a aplicação em produção (`main`) nunca quebre enquanto novas funcionalidades são desenvolvidas.

---

## Estrutura de Branches

```
main        → produção, sempre estável, nunca recebe commit direto
develop     → integração, base para todas as features
feat/*      → novas funcionalidades
fix/*       → correções de bugs
hotfix/*    → correção urgente em produção
release/*   → preparação de nova versão antes de ir para main
```

---

## Regras Obrigatórias

- Nunca commitar diretamente em `main` ou `develop`
- Toda feature sempre parte de `develop`
- Toda feature volta para `develop` ao terminar
- `main` só recebe merge de `release/*` ou `hotfix/*`
- Antes de qualquer merge, rodar `flutter analyze` e `flutter test`
- APKs de teste são gerados sempre a partir da branch atual de desenvolvimento
- APKs de produção são gerados apenas a partir de `main`

---

## Fluxo de uma Nova Feature

```bash
# 1. Partir do develop atualizado
git checkout develop
git pull origin develop

# 2. Criar branch da feature
git checkout -b feat/nome-da-feature

# 3. Desenvolver, testar no Android e commitar
git add .
git commit -m "feat: descrição do que foi feito"

# 4. Validar antes de mergear
flutter analyze
flutter test

# 5. Mergear de volta ao develop
git checkout develop
git merge feat/nome-da-feature --no-ff
git push origin develop

# 6. Remover branch local
git branch -d feat/nome-da-feature
```

---

## Fluxo de Correção de Bug (fix)

```bash
# 1. Partir do develop
git checkout develop
git pull origin develop

# 2. Criar branch de fix
git checkout -b fix/descricao-do-bug

# 3. Corrigir, testar no Android e commitar
git commit -m "fix: descrição da correção"

# 4. Mergear ao develop
git checkout develop
git merge fix/descricao-do-bug --no-ff
git push origin develop

git branch -d fix/descricao-do-bug
```

---

## Fluxo de Release (develop pronto para produção)

```bash
# 1. Criar branch de release a partir do develop
git checkout develop
git pull origin develop
git checkout -b release/vX.X.X

# 2. Ajustes finais: atualizar versão no pubspec.yaml
# version: X.X.X+BUILD

# 3. Gerar APK de release para validação final
cd app
flutter build apk --release
# testar o APK gerado em app/build/app/outputs/flutter-apk/app-release.apk

# 4. Se aprovado, mergear na main e taggear
git checkout main
git merge release/vX.X.X --no-ff
git tag vX.X.X
git push origin main --tags

# 5. Mergear também no develop para sincronizar
git checkout develop
git merge release/vX.X.X --no-ff
git push origin develop

# 6. Remover branch de release
git branch -d release/vX.X.X
```

---

## Fluxo de Hotfix (bug crítico em produção)

```bash
# 1. Partir da main
git checkout main
git pull origin main
git checkout -b hotfix/descricao-do-bug

# 2. Corrigir e commitar
git commit -m "fix: correção urgente de produção"

# 3. Gerar APK de teste para validar a correção
cd app
flutter build apk --debug

# 4. Mergear na main e taggear
git checkout main
git merge hotfix/descricao-do-bug --no-ff
git tag vX.X.Y
git push origin main --tags

# 5. Mergear também no develop
git checkout develop
git merge hotfix/descricao-do-bug --no-ff
git push origin develop

git branch -d hotfix/descricao-do-bug
```

---

## Geração de APKs

### APK de Teste (durante desenvolvimento)
Gerado a partir de qualquer branch de feature/fix para testar no Android pessoal.

```bash
cd app
flutter build apk --debug
# arquivo gerado: app/build/app/outputs/flutter-apk/app-debug.apk
# instalar no Android via cabo USB ou transferência de arquivo
```

### APK de Homologação (release candidate)
Gerado na branch `release/*` antes de ir para produção.

```bash
cd app
flutter build apk --release
# arquivo: app/build/app/outputs/flutter-apk/app-release.apk
```

### APK de Produção
Gerado somente a partir da `main` após merge do release.

```bash
git checkout main
cd app
flutter build apk --release
# nomear com a versão antes de distribuir:
# ex: movel_tracker-v1.2.0.apk
```

---

## Padrão de Mensagens de Commit

```
feat: adiciona filtro por UF na tela inicial
fix: corrige crash ao abrir site sem coordenadas
docs: atualiza GITFLOW.md
refactor: extrai lógica de busca para SiteRepository
test: adiciona testes para AuthProvider
chore: atualiza dependências do pubspec.yaml
release: v1.2.0
```

---

## Resumo Visual

```
main        ←─── release/vX.X.X ←─── develop ←─── feat/*
                                               ←─── fix/*
main        ←─── hotfix/*       ────────────→ develop
```

---

## Branches Atuais do Projeto

| Branch | Status | Descrição |
|--------|--------|-----------|
| `main` | Estavel | v1.0.0 — versão base funcional |
| `develop` | A criar | Base de integração (criar antes de continuar) |
| `feat/Upload_image` | Em progresso | Upload de fotos via Cloudinary |
| `feat/Supabase+cloudinary` | Em progresso | Auth + banco + storage |
