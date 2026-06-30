import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:webapp_pesquisa_avalicao_dashboard/model/avaliacoes_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:html' as html;
import 'package:excel/excel.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  late final FirebaseFirestore _firestore;

  factory FirebaseService() {
    return _instance;
  }

  FirebaseService._internal() {
    _firestore = FirebaseFirestore.instance;
  }

  /// Busca todas as filiais disponíveis
  Future<List<Filial>> buscarFiliais() async {
    try {
      print('🔍 Buscando filiais...');
      final snapshot = await _firestore.collection('Filial').get();

      print('✅ Filiais encontradas: ${snapshot.docs.length}');

      final filiais = snapshot.docs.map((doc) {
        print('   - Filial: ${doc.data()}');
        return Filial.fromMap({
          ...doc.data(),
          'id': doc.id,
        });
      }).toList();

      return filiais;
    } catch (e) {
      print('❌ Erro ao buscar filiais: $e');
      return [];
    }
  }

  /// Busca uma filial específica pelo ID
  Future<Filial?> buscarFilialPorId(String filialId) async {
    try {
      print('🔍 Buscando filial: $filialId');
      final snapshot =
          await _firestore.collection('Filial').doc(filialId).get();

      if (snapshot.exists) {
        print('✅ Filial encontrada: ${snapshot.data()}');
        return Filial.fromMap({
          ...snapshot.data()!,
          'id': snapshot.id,
        });
      }
      print('⚠️ Filial não encontrada: $filialId');
      return null;
    } catch (e) {
      print('❌ Erro ao buscar filial: $e');
      return null;
    }
  }

  /// Busca todas as avaliações de uma filial específica
  // Future<List<Avaliacao>> buscarAvaliacoesPorFilial(
  //   String idFilial, {
  //   DateTime? dataInicial,
  //   DateTime? dataFinal,
  // }) async {
  //   try {
  //     print('🔍 Buscando avaliações para filial: $idFilial');

  //     Query query = _firestore
  //         .collection('avaliacoes')
  //         .where('id_filial', isEqualTo: idFilial);

  //     //Filtro de data inicial
  //     if (dataInicial != null) {
  //       query = query.where(
  //         'data_hora_resposta',
  //         isGreaterThanOrEqualTo: Timestamp.fromDate(dataInicial),
  //       );
  //     }

  //     //Filtro de data final
  //     if (dataFinal != null) {
  //       query = query.where(
  //         'data_hora_resposta',
  //         isLessThan: Timestamp.fromDate(
  //           DateTime(
  //             dataFinal.year,
  //             dataFinal.month,
  //             dataFinal.day + 1,
  //           ),
  //         ),
  //       );
  //     }

  //     query = query.orderBy('data_hora_resposta', descending: true);

  //     final snapshot = await query.get();

  //     print('✅ Avaliações encontradas: ${snapshot.docs.length}');

  //     return snapshot.docs
  //         .map((doc) => Avaliacao.fromMap(
  //               doc.id,
  //               doc.data() as Map<String, dynamic>,
  //             ))
  //         .toList();
  //   } catch (e) {
  //     print('❌ Erro ao buscar avaliações: $e');
  //     return [];
  //   }
  // }
  Future<List<Avaliacao>> buscarAvaliacoesPorFilial(
    String idFilial, {
    DateTime? dataInicial,
    DateTime? dataFinal,
  }) async {
    print('🔍 Buscando avaliações para filial: $idFilial');

    Query query = _firestore
        .collection('avaliacoes')
        .where('id_filial', isEqualTo: idFilial);

    if (dataInicial != null) {
      query = query.where(
        'data_hora_resposta',
        isGreaterThanOrEqualTo: Timestamp.fromDate(dataInicial),
      );
    }

    if (dataFinal != null) {
      query = query.where(
        'data_hora_resposta',
        isLessThan: Timestamp.fromDate(
          DateTime(dataFinal.year, dataFinal.month, dataFinal.day + 1),
        ),
      );
    }

    query = query.orderBy('data_hora_resposta', descending: true);

    final snapshot = await query.get(); // se faltar índice, lança aqui

    print('✅ Avaliações encontradas: ${snapshot.docs.length}');

    return snapshot.docs
        .map((doc) =>
            Avaliacao.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList();
  }

  /// Busca avaliações de uma filial com filtro de data
  Future<List<Avaliacao>> buscarAvaliacoesPorFilialEData(
    String idFilial,
    DateTime dataInicio,
    DateTime dataFim,
  ) async {
    try {
      print(
          '🔍 Buscando avaliações para filial: $idFilial entre $dataInicio e $dataFim');

      final snapshot = await _firestore.collection('avaliacoes').get();

      final avaliacoesFiltradas = snapshot.docs.where((doc) {
        final data = doc.data();
        final idFilialDoc = data['id_filial']?.toString() ?? '';

        if (idFilialDoc != idFilial) return false;

        final dataHora = data['data_hora_resposta'];
        DateTime dateTime =
            dataHora is Timestamp ? dataHora.toDate() : DateTime.now();

        return dateTime.isAfter(dataInicio) && dateTime.isBefore(dataFim);
      }).toList();

      print('✅ Avaliações encontradas: ${avaliacoesFiltradas.length}');

      return avaliacoesFiltradas.map((doc) {
        return Avaliacao.fromMap(doc.id, doc.data());
      }).toList();
    } catch (e) {
      print('❌ Erro ao buscar avaliações com filtro de data: $e');
      return [];
    }
  }

  /// Busca avaliações em tempo real (stream)
  Stream<List<Avaliacao>> buscarAvaliacoesPorFilialStream(String idFilial) {
    print('🔄 Iniciando stream de avaliações para filial: $idFilial');

    return _firestore.collection('avaliacoes').snapshots().map((snapshot) {
      print('📊 Stream atualizado com ${snapshot.docs.length} documentos');

      final avaliacoesFiltradas = snapshot.docs.where((doc) {
        final idFilialDoc = doc.data()['id_filial']?.toString() ?? '';
        return idFilialDoc == idFilial;
      }).toList();

      print('✅ Avaliações filtradas: ${avaliacoesFiltradas.length}');

      return avaliacoesFiltradas.map((doc) {
        return Avaliacao.fromMap(doc.id, doc.data());
      }).toList();
    }).handleError((error) {
      print('❌ Erro no stream: $error');
    });
  }

  /// Busca stream de filiais
  Stream<List<Filial>> buscarFiliaisStream() {
    return _firestore.collection('Filial').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Filial.fromMap({
          ...doc.data(),
          'id': doc.id,
        });
      }).toList();
    });
  }

  /// Salva uma avaliação (para testes ou novas avaliações)
  Future<String> salvarAvaliacao(Avaliacao avaliacao) async {
    try {
      print('💾 Salvando avaliação...');
      final docRef = await _firestore.collection('avaliacoes').add(
            avaliacao.toMap(),
          );
      print('✅ Avaliação salva com ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Erro ao salvar avaliação: $e');
      rethrow;
    }
  }

  /// Atualiza uma avaliação existente
  Future<void> atualizarAvaliacao(String docId, Avaliacao avaliacao) async {
    try {
      print('✏️ Atualizando avaliação: $docId');
      await _firestore.collection('avaliacoes').doc(docId).update(
            avaliacao.toMap(),
          );
      print('✅ Avaliação atualizada');
    } catch (e) {
      print('❌ Erro ao atualizar avaliação: $e');
      rethrow;
    }
  }

  /// Deleta uma avaliação
  Future<void> deletarAvaliacao(String docId) async {
    try {
      print('🗑️ Deletando avaliação: $docId');
      await _firestore.collection('avaliacoes').doc(docId).delete();
      print('✅ Avaliação deletada');
    } catch (e) {
      print('❌ Erro ao deletar avaliação: $e');
      rethrow;
    }
  }

  /// Busca comentários não vazios de uma filial
  Future<List<String>> buscarComentariosPorFilial(String idFilial) async {
    try {
      final avaliacoes = await buscarAvaliacoesPorFilial(idFilial);
      return avaliacoes
          .where((a) => a.comentarios.isNotEmpty)
          .map((a) => a.comentarios)
          .toList();
    } catch (e) {
      print('❌ Erro ao buscar comentários: $e');
      return [];
    }
  }

  /// Calcula estatísticas de uma filial
  // Future<EstatisticasFilial> calcularEstatisticasFilial(
  //   String filialId,
  //   String filialNome,
  // ) async {
  // Future<EstatisticasFilial> calcularEstatisticasFilial(
  //   String filialId,
  //   String filialNome, {
  //   DateTime? dataInicial,
  //   DateTime? dataFinal,
  // }) async {
  //   try {
  //     print('📈 Calculando estatísticas para: $filialNome');
  //     // final avaliacoes = await buscarAvaliacoesPorFilial(filialId);
  //     final avaliacoes = await buscarAvaliacoesPorFilial(
  //       filialId,
  //       dataInicial: dataInicial,
  //       dataFinal: dataFinal,
  //     );
  //     print('   Total de avaliações: ${avaliacoes.length}');

  //     final stats =
  //         EstatisticasFilial.fromAvaliacoes(filialId, filialNome, avaliacoes);

  //     print('   Média Geral: ${stats.mediaSatisfacaoGeral}');
  //     print('✅ Estatísticas calculadas');

  //     return stats;
  //   } catch (e) {
  //     print('❌ Erro ao calcular estatísticas: $e');
  //     return EstatisticasFilial(
  //       filialId: filialId,
  //       filialNome: filialNome,
  //       totalAvaliacoes: 0,
  //       mediaSabor: 0.0,
  //       mediaQualidadeProdutos: 0.0,
  //       mediaTemperatura: 0.0,
  //       mediaVariedadeProdutos: 0.0,
  //       mediaCaixaAtendimento: 0.0,
  //       mediaSatisfacaoGeral: 0.0,
  //       avaliacoes: [],
  //     );
  //   }
  // }
  Future<EstatisticasFilial> calcularEstatisticasFilial(
    String filialId,
    String filialNome, {
    DateTime? dataInicial,
    DateTime? dataFinal,
  }) async {
    print('📈 Calculando estatísticas para: $filialNome');
    final avaliacoes = await buscarAvaliacoesPorFilial(
      filialId,
      dataInicial: dataInicial,
      dataFinal: dataFinal,
    );
    print('   Total de avaliações: ${avaliacoes.length}');

    final stats =
        EstatisticasFilial.fromAvaliacoes(filialId, filialNome, avaliacoes);

    print('   Média Geral: ${stats.mediaSatisfacaoGeral}');
    print('✅ Estatísticas calculadas');

    return stats;
    // removi o try/catch — deixa o erro subir para quem chamou (HomeScreen),
    // que já sabe tratar e mostrar mensagem
  }

  /// Busca avaliações agrupadas por data para gráfico de linha
  Future<Map<String, double>> buscarMediasPorData(String idFilial) async {
    try {
      print('📅 Buscando médias por data para: $idFilial');
      final avaliacoes = await buscarAvaliacoesPorFilial(idFilial);
      final Map<String, List<double>> mediasPorDia = {};

      for (final avaliacao in avaliacoes) {
        final data = avaliacao.dataHoraResposta;
        final chave =
            '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}';

        if (!mediasPorDia.containsKey(chave)) {
          mediasPorDia[chave] = [];
        }

        mediasPorDia[chave]!.add(avaliacao.avaliacoes.satisfacaoGeralDouble);
      }

      // Calcular média por dia
      final Map<String, double> resultado = {};
      mediasPorDia.forEach((data, valores) {
        resultado[data] = valores.reduce((a, b) => a + b) / valores.length;
      });

      print('✅ Médias por data calculadas: ${resultado.length} dias');
      return resultado;
    } catch (e) {
      print('❌ Erro ao buscar médias por data: $e');
      return {};
    }
  }

  /// Função de debug para verificar estrutura de dados
  Future<void> debugAvaliacoes(String idFilial) async {
    try {
      print('\n🔍 ===== DEBUG AVALIAÇÕES =====');
      print('Filial ID: $idFilial\n');

      final snapshot = await _firestore.collection('avaliacoes').get();

      print('Total de documentos: ${snapshot.docs.length}\n');

      for (var doc in snapshot.docs) {
        final data = doc.data();
        print('Documento ID: ${doc.id}');
        print(
            'id_filial: ${data['id_filial']} (tipo: ${data['id_filial'].runtimeType})');
        print(
            'data_hora_resposta: ${data['data_hora_resposta']} (tipo: ${data['data_hora_resposta'].runtimeType})');
        print('usuario_id: ${data['usuario_id']}');
        print('avaliacoes: ${data['avaliacoes']}');
        print('comentarios: ${data['comentarios']}');
        print('---');
      }

      print('===== FIM DEBUG =====\n');
    } catch (e) {
      print('❌ Erro no debug: $e');
    }
  }
}
