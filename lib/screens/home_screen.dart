// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:webapp_pesquisa_avalicao_dashboard/model/user_model.dart';

// class HomeScreen extends StatefulWidget {
//   final User? loggedInUser;
//   final String? loggedInUserName;
//   const HomeScreen({Key? key, this.loggedInUser, this.loggedInUserName})
//       : assert(
//           loggedInUser != null || loggedInUserName != null,
//           'Deve passar loggedInUser ou loggedInUserName',
//         ),
//         super(key: key);
//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         // const Placeholder(),
//       ],
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:webapp_pesquisa_avalicao_dashboard/model/avaliacoes_model.dart';
import 'package:webapp_pesquisa_avalicao_dashboard/model/user_model.dart';
import 'package:webapp_pesquisa_avalicao_dashboard/services/firebase_service.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  final User loggedInUser;

  const HomeScreen({
    Key? key,
    required this.loggedInUser,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  List<Filial> filiais = [];
  Filial? filialSelecionada;
  EstatisticasFilial? estatisticas;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _carregarFiliais();
  }

  /// Carrega a lista de filiais
  void _carregarFiliais() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final filiaisBuscadas = await _firebaseService.buscarFiliais();
      setState(() {
        filiais = filiaisBuscadas;
        if (filiais.isNotEmpty) {
          filialSelecionada = filiais.first;
          _carregarEstatisticas(filialSelecionada!.id);
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar filiais: $e';
        _isLoading = false;
      });
    }
  }

  /// Carrega estatísticas de uma filial específica
  void _carregarEstatisticas(String filialId) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final filial = filiais.firstWhere((f) => f.id == filialId);
      final stats = await _firebaseService.calcularEstatisticasFilial(
        filialId,
        filial.filial,
      );

      setState(() {
        estatisticas = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar estatísticas: $e';
        _isLoading = false;
      });
    }
  }

  /// Muda a filial selecionada
  void _selecionarFilial(Filial filial) {
    setState(() {
      filialSelecionada = filial;
    });
    _carregarEstatisticas(filial.id);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final isTablet = MediaQuery.of(context).size.width >= 768 &&
        MediaQuery.of(context).size.width < 1024;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: _buildAppBar(),
      drawer: isMobile ? _buildDrawer() : null,
      body: _isLoading && estatisticas == null
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Seção de seleção de filiais
                  if (!isMobile) _buildFiliaisSelector(),
                  if (isMobile) const SizedBox(height: 0),

                  // Conteúdo principal
                  if (estatisticas != null)
                    Padding(
                      padding: EdgeInsets.all(isMobile
                          ? 16
                          : isTablet
                              ? 20
                              : 24),
                      child: Column(
                        children: [
                          // Título da filial
                          _buildFilialTitle(),
                          const SizedBox(height: 24),

                          // Indicador de satisfação geral
                          _buildSatisfacaoGeralCard(),
                          const SizedBox(height: 24),

                          // Grid de métricas
                          isMobile
                              ? _buildMetricasGridMobile()
                              : isTablet
                                  ? _buildMetricasGridTablet()
                                  : _buildMetricasGridDesktop(),
                          const SizedBox(height: 32),

                          // Gráfico de barras
                          _buildGraficoBarras(),
                          const SizedBox(height: 32),

                          // Gráfico de linha (evolução)
                          _buildGraficoLinha(),
                          const SizedBox(height: 32),

                          // Seção de comentários
                          _buildComentariosSection(),
                          const SizedBox(height: 32),
                        ],
                      ),
                    )
                  else
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          _errorMessage ?? 'Nenhuma filial disponível',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  /// Constrói a AppBar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryRed,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.dashboard, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dashboard de Avaliações',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
              ),
              Text(
                'Análise de satisfação das filiais',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textLight,
                    ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        // Seletor de filiais para desktop
        if (MediaQuery.of(context).size.width >= 768)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: DropdownButton<Filial>(
              value: filialSelecionada,
              items: filiais.map((filial) {
                return DropdownMenuItem(
                  value: filial,
                  child: Text(filial.filial),
                );
              }).toList(),
              onChanged: (filial) {
                if (filial != null) {
                  _selecionarFilial(filial);
                }
              },
              style: Theme.of(context).textTheme.bodyMedium,
              underline: Container(
                height: 2,
                color: AppTheme.primaryRed,
              ),
            ),
          ),
        // Botão de usuário
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Center(
            child: Tooltip(
              message: widget.loggedInUser.name,
              child: CircleAvatar(
                backgroundColor: AppTheme.primaryRed,
                child: Text(
                  widget.loggedInUser.name.isNotEmpty
                      ? widget.loggedInUser.name[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Constrói o drawer para mobile
  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: AppTheme.primaryRed,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Text(
                    widget.loggedInUser.name.isNotEmpty
                        ? widget.loggedInUser.name[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      color: AppTheme.primaryRed,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.loggedInUser.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  widget.loggedInUser.email,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Selecione uma Filial',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          ...filiais.map((filial) {
            final isSelected = filialSelecionada?.id == filial.id;
            return ListTile(
              title: Text(
                filial.filial,
                style: TextStyle(
                  color: isSelected ? AppTheme.primaryRed : null,
                ),
              ),
              selected: isSelected,
              selectedTileColor: AppTheme.primaryRed.withOpacity(0.1),
              leading: Icon(
                Icons.store,
                color: isSelected ? AppTheme.primaryRed : null,
              ),
              onTap: () {
                _selecionarFilial(filial);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ],
      ),
    );
  }

  /// Constrói o seletor de filiais para desktop
  Widget _buildFiliaisSelector() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Text(
              'Filiais:',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(width: 16),
            ...filiais.map((filial) {
              final isSelected = filialSelecionada?.id == filial.id;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: FilterChip(
                  label: Text(filial.filial),
                  selected: isSelected,
                  onSelected: (_) {
                    _selecionarFilial(filial);
                  },
                  backgroundColor: Colors.grey[100],
                  selectedColor: AppTheme.primaryRed.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: isSelected ? AppTheme.primaryRed : AppTheme.textDark,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  /// Constrói o título da filial
  Widget _buildFilialTitle() {
    if (estatisticas == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.store,
              color: AppTheme.primaryRed,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    estatisticas!.filialNome,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                  ),
                  Text(
                    '${estatisticas!.totalAvaliacoes} avaliações',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textLight,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Constrói o card de satisfação geral
  Widget _buildSatisfacaoGeralCard() {
    if (estatisticas == null) return const SizedBox.shrink();

    final media = estatisticas!.mediaSatisfacaoGeral;
    final cor = _getCorPorMedia(media);
    final percentual = (media / 5.0) * 100;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cor.withOpacity(0.1),
            cor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cor.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: cor.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Satisfação Geral',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      media.toStringAsFixed(1),
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: cor,
                          ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '/ 5.0',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textLight,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: media / 5.0,
                    minHeight: 8,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(cor),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Column(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cor.withOpacity(0.1),
                  border: Border.all(
                    color: cor,
                    width: 3,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${percentual.toStringAsFixed(0)}%',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: cor,
                                ),
                      ),
                      Text(
                        'Satisfação',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cor,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Constrói o grid de métricas para mobile
  Widget _buildMetricasGridMobile() {
    if (estatisticas == null) return const SizedBox.shrink();

    return Column(
      children: [
        _buildMetricCard(
          'Sabor',
          estatisticas!.mediaSabor,
          Icons.restaurant,
        ),
        const SizedBox(height: 16),
        _buildMetricCard(
          'Qualidade',
          estatisticas!.mediaQualidadeProdutos,
          Icons.star,
        ),
        const SizedBox(height: 16),
        _buildMetricCard(
          'Temperatura',
          estatisticas!.mediaTemperatura,
          Icons.thermostat,
        ),
        const SizedBox(height: 16),
        _buildMetricCard(
          'Variedade',
          estatisticas!.mediaVariedadeProdutos,
          Icons.menu,
        ),
        const SizedBox(height: 16),
        _buildMetricCard(
          'Atendimento',
          estatisticas!.mediaCaixaAtendimento,
          Icons.people,
        ),
      ],
    );
  }

  /// Constrói o grid de métricas para tablet
  Widget _buildMetricasGridTablet() {
    if (estatisticas == null) return const SizedBox.shrink();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Sabor',
                estatisticas!.mediaSabor,
                Icons.restaurant,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMetricCard(
                'Qualidade',
                estatisticas!.mediaQualidadeProdutos,
                Icons.star,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Temperatura',
                estatisticas!.mediaTemperatura,
                Icons.thermostat,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMetricCard(
                'Variedade',
                estatisticas!.mediaVariedadeProdutos,
                Icons.menu,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Atendimento',
                estatisticas!.mediaCaixaAtendimento,
                Icons.people,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(),
            ),
          ],
        ),
      ],
    );
  }

  /// Constrói o grid de métricas para desktop
  Widget _buildMetricasGridDesktop() {
    if (estatisticas == null) return const SizedBox.shrink();

    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            'Sabor',
            estatisticas!.mediaSabor,
            Icons.restaurant,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            'Qualidade',
            estatisticas!.mediaQualidadeProdutos,
            Icons.star,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            'Temperatura',
            estatisticas!.mediaTemperatura,
            Icons.thermostat,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            'Variedade',
            estatisticas!.mediaVariedadeProdutos,
            Icons.menu,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            'Atendimento',
            estatisticas!.mediaCaixaAtendimento,
            Icons.people,
          ),
        ),
      ],
    );
  }

  /// Constrói um card de métrica individual
  Widget _buildMetricCard(String titulo, double valor, IconData icone) {
    final cor = _getCorPorMedia(valor);
    final percentual = (valor / 5.0) * 100;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                titulo,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icone,
                  color: cor,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                valor.toStringAsFixed(1),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cor,
                    ),
              ),
              const SizedBox(width: 4),
              Text(
                '/ 5',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textLight,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: valor / 5.0,
              minHeight: 6,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(cor),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${percentual.toStringAsFixed(0)}% de satisfação',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textLight,
                ),
          ),
        ],
      ),
    );
  }

  /// Constrói o gráfico de barras
  Widget _buildGraficoBarras() {
    if (estatisticas == null) return const SizedBox.shrink();

    final criterios = EstatisticasFilial.nomeCriterios;
    final medias = [
      estatisticas!.mediaSabor,
      estatisticas!.mediaQualidadeProdutos,
      estatisticas!.mediaTemperatura,
      estatisticas!.mediaVariedadeProdutos,
      estatisticas!.mediaCaixaAtendimento,
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Média por Critério',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
          ),
          const SizedBox(height: 20),
          ...List.generate(criterios.length, (index) {
            final criterio = criterios[index];
            final media = medias[index];
            final cor = _getCorPorMedia(media);

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        criterio,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textDark,
                            ),
                      ),
                      Text(
                        media.toStringAsFixed(1),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: cor,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: media / 5.0,
                      minHeight: 12,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(cor),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Constrói o gráfico de linha (evolução)
  Widget _buildGraficoLinha() {
    if (estatisticas == null) return const SizedBox.shrink();

    // Agrupar avaliações por data
    final Map<String, List<double>> avaliacoesPorData = {};

    for (final avaliacao in estatisticas!.avaliacoes) {
      final data = avaliacao.dataHoraResposta;
      final chave =
          '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}';

      if (!avaliacoesPorData.containsKey(chave)) {
        avaliacoesPorData[chave] = [];
      }

      avaliacoesPorData[chave]!.add(avaliacao.avaliacoes.satisfacaoGeralDouble);
    }

    // Calcular médias por data
    final Map<String, double> mediasPorData = {};
    avaliacoesPorData.forEach((data, valores) {
      mediasPorData[data] = valores.reduce((a, b) => a + b) / valores.length;
    });

    // Ordenar por data
    final datasOrdenadas = mediasPorData.keys.toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Evolução da Satisfação',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
          ),
          const SizedBox(height: 20),
          if (datasOrdenadas.isNotEmpty)
            SizedBox(
              height: 200,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(datasOrdenadas.length, (index) {
                    final data = datasOrdenadas[index];
                    final media = mediasPorData[data]!;
                    final altura = (media / 5.0) * 150;
                    final cor = _getCorPorMedia(media);

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            media.toStringAsFixed(1),
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: cor,
                                    ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 40,
                            height: altura,
                            decoration: BoxDecoration(
                              color: cor,
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: [
                                BoxShadow(
                                  color: cor.withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            data,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.textLight,
                                    ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            )
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'Sem dados de evolução',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textLight,
                      ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Constrói a seção de comentários
  Widget _buildComentariosSection() {
    if (estatisticas == null) return const SizedBox.shrink();

    final comentarios = estatisticas!.avaliacoes
        .where((a) => a.comentarios.isNotEmpty)
        .map((a) => (
              comentario: a.comentarios,
              data: a.dataHoraResposta,
              usuario: a.usuarioId,
            ))
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Comentários dos Clientes',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${comentarios.length}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryRed,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (comentarios.isNotEmpty)
            Column(
              children: List.generate(
                comentarios.length,
                (index) {
                  final item = comentarios[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildComentarioCard(
                      item.comentario,
                      item.data,
                      item.usuario,
                    ),
                  );
                },
              ),
            )
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'Nenhum comentário disponível',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textLight,
                      ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Constrói um card de comentário
  Widget _buildComentarioCard(
      String comentario, DateTime data, String usuario) {
    final dataFormatada = DateFormat('dd/MM/yyyy HH:mm').format(data);

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppTheme.primaryRed.withOpacity(0.2),
                    child: Text(
                      usuario.isNotEmpty ? usuario[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        color: AppTheme.primaryRed,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        usuario,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                      ),
                      Text(
                        dataFormatada,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textLight,
                              fontSize: 11,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
              Icon(
                Icons.message,
                color: AppTheme.primaryRed.withOpacity(0.5),
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            comentario,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textDark,
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }

  /// Retorna a cor baseada na média
  Color _getCorPorMedia(double media) {
    if (media >= 4.0) return Colors.green;
    if (media >= 3.0) return Colors.amber;
    return Colors.red;
  }
}
