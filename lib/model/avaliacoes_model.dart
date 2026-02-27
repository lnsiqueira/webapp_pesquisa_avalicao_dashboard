import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo para representar uma Filial
class Filial {
  final String id;
  final String filial;

  Filial({
    required this.id,
    required this.filial,
  });

  factory Filial.fromMap(Map<String, dynamic> map) {
    return Filial(
      id: map['id'] ?? '',
      filial: map['filial'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'filial': filial,
    };
  }
}

/// Modelo para as avaliações individuais
/// IMPORTANTE: Os valores são salvos como números (int/double), não como strings!
class AvaliacoesCriteria {
  final dynamic sabor;
  final dynamic qualidadeProdutos;
  final dynamic temperatura;
  final dynamic variedadeProdutos;
  final dynamic caixaAtendimento;
  final dynamic satisfacaoGeral;

  AvaliacoesCriteria({
    required this.sabor,
    required this.qualidadeProdutos,
    required this.temperatura,
    required this.variedadeProdutos,
    required this.caixaAtendimento,
    required this.satisfacaoGeral,
  });

  factory AvaliacoesCriteria.fromMap(Map<String, dynamic> map) {
    return AvaliacoesCriteria(
      sabor: map['sabor'] ?? 0,
      qualidadeProdutos: map['qualidade_produtos'] ?? 0,
      temperatura: map['temperatura'] ?? 0,
      variedadeProdutos: map['variedade_produtos'] ?? 0,
      caixaAtendimento: map['caixa_atendimento'] ?? 0,
      satisfacaoGeral: map['satisfacao_geral'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sabor': sabor,
      'qualidade_produtos': qualidadeProdutos,
      'temperatura': temperatura,
      'variedade_produtos': variedadeProdutos,
      'caixa_atendimento': caixaAtendimento,
      'satisfacao_geral': satisfacaoGeral,
    };
  }

  /// Converte para double de forma segura
  double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  // Getters que convertem para double
  double get saborDouble => _toDouble(sabor);
  double get qualidadeProdutosDouble => _toDouble(qualidadeProdutos);
  double get temperaturaDouble => _toDouble(temperatura);
  double get variedadeProdutosDouble => _toDouble(variedadeProdutos);
  double get caixaAtendimentoDouble => _toDouble(caixaAtendimento);
  double get satisfacaoGeralDouble => _toDouble(satisfacaoGeral);
}

/// Modelo para informações adicionais
class OutrosInfo {
  final String origem;
  final String versaoFormulario;

  OutrosInfo({
    required this.origem,
    required this.versaoFormulario,
  });

  factory OutrosInfo.fromMap(Map<String, dynamic> map) {
    return OutrosInfo(
      origem: map['origem'] ?? 'desconhecido',
      versaoFormulario: map['versao_formulario'] ?? '1.0',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'origem': origem,
      'versao_formulario': versaoFormulario,
    };
  }
}

/// Modelo principal para uma Avaliacao
class Avaliacao {
  final String id;
  final String idFilial;
  final DateTime dataHoraResposta;
  final String usuarioId;
  final AvaliacoesCriteria avaliacoes;
  final String comentarios;
  final OutrosInfo outros;

  Avaliacao({
    required this.id,
    required this.idFilial,
    required this.dataHoraResposta,
    required this.usuarioId,
    required this.avaliacoes,
    required this.comentarios,
    required this.outros,
  });

  factory Avaliacao.fromMap(String docId, Map<String, dynamic> map) {
    // Converter Timestamp para DateTime
    DateTime dataHora;
    if (map['data_hora_resposta'] is Timestamp) {
      dataHora = (map['data_hora_resposta'] as Timestamp).toDate();
    } else if (map['data_hora_resposta'] is String) {
      try {
        dataHora = DateTime.parse(map['data_hora_resposta']);
      } catch (e) {
        dataHora = DateTime.now();
      }
    } else {
      dataHora = DateTime.now();
    }

    return Avaliacao(
      id: docId,
      idFilial: map['id_filial']?.toString() ?? '',
      dataHoraResposta: dataHora,
      usuarioId: map['usuario_id'] ?? '',
      avaliacoes: AvaliacoesCriteria.fromMap(map['avaliacoes'] ?? {}),
      comentarios: map['comentarios'] ?? '',
      outros: OutrosInfo.fromMap(map['outros'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_filial': idFilial,
      'data_hora_resposta': dataHoraResposta,
      'usuario_id': usuarioId,
      'avaliacoes': avaliacoes.toMap(),
      'comentarios': comentarios,
      'outros': outros.toMap(),
    };
  }
}

/// Modelo para estatísticas de uma filial
class EstatisticasFilial {
  final String filialId;
  final String filialNome;
  final int totalAvaliacoes;
  final double mediaSabor;
  final double mediaQualidadeProdutos;
  final double mediaTemperatura;
  final double mediaVariedadeProdutos;
  final double mediaCaixaAtendimento;
  final double mediaSatisfacaoGeral;
  final List<Avaliacao> avaliacoes;

  EstatisticasFilial({
    required this.filialId,
    required this.filialNome,
    required this.totalAvaliacoes,
    required this.mediaSabor,
    required this.mediaQualidadeProdutos,
    required this.mediaTemperatura,
    required this.mediaVariedadeProdutos,
    required this.mediaCaixaAtendimento,
    required this.mediaSatisfacaoGeral,
    required this.avaliacoes,
  });

  /// Factory para calcular estatísticas a partir de uma lista de avaliações
  factory EstatisticasFilial.fromAvaliacoes(
    String filialId,
    String filialNome,
    List<Avaliacao> avaliacoes,
  ) {
    if (avaliacoes.isEmpty) {
      return EstatisticasFilial(
        filialId: filialId,
        filialNome: filialNome,
        totalAvaliacoes: 0,
        mediaSabor: 0.0,
        mediaQualidadeProdutos: 0.0,
        mediaTemperatura: 0.0,
        mediaVariedadeProdutos: 0.0,
        mediaCaixaAtendimento: 0.0,
        mediaSatisfacaoGeral: 0.0,
        avaliacoes: avaliacoes,
      );
    }

    double calcularMedia(List<double> valores) {
      if (valores.isEmpty) return 0.0;
      return valores.reduce((a, b) => a + b) / valores.length;
    }

    final saborValues =
        avaliacoes.map((a) => a.avaliacoes.saborDouble).toList();
    final qualidadeValues =
        avaliacoes.map((a) => a.avaliacoes.qualidadeProdutosDouble).toList();
    final temperaturaValues =
        avaliacoes.map((a) => a.avaliacoes.temperaturaDouble).toList();
    final variedadeValues =
        avaliacoes.map((a) => a.avaliacoes.variedadeProdutosDouble).toList();
    final caixaValues =
        avaliacoes.map((a) => a.avaliacoes.caixaAtendimentoDouble).toList();
    final satisfacaoValues =
        avaliacoes.map((a) => a.avaliacoes.satisfacaoGeralDouble).toList();

    return EstatisticasFilial(
      filialId: filialId,
      filialNome: filialNome,
      totalAvaliacoes: avaliacoes.length,
      mediaSabor: calcularMedia(saborValues),
      mediaQualidadeProdutos: calcularMedia(qualidadeValues),
      mediaTemperatura: calcularMedia(temperaturaValues),
      mediaVariedadeProdutos: calcularMedia(variedadeValues),
      mediaCaixaAtendimento: calcularMedia(caixaValues),
      mediaSatisfacaoGeral: calcularMedia(satisfacaoValues),
      avaliacoes: avaliacoes,
    );
  }

  /// Retorna lista de médias por critério para gráficos
  List<double> get mediasPorCriterio => [
        mediaSabor,
        mediaQualidadeProdutos,
        mediaTemperatura,
        mediaVariedadeProdutos,
        mediaCaixaAtendimento,
      ];

  /// Retorna lista de nomes dos critérios
  static List<String> get nomeCriterios => [
        'Sabor',
        'Qualidade',
        'Temperatura',
        'Variedade',
        'Atendimento',
      ];

  /// Retorna cor baseada na média (verde, amarelo, vermelho)
  Color getCorPorMedia(double media) {
    if (media >= 4.0) return Colors.green;
    if (media >= 3.0) return Colors.amber;
    return Colors.red;
  }
}
