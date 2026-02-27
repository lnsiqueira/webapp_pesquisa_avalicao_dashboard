import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:webapp_pesquisa_avalicao_dashboard/model/avaliacoes_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  Future<List<Avaliacao>> buscarAvaliacoesPorFilial(String idFilial) async {
    try {
      print('🔍 Buscando avaliações para filial: $idFilial');

      // Primeiro, buscar todos os documentos
      final snapshot = await _firestore.collection('avaliacoes').get();

      print('📊 Total de avaliações no Firestore: ${snapshot.docs.length}');

      // Filtrar manualmente por id_filial
      final avaliacoesFiltradas = snapshot.docs.where((doc) {
        final data = doc.data();
        final idFilialDoc = data['id_filial']?.toString() ?? '';
        print(
            '   Comparando: "$idFilialDoc" == "$idFilial" ? ${idFilialDoc == idFilial}');
        return idFilialDoc == idFilial;
      }).toList();

      print(
          '✅ Avaliações encontradas para filial: ${avaliacoesFiltradas.length}');

      // Ordenar por data
      avaliacoesFiltradas.sort((a, b) {
        final dataA = a.data()['data_hora_resposta'];
        final dataB = b.data()['data_hora_resposta'];

        DateTime dateTimeA =
            dataA is Timestamp ? dataA.toDate() : DateTime.now();
        DateTime dateTimeB =
            dataB is Timestamp ? dataB.toDate() : DateTime.now();

        return dateTimeB.compareTo(dateTimeA);
      });

      final avaliacoes = avaliacoesFiltradas.map((doc) {
        print('   📄 Avaliação: ${doc.data()}');
        return Avaliacao.fromMap(doc.id, doc.data());
      }).toList();

      return avaliacoes;
    } catch (e) {
      print('❌ Erro ao buscar avaliações: $e');
      return [];
    }
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
  Future<EstatisticasFilial> calcularEstatisticasFilial(
    String filialId,
    String filialNome,
  ) async {
    try {
      print('📈 Calculando estatísticas para: $filialNome');
      final avaliacoes = await buscarAvaliacoesPorFilial(filialId);
      print('   Total de avaliações: ${avaliacoes.length}');

      final stats =
          EstatisticasFilial.fromAvaliacoes(filialId, filialNome, avaliacoes);

      print('   Média Geral: ${stats.mediaSatisfacaoGeral}');
      print('✅ Estatísticas calculadas');

      return stats;
    } catch (e) {
      print('❌ Erro ao calcular estatísticas: $e');
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
        avaliacoes: [],
      );
    }
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
