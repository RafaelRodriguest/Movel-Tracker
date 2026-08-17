import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/site.dart';
import '../providers/site_provider.dart';
import '../services/supabase_service.dart';
import '../theme/app_colors.dart';

// Opções de chaves comuns a todos os estados — base para as UFs que ainda
// não têm lista própria cadastrada (PA, AM, RR, AP).
const _opcoesChaveBase = [
  'NO CONT A',
  'MULTLOCK',
  'EBT TETRA',
];

// Opções de chaves por estado (portão, gradil 01 e gradil 02 compartilham a
// mesma lista dentro de um estado). Estados ausentes caem em _opcoesChaveBase.
const _opcoesChavePorUf = <String, List<String>>{
  'MA': [
    'NO CONT A',
    'MA GDA',
    'MA GDV',
    'MA GDB',
    'MA GMR',
    'GD SLS V',
    'GD CHI V',
    'GD PHE V',
    'GD BBL V',
    'GD ITZ V',
    'MA PCN V',
    'MULTLOCK',
    'EBT TETRA',
  ],
};

/// Lista de chaves válidas para o estado do site.
List<String> opcoesChaveDe(String uf) =>
    _opcoesChavePorUf[uf.toUpperCase()] ?? _opcoesChaveBase;

// Opções de fontes (fonte 01 e fonte 02 compartilham a mesma lista)
const _opcoesFonte = [
  'ELTEK 2500',
  'ELTEK FLATPACK 3000',
  'EMERSON',
  'VERTIV',
  'DELTA DPR4000',
  'DELTA DP2900',
];

// Opções de quantidade de baterias (1 a 9)
final _opcoesBaterias = List.generate(9, (i) => '${i + 1}');

class SiteOperacionalScreen extends StatefulWidget {
  final Site site;

  const SiteOperacionalScreen({super.key, required this.site});

  @override
  State<SiteOperacionalScreen> createState() => _SiteOperacionalScreenState();
}

class _SiteOperacionalScreenState extends State<SiteOperacionalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supabaseService = SupabaseService();
  bool _isSaving = false;

  // Controllers para campos de consumo
  late final TextEditingController _consumo01Controller;
  late final TextEditingController _consumo02Controller;

  // Estado dos dropdowns
  String? _chavePortao;
  String? _chaveGradil01;
  String? _chaveGradil02;
  String? _fonte01;
  String? _fonte02;
  String? _bateriasFonte01;
  String? _bateriasFonte02;

  @override
  void initState() {
    super.initState();
    final s = widget.site;
    _chavePortao = s.chavePortao;
    _chaveGradil01 = s.chaveGradil01;
    _chaveGradil02 = s.chaveGradil02;
    _fonte01 = s.fonte01;
    _fonte02 = s.fonte02;
    _bateriasFonte01 = s.bateriasFonte01;
    _bateriasFonte02 = s.bateriasFonte02;
    _consumo01Controller = TextEditingController(text: s.consumoFonte01 ?? '');
    _consumo02Controller = TextEditingController(text: s.consumoFonte02 ?? '');
  }

  @override
  void dispose() {
    _consumo01Controller.dispose();
    _consumo02Controller.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await _supabaseService.updateInformacoesOperacionais(
        widget.site.siteId,
        chavePortao: _chavePortao,
        chaveGradil01: _chaveGradil01,
        chaveGradil02: _chaveGradil02,
        fonte01: _fonte01,
        fonte02: _fonte02,
        consumoFonte01: _consumo01Controller.text.trim().isEmpty
            ? null
            : _consumo01Controller.text.trim(),
        consumoFonte02: _consumo02Controller.text.trim().isEmpty
            ? null
            : _consumo02Controller.text.trim(),
        bateriasFonte01: _bateriasFonte01,
        bateriasFonte02: _bateriasFonte02,
      );

      final updatedSite = widget.site.copyWith(
        chavePortao: _chavePortao,
        chaveGradil01: _chaveGradil01,
        chaveGradil02: _chaveGradil02,
        fonte01: _fonte01,
        fonte02: _fonte02,
        consumoFonte01: _consumo01Controller.text.trim().isEmpty
            ? null
            : _consumo01Controller.text.trim(),
        consumoFonte02: _consumo02Controller.text.trim().isEmpty
            ? null
            : _consumo02Controller.text.trim(),
        bateriasFonte01: _bateriasFonte01,
        bateriasFonte02: _bateriasFonte02,
      );

      if (mounted) {
        context.read<SiteProvider>().updateSiteFields(widget.site.siteId, updatedSite);
        Navigator.pop(context, updatedSite);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao salvar. Verifique a conexão.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informações Operacionais',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.site.nome,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textLight,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: AppColors.primary.withOpacity(0.1),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── SEÇÃO: CHAVES ──────────────────────────────────────
            _buildSectionHeader(
              icon: Icons.vpn_key_outlined,
              title: 'Chaves',
            ),
            const SizedBox(height: 12),
            _buildDropdown(
              label: 'Chave Portão',
              value: _chavePortao,
              options: opcoesChaveDe(widget.site.uf),
              onChanged: (v) => setState(() => _chavePortao = v),
            ),
            const SizedBox(height: 12),
            _buildDropdown(
              label: 'Chave Gradil 01',
              value: _chaveGradil01,
              options: opcoesChaveDe(widget.site.uf),
              onChanged: (v) => setState(() => _chaveGradil01 = v),
            ),
            const SizedBox(height: 12),
            _buildDropdown(
              label: 'Chave Gradil 02',
              value: _chaveGradil02,
              options: opcoesChaveDe(widget.site.uf),
              onChanged: (v) => setState(() => _chaveGradil02 = v),
            ),
            const SizedBox(height: 24),

            // ── SEÇÃO: GABINETE 01 ─────────────────────────────────
            _buildSectionHeader(
              icon: Icons.electrical_services_outlined,
              title: 'Gabinete 01',
            ),
            const SizedBox(height: 12),
            _buildDropdown(
              label: 'Fonte 01',
              value: _fonte01,
              options: _opcoesFonte,
              onChanged: (v) => setState(() => _fonte01 = v),
            ),
            const SizedBox(height: 12),
            _buildConsumoField(
              label: 'Consumo Fonte 01',
              controller: _consumo01Controller,
            ),
            const SizedBox(height: 12),
            _buildDropdown(
              label: 'Quantidade de Baterias Fonte 01',
              value: _bateriasFonte01,
              options: _opcoesBaterias,
              onChanged: (v) => setState(() => _bateriasFonte01 = v),
            ),
            const SizedBox(height: 24),

            // ── SEÇÃO: GABINETE 02 ─────────────────────────────────
            _buildSectionHeader(
              icon: Icons.electrical_services_outlined,
              title: 'Gabinete 02',
            ),
            const SizedBox(height: 12),
            _buildDropdown(
              label: 'Fonte 02',
              value: _fonte02,
              options: _opcoesFonte,
              onChanged: (v) => setState(() => _fonte02 = v),
            ),
            const SizedBox(height: 12),
            _buildConsumoField(
              label: 'Consumo Fonte 02',
              controller: _consumo02Controller,
            ),
            const SizedBox(height: 12),
            _buildDropdown(
              label: 'Quantidade de Baterias Fonte 02',
              value: _bateriasFonte02,
              options: _opcoesBaterias,
              onChanged: (v) => setState(() => _bateriasFonte02 = v),
            ),
            const SizedBox(height: 32),

            // ── BOTÃO SALVAR ───────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _salvar,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_outlined, size: 20),
                label: Text(
                  _isSaving ? 'SALVANDO...' : 'SALVAR INFORMAÇÕES',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
                  disabledForegroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({required IconData icon, required String title}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(height: 1, color: AppColors.primary.withOpacity(0.15)),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    // Valor gravado fora da lista do estado (dado legado ou migrado de outra UF)
    // ainda precisa aparecer — caso contrário o Dropdown dispara assert.
    final opcoes = (value == null || options.contains(value))
        ? options
        : [value, ...options];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          isDense: true,
        ),
        isExpanded: true,
        hint: Text(
          'Selecionar',
          style: TextStyle(color: AppColors.textSecondary.withOpacity(0.6), fontSize: 14),
        ),
        icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
        items: [
          DropdownMenuItem<String>(
            value: null,
            child: Text(
              '— Nenhum —',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ),
          ...opcoes.map(
            (opt) => DropdownMenuItem<String>(
              value: opt,
              child: Text(opt, style: const TextStyle(fontSize: 14)),
            ),
          ),
        ],
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildConsumoField({
    required String label,
    required TextEditingController controller,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
        ],
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
          suffixText: 'A',
          suffixStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
            fontSize: 15,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          isDense: true,
        ),
        style: const TextStyle(fontSize: 14),
      ),
    );
  }
}
