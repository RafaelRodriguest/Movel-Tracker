import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import 'home_screen.dart';

/// Estado (UF) exibido como card na tela de seleção.
class _UF {
  final String sigla;
  final String nome;
  final bool disponivel;

  const _UF({
    required this.sigla,
    required this.nome,
    this.disponivel = false,
  });
}

/// Estados atendidos pelo Movel Tracker.
/// Apenas MA possui funcionalidade ativa; os demais serão habilitados
/// conforme os sites forem cadastrados.
const _ufs = <_UF>[
  _UF(sigla: 'MA', nome: 'Maranhão', disponivel: true),
  _UF(sigla: 'PA', nome: 'Pará'),
  _UF(sigla: 'AM', nome: 'Amazonas'),
  _UF(sigla: 'RR', nome: 'Roraima'),
  _UF(sigla: 'AP', nome: 'Amapá'),
];

/// Tela inicial de seleção de estado (UF).
/// Cada card direciona para a tela de pesquisa de sites do respectivo estado.
class StateSelectionScreen extends StatelessWidget {
  const StateSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: AppColors.primary.withOpacity(0.1),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.cell_tower,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Movel Tracker',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        actions: [
          Consumer<AuthProvider>(
            builder: (context, auth, _) => PopupMenuButton(
              icon: const Icon(Icons.account_circle),
              itemBuilder: (_) => <PopupMenuEntry>[
                PopupMenuItem(
                  enabled: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        auth.profile?.nome ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textLight,
                        ),
                      ),
                      Text(
                        auth.profile?.isCellOwner == true
                            ? 'Cell Owner'
                            : 'Geral',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  onTap: () => context.read<AuthProvider>().signOut(),
                  child: const Row(
                    children: [
                      Icon(Icons.logout, color: Colors.red, size: 18),
                      SizedBox(width: 8),
                      Text('Sair', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Text(
              'Selecione o estado',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textLight,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 16),
            child: Text(
              'Consulte os sites técnicos por estado',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ..._ufs.map((uf) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _UFCard(uf: uf),
              )),
        ],
      ),
    );
  }
}

/// Card de estado (UF).
class _UFCard extends StatelessWidget {
  final _UF uf;

  const _UFCard({required this.uf});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (uf.disponivel) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${uf.nome} — em breve'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Sigla da UF
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: uf.disponivel
                      ? AppColors.primary.withOpacity(0.1)
                      : AppColors.textSecondary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  uf.sigla,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: uf.disponivel
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Nome do estado + status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      uf.nome,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      uf.disponivel ? 'Disponível' : 'Em breve',
                      style: TextStyle(
                        fontSize: 12,
                        color: uf.disponivel
                            ? AppColors.success
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                Icons.chevron_right,
                color: uf.disponivel
                    ? AppColors.primary
                    : AppColors.textSecondary.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
