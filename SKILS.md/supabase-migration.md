# Planejamento: Migração Google Sheets → Supabase

## Contexto

Atualmente o app busca dados de sites (torres Claro/MA) via CSV exportado do Google Sheets.
O objetivo é migrar para o Supabase como backend, ganhando uma API REST/realtime, autenticação e um banco de dados PostgreSQL gerenciado.

---

## Por que migrar?

| Google Sheets (atual) | Supabase (destino) |
|-----------------------|--------------------|
| Sem controle de acesso por usuário | Auth integrado (JWT) |
| Apenas leitura via CSV público | CRUD completo via REST/SDK |
| Sem realtime | Realtime com websockets |
| Limitado a ~10MB de dados | PostgreSQL com escala real |
| Sem possibilidade de histórico/auditoria | Triggers, logs e Row Level Security |
| Parsing frágil de CSV | API tipada e estruturada |

---

## Arquitetura Alvo

```
Supabase (PostgreSQL)
    ↓
SupabaseService (substitui DataService)
    ↓
SiteRepository (mesma interface, nova fonte de dados)
    ↓
SiteProvider (sem mudança)
    ↓
Screens (sem mudança)
```

A camada de UI e o Provider **não precisam mudar**. Apenas `DataService` é substituído e `SiteRepository` tem a fonte de dados trocada.

---

## Etapas da Migração

### Fase 1 — Configurar o Supabase

- [ ] Criar projeto no [supabase.com](https://supabase.com)
- [ ] Criar tabela `sites` no banco PostgreSQL com as colunas do modelo atual:

```sql
create table sites (
  id          bigserial primary key,
  site_id     text not null unique,
  sigla       text,
  nome        text,
  endereco    text,
  municipio   text,
  tecnico     text,
  latitude    double precision,
  longitude   double precision,
  detentora   text,
  uc          text,
  tecnologias text,   -- ex: '4G,5G' (mesmo formato atual)
  status      text default 'Ativo',
  created_at  timestamptz default now()
);
```

- [ ] Definir Row Level Security (RLS):
  - Leitura pública para todos os dados (mesma permissão atual do Sheets)
  - Escrita restrita a usuários autenticados (para futuras edições no app)
- [ ] Obter as credenciais: `SUPABASE_URL` e `SUPABASE_ANON_KEY`

### Fase 2 — Popular o Banco

- [ ] Exportar a planilha atual do Google Sheets como CSV
- [ ] Importar o CSV diretamente no Supabase via Table Editor ou SQL:

```sql
-- Alternativa: usar o importador CSV da dashboard do Supabase
-- Ou via psql:
\copy sites(site_id, sigla, nome, endereco, municipio, tecnico,
            latitude, longitude, detentora, uc, tecnologias, status)
FROM 'sites.csv' DELIMITER ',' CSV HEADER;
```

### Fase 3 — Adaptar o App Flutter

#### 3.1 Adicionar dependência

No `app/pubspec.yaml`, substituir/adicionar:

```yaml
dependencies:
  supabase_flutter: ^2.x.x   # adicionar
  # http e csv podem ser removidos após a migração
```

#### 3.2 Inicializar o Supabase

Em `app/lib/main.dart`:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'SUA_SUPABASE_URL',
    anonKey: 'SUA_SUPABASE_ANON_KEY',
  );
  runApp(const MyApp());
}
```

#### 3.3 Criar `SupabaseService` (substitui `DataService`)

Novo arquivo: `app/lib/services/supabase_service.dart`

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/site.dart';

class SupabaseService {
  final _client = Supabase.instance.client;

  Future<List<Site>> fetchSites() async {
    final data = await _client
        .from('sites')
        .select()
        .order('nome');

    return (data as List)
        .map((row) => Site.fromJson(row as Map<String, dynamic>))
        .toList();
  }
}
```

> O `Site.fromJson` já existe e aceita `Map<String, dynamic>` — compatível com a resposta do Supabase. Verificar se os nomes das colunas do banco batem com as chaves esperadas pelo modelo.

#### 3.4 Atualizar `SiteRepository`

Substituir a instância de `DataService` por `SupabaseService` e trocar o método `loadFromGoogleSheets` por `loadFromSupabase`:

```dart
// Antes
final DataService _dataService = DataService();
Future<List<Site>?> loadFromGoogleSheets() async { ... }

// Depois
final SupabaseService _supabaseService = SupabaseService();
Future<List<Site>?> loadFromSupabase() async { ... }
```

#### 3.5 Atualizar `SiteProvider`

Trocar a chamada `loadFromGoogleSheets()` por `loadFromSupabase()` no método `_loadSites`.

### Fase 4 — Testes e Validação

- [ ] Executar `flutter analyze` — verificar se não há erros de tipo
- [ ] Executar `flutter test` — adaptar mocks nos testes que instanciam `DataService`
- [ ] Testar no emulador/dispositivo: verificar se os dados carregam corretamente
- [ ] Validar busca, filtros e navegação GPS após migração
- [ ] Confirmar que o fallback mock ainda funciona se o Supabase estiver offline

### Fase 5 — Limpeza (pós-validação)

- [ ] Remover `data_service.dart`
- [ ] Remover dependências `http` e `csv` do `pubspec.yaml` (se não usadas em outro lugar)
- [ ] Remover referências ao Google Sheets no `CLAUDE.md` e `DADOS.md`
- [ ] Atualizar testes que mockavam `DataService`

---

## Pontos de Atenção

### Credenciais
Não commitar `SUPABASE_URL` e `SUPABASE_ANON_KEY` diretamente no código.
Usar variáveis de ambiente ou um arquivo `lib/config/env.dart` ignorado pelo `.gitignore`.

```dart
// lib/config/env.dart  (adicionar ao .gitignore)
class Env {
  static const supabaseUrl = 'https://xxxxxxxxxxx.supabase.co';
  static const supabaseAnonKey = 'eyJ...';
}
```

### Compatibilidade do `Site.fromJson`
A resposta do Supabase retorna `double` para coordenadas diretamente — o método `_parseCoordinate` atual espera `String`. Precisará de ajuste:

```dart
// Antes (para CSV com string):
latitude: _parseCoordinate(json['latitude']?.toString()),

// Depois (para Supabase que já retorna double/num):
latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
```

Ou manter o `_parseCoordinate` tolerante a ambos os tipos (String e num).

### `tecnologias` como Array ou Text
Decidir se o campo `tecnologias` no Supabase será:
- `text` (string `'4G,5G'`) — mantém compatibilidade com o `_parseTecnologias` atual
- `text[]` (array PostgreSQL) — mais correto, mas exige ajuste no `fromJson`

**Recomendação inicial:** manter como `text` para facilitar a migração, e refatorar para `text[]` depois.

---

## Dependências a Adicionar/Remover

| Pacote | Ação |
|--------|------|
| `supabase_flutter: ^2.x.x` | Adicionar |
| `http: ^1.2.2` | Remover (após migração) |
| `csv: ^6.0.0` | Remover (após migração) |

---

## Arquivos Impactados

| Arquivo | Mudança |
|---------|---------|
| `app/pubspec.yaml` | Adicionar `supabase_flutter`, remover `http` e `csv` |
| `app/lib/main.dart` | Inicializar `Supabase.initialize(...)` |
| `app/lib/services/data_service.dart` | **Remover** (substituído) |
| `app/lib/services/supabase_service.dart` | **Criar** novo serviço |
| `app/lib/repositories/site_repository.dart` | Trocar `DataService` por `SupabaseService` |
| `app/lib/providers/site_provider.dart` | Trocar chamada `loadFromGoogleSheets` |
| `app/lib/models/site.dart` | Ajuste no `fromJson` para tipos `num`/`double` |
| `app/lib/config/env.dart` | **Criar** para guardar credenciais (no `.gitignore`) |
| `app/test/services/data_service_test.dart` | Adaptar ou substituir por testes do novo serviço |

---

## Status

- [x] Planejamento documentado
- [ ] Fase 1 — Configurar Supabase
- [ ] Fase 2 — Popular banco
- [ ] Fase 3 — Adaptar Flutter
- [ ] Fase 4 — Testes
- [ ] Fase 5 — Limpeza
