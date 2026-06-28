import 'package:flutter/material.dart';
import '../models/solicitacao.dart';
import '../core/constants/app_colors.dart';
import 'status_tag.dart';

class SolicitacaoCard extends StatelessWidget {
  final Solicitacao solicitacao;
  final VoidCallback onTap;

  const SolicitacaoCard({
    Key? key,
    required this.solicitacao,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.bgPrimary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    solicitacao.clienteNome ?? 'Cliente',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                StatusTag(status: solicitacao.status),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${solicitacao.tipoServico.label} · ${solicitacao.veiculoDisplay}',
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
            const Divider(
                height: 16, thickness: 0.5, color: AppColors.borderLight),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    solicitacao.endereco,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.chevron_right,
                    size: 16, color: AppColors.textTertiary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
