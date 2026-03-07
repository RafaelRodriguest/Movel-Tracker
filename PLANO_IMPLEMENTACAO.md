# Plano de Implementação — Supabase + Cloudinary

## Visão Geral

Expansão do Movel Tracker para suportar múltiplas UFs, autenticação com controle de acesso por perfil (RBAC) e armazenamento de imagens escalável.

**Stack escolhida:**
- **Supabase** — autenticação + banco de dados PostgreSQL + RBAC
- **Cloudinary** — armazenamento de imagens (25GB grátis)
- **Flutter** — app Android (sem mudança de framework)

**Nenhuma dependência de TI externo. Tudo configurado e gerenciado pelo desenvolvedor.**

---

## Arquitetura Final

```
Flutter App
│
├── Supabase Auth
│   └── Login por email/senha
│   └── Roles: viewer / editor / admin
│
├── Supabase PostgreSQL
│   ├── tabela: sites        (dados de todas as UFs)
│   ├── tabela: profiles     (usuários + roles)
│   └── Row Level Security   (viewer lê, editor insere imagens)
│
└── Cloudinary Storage
    └── Upload de imagens por site
    └── URL pública salva no Supabase (tabela: site_images)
```

---

## Perfis de Acesso (RBAC)

| Perfil | Ver sites | Navegar GPS | Ver fotos | Enviar fotos | Gerenciar usuários |
|--------|-----------|-------------|-----------|--------------|-------------------|
| `viewer` | ✅ | ✅ | ✅ | ❌ | ❌ |
| `editor` | ✅ | ✅ | ✅ | ✅ | ❌ |
| `admin` | ✅ | ✅ | ✅ | ✅ | ✅ |

---

## Fase 1 — Configurar o Supabase

### 1.1 Criar conta e projeto
1. Acessar [supabase.com](https://supabase.com) e criar conta gratuita
2. Criar novo projeto (guardar a `URL` e a `anon key` geradas)

### 1.2 Criar as tabelas no banco

Executar no SQL Editor do Supabase:

```sql
-- Extensão para UUIDs
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Tabela de perfis de usuário (vinculada ao Supabase Auth)
CREATE TABLE profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  email TEXT NOT NULL,
  nome TEXT,
  role TEXT NOT NULL DEFAULT 'viewer' CHECK (role IN ('viewer', 'editor', 'admin')),
  uf TEXT,                        -- UF de atuação do técnico (opcional)
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tabela principal de sites (todas as UFs)
CREATE TABLE sites (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  site_id TEXT NOT NULL UNIQUE,   -- Ex: SLZ001
  sigla TEXT,
  nome TEXT NOT NULL,
  endereco TEXT,
  municipio TEXT,
  uf TEXT NOT NULL,               -- Ex: MA, PA, PI
  tecnico TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  detentora TEXT,
  uc TEXT,
  tecnologias TEXT[],             -- Ex: {'4G','5G'}
  status TEXT DEFAULT 'Ativo',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tabela de imagens dos sites
CREATE TABLE site_images (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  site_id TEXT NOT NULL REFERENCES sites(site_id) ON DELETE CASCADE,
  url TEXT NOT NULL,              -- URL pública do Cloudinary
  uploaded_by UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índices para performance de busca
CREATE INDEX idx_sites_uf ON sites(uf);
CREATE INDEX idx_sites_municipio ON sites(municipio);
CREATE INDEX idx_sites_site_id ON sites(site_id);
CREATE INDEX idx_site_images_site_id ON site_images(site_id);
```

### 1.3 Configurar Row Level Security (RLS)

```sql
-- Habilitar RLS em todas as tabelas
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE sites ENABLE ROW LEVEL SECURITY;
ALTER TABLE site_images ENABLE ROW LEVEL SECURITY;

-- profiles: usuário vê e edita apenas o próprio perfil
CREATE POLICY "usuario ve proprio perfil"
  ON profiles FOR SELECT USING (auth.uid() = id);

CREATE POLICY "usuario edita proprio perfil"
  ON profiles FOR UPDATE USING (auth.uid() = id);

-- sites: qualquer usuário autenticado pode ler
CREATE POLICY "usuarios autenticados leem sites"
  ON sites FOR SELECT USING (auth.role() = 'authenticated');

-- sites: somente admin pode inserir/editar/deletar
CREATE POLICY "admin gerencia sites"
  ON sites FOR ALL USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- site_images: qualquer autenticado pode ver
CREATE POLICY "usuarios autenticados veem imagens"
  ON site_images FOR SELECT USING (auth.role() = 'authenticated');

-- site_images: somente editor e admin podem inserir
CREATE POLICY "editor e admin inserem imagens"
  ON site_images FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND role IN ('editor', 'admin')
    )
  );

-- site_images: somente admin pode deletar
CREATE POLICY "admin deleta imagens"
  ON site_images FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Trigger: criar perfil automaticamente ao cadastrar usuário
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO profiles (id, email, role)
  VALUES (NEW.id, NEW.email, 'viewer');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();
```

---

## Fase 2 — Migrar dados do Google Sheets para o Supabase

### 2.1 Exportar o CSV atual
1. Abrir a planilha Google Sheets
2. Arquivo → Download → CSV
3. Salvar como `sites.csv`

### 2.2 Adicionar coluna `uf` ao CSV
- Abrir o CSV e adicionar coluna `uf` com o valor `MA` para todos os registros atuais
- Para novas UFs, basta adicionar linhas com o `uf` correspondente

### 2.3 Importar no Supabase
1. No painel Supabase → Table Editor → tabela `sites`
2. Clicar em "Import data" → selecionar o CSV
3. Mapear as colunas conforme a tabela
4. Confirmar importação

**Ou via SQL:**
```sql
-- Após importar o CSV via painel, verificar dados:
SELECT uf, COUNT(*) as total FROM sites GROUP BY uf ORDER BY uf;
```

---

## Fase 3 — Configurar o Cloudinary

### 3.1 Verificar configuração atual
O projeto já tem integração com Cloudinary na branch `feat/Upload_image`.
Verificar `app/lib/config/cloudinary_config.dart`:

```dart
static const String cloudName = 'SEU_CLOUD_NAME';
static const String uploadPreset = 'movel_tracker_preset'; // unsigned preset
```

### 3.2 Criar upload preset (se ainda não existir)
1. Acessar [cloudinary.com/console](https://cloudinary.com/console)
2. Settings → Upload → Upload Presets → Add upload preset
3. Signing mode: **Unsigned**
4. Folder: `movel_tracker/sites`
5. Salvar e copiar o nome do preset para `cloudinary_config.dart`

### 3.3 Fluxo de upload com Supabase
Após o upload no Cloudinary, salvar a URL no Supabase em vez do Google Sheets:

```dart
// Após upload bem-sucedido no Cloudinary
final imageUrl = await imageService.uploadToCloudinary(compressedImage);

// Salvar URL no Supabase
await supabase.from('site_images').insert({
  'site_id': site.siteId,
  'url': imageUrl,
  'uploaded_by': supabase.auth.currentUser!.id,
});
```

---

## Fase 4 — Integrar Supabase no Flutter

### 4.1 Adicionar dependência

```yaml
# app/pubspec.yaml
dependencies:
  supabase_flutter: ^2.5.0
```

### 4.2 Inicializar no main.dart

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

// Helper global
final supabase = Supabase.instance.client;
```

### 4.3 Criar AuthService

```dart
// app/lib/services/auth_service.dart
class AuthService {
  final _client = Supabase.instance.client;

  Future<void> signIn(String email, String password) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<String> getUserRole() async {
    final userId = _client.auth.currentUser!.id;
    final data = await _client
        .from('profiles')
        .select('role')
        .eq('id', userId)
        .single();
    return data['role'] as String;
  }

  bool get isLoggedIn => _client.auth.currentUser != null;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
}
```

### 4.4 Criar AuthProvider

```dart
// app/lib/providers/auth_provider.dart
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  String? _role;
  bool _isLoading = false;
  String? _error;

  String? get role => _role;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _authService.isLoggedIn;
  bool get canUploadImages => _role == 'editor' || _role == 'admin';
  bool get isAdmin => _role == 'admin';

  Future<void> signIn(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.signIn(email, password);
      _role = await _authService.getUserRole();
    } catch (e) {
      _error = 'Email ou senha incorretos';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _role = null;
    notifyListeners();
  }
}
```

### 4.5 Atualizar SiteRepository para buscar do Supabase

```dart
// Substituir DataService (Google Sheets) por Supabase
Future<List<Site>> fetchSites({String? uf}) async {
  var query = supabase.from('sites').select();

  if (uf != null && uf.isNotEmpty) {
    query = query.eq('uf', uf);
  }

  final data = await query.order('nome');
  return (data as List).map((row) => Site.fromJson(row)).toList();
}
```

### 4.6 Tela de Login (nova tela)

```dart
// app/lib/screens/login_screen.dart
// Campos: email, senha
// Botão: Entrar
// Ao autenticar: navega para HomeScreen
// AuthProvider controla o estado de loading e erro
```

---

## Fase 5 — Adaptar a UI para RBAC

### Botão de câmera (condicional por role)

```dart
// Em site_detail_screen.dart
Consumer<AuthProvider>(
  builder: (context, auth, _) {
    if (!auth.canUploadImages) return const SizedBox.shrink();
    return FloatingActionButton(
      onPressed: () => _showImagePicker(context),
      child: const Icon(Icons.camera_alt),
    );
  },
)
```

### Filtro por UF na HomeScreen

```dart
// Adicionar DropdownButton com lista de UFs disponíveis
// Ao selecionar, recarrega sites filtrados do Supabase
DropdownButton<String>(
  value: selectedUf,
  items: ufs.map((uf) => DropdownMenuItem(value: uf, child: Text(uf))).toList(),
  onChanged: (uf) => siteProvider.filterByUf(uf),
)
```

---

## Fase 6 — Gerenciamento de Usuários (Admin)

O admin cadastra e gerencia usuários **pelo painel do Supabase**:

1. Supabase Dashboard → Authentication → Users → "Invite user"
2. Informar e-mail do técnico (ele recebe link para criar senha)
3. Após criação, editar o role na tabela `profiles`:

```sql
UPDATE profiles SET role = 'editor' WHERE email = 'tecnico@claro.com.br';
```

> Futuramente pode ser criada uma tela de admin no próprio app para gerenciar isso.

---

## Resumo das Fases

| Fase | O que faz | Dependência |
|------|-----------|-------------|
| 1 — Supabase setup | Banco + Auth + RLS | Só você |
| 2 — Migração CSV | Dados do Sheets → Supabase | Só você |
| 3 — Cloudinary | Confirmar config de upload | Só você |
| 4 — Flutter Supabase | SDK + AuthService + AuthProvider | Só você |
| 5 — UI RBAC | Login screen + filtro UF + botão condicional | Só você |
| 6 — Gestão usuários | Cadastrar técnicos via painel | Só você |

**Custo total: R$ 0,00**
- Supabase Free: até 500MB DB, 2GB bandwidth
- Cloudinary Free: 25GB storage, 25GB bandwidth

---

## Variáveis de ambiente necessárias

Criar `app/.env`:

```env
SUPABASE_URL=https://xxxxxxxxxxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
CLOUDINARY_CLOUD_NAME=seu_cloud_name
CLOUDINARY_UPLOAD_PRESET=movel_tracker_preset
```

Adicionar `app/.env` ao `.gitignore` para não vazar credenciais.
