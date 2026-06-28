import 'package:flutter/material.dart';
import '../models/solicitacao.dart';
import '../core/constants/app_colors.dart';

class StatusTag extends StatelessWidget {
  final StatusSolicitacao status;

  const StatusTag({Key? key, required this.status}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: _fg),
      ),
    );
  }

  Color get _bg {
    switch (status) {
      case StatusSolicitacao.pendente:
        return AppColors.orangeLight;
      case StatusSolicitacao.aceita:
        return AppColors.greenLight;
      case StatusSolicitacao.emExecucao:
        return AppColors.blueLight;
      case StatusSolicitacao.concluida:
        return AppColors.tealLight;
      case StatusSolicitacao.recusada:
        return AppColors.redLight;
      case StatusSolicitacao.cancelada:
        return AppColors.purpleLight;
    }
  }

  Color get _fg {
    switch (status) {
      case StatusSolicitacao.pendente:
        return AppColors.orange;
      case StatusSolicitacao.aceita:
        return AppColors.greenDark;
      case StatusSolicitacao.emExecucao:
        return AppColors.blue;
      case StatusSolicitacao.concluida:
        return AppColors.teal;
      case StatusSolicitacao.recusada:
        return AppColors.redDark;
      case StatusSolicitacao.cancelada:
        return AppColors.purple;
    }
  }
}
