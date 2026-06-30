// lib/services/excel_export_service.dart
import 'dart:html' as html;
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:webapp_pesquisa_avalicao_dashboard/model/avaliacoes_model.dart';

class ExcelExportService {
  void exportarEstatisticas(EstatisticasFilial estatisticas) {
    final excel = Excel.createExcel();
    excel.delete('Sheet1');

    // ===== Aba 1: Resumo =====
    final resumo = excel['Resumo'];

    resumo.appendRow([
      TextCellValue('Filial'),
      TextCellValue(estatisticas.filialNome),
    ]);
    resumo.appendRow([
      TextCellValue('Total de Avaliações'),
      IntCellValue(estatisticas.totalAvaliacoes),
    ]);
    resumo.appendRow([]);
    resumo.appendRow([
      TextCellValue('Métrica'),
      TextCellValue('Média'),
      TextCellValue('% Satisfação'),
    ]);

    void linhaMetrica(String nome, double valor) {
      resumo.appendRow([
        TextCellValue(nome),
        TextCellValue(valor.toStringAsFixed(2)),
        TextCellValue('${((valor / 3.0) * 100).toStringAsFixed(0)}%'),
      ]);
    }

    linhaMetrica('Satisfação Geral', estatisticas.mediaSatisfacaoGeral);
    linhaMetrica('Sabor', estatisticas.mediaSabor);
    linhaMetrica('Qualidade dos Produtos', estatisticas.mediaQualidadeProdutos);
    linhaMetrica('Variedade de Produtos', estatisticas.mediaVariedadeProdutos);
    linhaMetrica('Atendimento', estatisticas.mediaCaixaAtendimento);

    for (var col = 0; col < 3; col++) {
      final cell = resumo.cell(CellIndex.indexByColumnRow(
        columnIndex: col,
        rowIndex: 3,
      ));
      cell.cellStyle = CellStyle(bold: true);
    }

    // ===== Aba 2: Avaliações Detalhadas =====
    final detalhes = excel['Avaliações'];

    detalhes.appendRow([
      TextCellValue('Usuário'),
      TextCellValue('Data/Hora'),
      TextCellValue('Satisfação Geral'),
      TextCellValue('Sabor'),
      TextCellValue('Qualidade'),
      TextCellValue('Variedade'),
      TextCellValue('Atendimento'),
      TextCellValue('Comentário'),
    ]);

    for (var col = 0; col < 8; col++) {
      final cell = detalhes.cell(CellIndex.indexByColumnRow(
        columnIndex: col,
        rowIndex: 0,
      ));
      cell.cellStyle = CellStyle(bold: true);
    }

    for (final av in estatisticas.avaliacoes) {
      detalhes.appendRow([
        TextCellValue(av.usuarioId),
        TextCellValue(
            DateFormat('dd/MM/yyyy HH:mm').format(av.dataHoraResposta)),
        DoubleCellValue(av.avaliacoes.satisfacaoGeralDouble),
        DoubleCellValue(av.avaliacoes.saborDouble),
        DoubleCellValue(av.avaliacoes.qualidadeProdutosDouble),
        DoubleCellValue(av.avaliacoes.variedadeProdutosDouble),
        DoubleCellValue(av.avaliacoes.caixaAtendimentoDouble),
        TextCellValue(av.comentarios),
      ]);
    }

    final bytes = excel.encode();
    if (bytes == null) return;

    final nomeArquivo =
        'avaliacoes_${estatisticas.filialNome}_${DateFormat('ddMMyyyy').format(DateTime.now())}.xlsx'
            .replaceAll(' ', '_');

    final blob = html.Blob(
      [bytes],
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', nomeArquivo)
      ..click();
    html.Url.revokeObjectUrl(url);
  }
}
