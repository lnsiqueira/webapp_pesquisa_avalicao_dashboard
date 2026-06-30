import 'package:excel/excel.dart' as excel_lib;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:webapp_pesquisa_avalicao_dashboard/model/avaliacoes_model.dart';
import 'package:webapp_pesquisa_avalicao_dashboard/model/user_model.dart';
import 'package:webapp_pesquisa_avalicao_dashboard/services/firebase_service.dart';
import '../theme/app_theme.dart';
import 'dart:html' as html;

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
  // DateTime? dataInicial;
  // DateTime? dataFinal;
  DateTimeRange? periodoSelecionado;
  @override
  void initState() {
    super.initState();
    final hoje = DateTime.now();

    periodoSelecionado = DateTimeRange(
      start: DateTime(hoje.year, hoje.month, 1),
      end: DateTime(hoje.year, hoje.month + 1, 0),
    );

    _carregarFiliais();
  }

  void exportarEstatisticas(EstatisticasFilial estatisticas) {
    final excel = excel_lib.Excel.createExcel();

    // NÃO delete o Sheet1 aqui ainda

    // ===== Aba 1: Resumo =====
    final resumo = excel['Resumo'];

    resumo.appendRow([
      excel_lib.TextCellValue('Filial'),
      excel_lib.TextCellValue(estatisticas.filialNome),
    ]);
    resumo.appendRow([
      excel_lib.TextCellValue('Total de Avaliações'),
      excel_lib.IntCellValue(estatisticas.totalAvaliacoes),
    ]);
    resumo.appendRow([]);
    resumo.appendRow([
      excel_lib.TextCellValue('Métrica'),
      excel_lib.TextCellValue('Média'),
      excel_lib.TextCellValue('% Satisfação'),
    ]);

    void linhaMetrica(String nome, double valor) {
      resumo.appendRow([
        excel_lib.TextCellValue(nome),
        excel_lib.TextCellValue(valor.toStringAsFixed(2)),
        excel_lib.TextCellValue('${((valor / 3.0) * 100).toStringAsFixed(0)}%'),
      ]);
    }

    linhaMetrica('Satisfação Geral', estatisticas.mediaSatisfacaoGeral);
    linhaMetrica('Sabor', estatisticas.mediaSabor);
    linhaMetrica('Qualidade dos Produtos', estatisticas.mediaQualidadeProdutos);
    linhaMetrica('Variedade de Produtos', estatisticas.mediaVariedadeProdutos);
    linhaMetrica('Atendimento', estatisticas.mediaCaixaAtendimento);

    for (var col = 0; col < 3; col++) {
      final cell = resumo.cell(excel_lib.CellIndex.indexByColumnRow(
        columnIndex: col,
        rowIndex: 3,
      ));
      cell.cellStyle = excel_lib.CellStyle(bold: true);
    }

    // ===== Aba 2: Avaliações Detalhadas =====
    final detalhes = excel['Avaliações'];

    detalhes.appendRow([
      excel_lib.TextCellValue('Usuário'),
      excel_lib.TextCellValue('Data/Hora'),
      excel_lib.TextCellValue('Satisfação Geral'),
      excel_lib.TextCellValue('Sabor'),
      excel_lib.TextCellValue('Qualidade'),
      excel_lib.TextCellValue('Variedade'),
      excel_lib.TextCellValue('Atendimento'),
      excel_lib.TextCellValue('Comentário'),
    ]);

    for (var col = 0; col < 8; col++) {
      final cell = detalhes.cell(excel_lib.CellIndex.indexByColumnRow(
        columnIndex: col,
        rowIndex: 0,
      ));
      cell.cellStyle = excel_lib.CellStyle(bold: true);
    }

    for (final av in estatisticas.avaliacoes) {
      detalhes.appendRow([
        excel_lib.TextCellValue(av.usuarioId),
        excel_lib.TextCellValue(
            DateFormat('dd/MM/yyyy HH:mm').format(av.dataHoraResposta)),
        excel_lib.DoubleCellValue(av.avaliacoes.satisfacaoGeralDouble),
        excel_lib.DoubleCellValue(av.avaliacoes.saborDouble),
        excel_lib.DoubleCellValue(av.avaliacoes.qualidadeProdutosDouble),
        excel_lib.DoubleCellValue(av.avaliacoes.variedadeProdutosDouble),
        excel_lib.DoubleCellValue(av.avaliacoes.caixaAtendimentoDouble),
        excel_lib.TextCellValue(av.comentarios),
      ]);
    }

    // ✅ deleta o Sheet1 só agora, depois que Resumo/Avaliações já existem e têm conteúdo
    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    // ===== Gera os bytes e dispara o download =====
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
        // if (filiais.isNotEmpty) {
        //   filialSelecionada = filiais.first;
        //   _carregarEstatisticas(filialSelecionada!.id);
        // }
        if (filiais.isNotEmpty) {
          filialSelecionada = filiais.firstWhere(
            (f) => f.id == "1749930481153",
            orElse: () => filiais.first,
          );

          // _carregarEstatisticas(filialSelecionada!.id);
          _carregarEstatisticas(
            filialSelecionada!.id,
            dataInicial: periodoSelecionado!.start,
            dataFinal: periodoSelecionado!.end,
          );
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
  // void _carregarEstatisticas(String filialId) async {
  // _carregarEstatisticas(
  //   String filialId, {
  //   DateTime? dataInicial,
  //   DateTime? dataFinal,
  // }) async {
  //   setState(() {
  //     _isLoading = true;
  //     _errorMessage = null;
  //   });

  //   try {
  //     final filial = filiais.firstWhere((f) => f.id == filialId);
  //     final stats = await _firebaseService.calcularEstatisticasFilial(
  //       filialId,
  //       filial.filial,
  //       dataInicial: dataInicial,
  //       dataFinal: dataFinal,
  //     );
  //     // final stats = await _firebaseService.calcularEstatisticasFilial(
  //     //   filialId,
  //     //   filial.filial,
  //     // );

  //     setState(() {
  //       estatisticas = stats;
  //       _isLoading = false;
  //     });
  //   } catch (e) {
  //     setState(() {
  //       _errorMessage = 'Erro ao carregar estatísticas: $e';
  //       _isLoading = false;
  //     });
  //   }
  // }
  _carregarEstatisticas(
    String filialId, {
    DateTime? dataInicial,
    DateTime? dataFinal,
  }) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final filial = filiais.firstWhere((f) => f.id == filialId);
      final stats = await _firebaseService.calcularEstatisticasFilial(
        filialId,
        filial.filial,
        dataInicial: dataInicial,
        dataFinal: dataFinal,
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

      // mostra o erro mesmo que já existam dados antigos na tela
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage!)),
        );
      }
    }
  }

  /// Muda a filial selecionada
  void _selecionarFilial(Filial filial) {
    setState(() {
      filialSelecionada = filial;
    });
    // _carregarEstatisticas(filial.id);
    _carregarEstatisticas(
      filial.id,
      dataInicial: periodoSelecionado?.start,
      dataFinal: periodoSelecionado?.end,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isTablet = screenWidth >= 768 && screenWidth < 1024;
    final isDesktop = screenWidth >= 1024;

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
                  // Seção de seleção de filiais (desktop)
                  if (isDesktop) _buildFiliaisSelector(),

                  // Conteúdo principal
                  if (estatisticas != null)
                    Padding(
                      padding: EdgeInsets.all(isMobile
                          ? 16
                          : isTablet
                              ? 20
                              : 32),
                      child: Column(
                        children: [
                          // Título da filial
                          _buildFilialTitle(),
                          // const SizedBox(height: 24),

                          const SizedBox(height: 8),
                          _buildFiltroPeriodo(),

                          const SizedBox(height: 12),

                          // Satisfação Geral
                          _buildSatisfacaoGeralCard(),
                          const SizedBox(height: 16),

                          // Grid responsivo de cards
                          if (isMobile)
                            _buildMetricasGridMobile()
                          else if (isTablet)
                            _buildMetricasGridTablet()
                          else
                            _buildMetricasGridDesktop(),

                          const SizedBox(height: 32),

                          // Gráfico de barras (apenas desktop/tablet)
                          // if (isDesktop || isTablet) ...[
                          //   _buildGraficoBarras(),
                          //   const SizedBox(height: 32),
                          // ],

                          // Gráfico de linha (apenas desktop/tablet)
                          // if (isDesktop || isTablet) ...[
                          _buildGraficoLinha(),
                          const SizedBox(height: 32),
                          // ],

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

  /// ==================== LAYOUTS RESPONSIVOS ====================

  /// Grid para Mobile (MANTÉM ORIGINAL - 5 cards em coluna)
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
        // const SizedBox(height: 16),
        // _buildMetricCard(
        //   'Temperatura',
        //   estatisticas!.mediaTemperatura,
        //   Icons.thermostat,
        // ),
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

  /// Grid para Tablet (2 colunas)
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
            const SizedBox(width: 20),
            Expanded(
              child: _buildMetricCard(
                'Qualidade',
                estatisticas!.mediaQualidadeProdutos,
                Icons.star,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            // Expanded(
            //   child: _buildMetricCard(
            //     'Temperatura',
            //     estatisticas!.mediaTemperatura,
            //     Icons.thermostat,
            //   ),
            // ),
            // const SizedBox(width: 20),
            Expanded(
              child: _buildMetricCard(
                'Variedade',
                estatisticas!.mediaVariedadeProdutos,
                Icons.menu,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Atendimento',
                estatisticas!.mediaCaixaAtendimento,
                Icons.people,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: SizedBox.shrink(),
            ),
          ],
        ),
      ],
    );
  }

  /// Grid para Desktop (2 colunas, cards GRANDES e LIMPOS)
  Widget _buildMetricasGridDesktop() {
    if (estatisticas == null) return const SizedBox.shrink();

    return Column(
      children: [
        // Primeira linha
        Row(
          children: [
            Expanded(
              child: _buildMetricCardDesktop(
                  'Sabor', estatisticas!.mediaSabor, Icons.restaurant),
            ),
            const SizedBox(width: 28),
            Expanded(
              child: _buildMetricCardDesktop('Qualidade',
                  estatisticas!.mediaQualidadeProdutos, Icons.star),
            ),
          ],
        ),
        const SizedBox(height: 28),
        // Segunda linha
        Row(
          children: [
            // Expanded(
            //   child: _buildMetricCardDesktop('Temperatura',
            //       estatisticas!.mediaTemperatura, Icons.thermostat),
            // ),
            // const SizedBox(width: 28),
            Expanded(
              child: _buildMetricCardDesktop('Variedade',
                  estatisticas!.mediaVariedadeProdutos, Icons.menu),
            ),
          ],
        ),
        const SizedBox(height: 28),
        // Terceira linha
        Row(
          children: [
            Expanded(
              child: _buildMetricCardDesktop('Atendimento',
                  estatisticas!.mediaCaixaAtendimento, Icons.people),
            ),
            const SizedBox(width: 28),
            Expanded(
              child: SizedBox.shrink(),
            ),
          ],
        ),
      ],
    );
  }

  /// ==================== COMPONENTES ====================
  // Widget _buildFiltroPeriodo() {
  //   return Container(
  //     width: double.infinity,
  //     padding: const EdgeInsets.all(20),
  //     margin: const EdgeInsets.only(bottom: 24),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(16),
  //       border: Border.all(color: Colors.grey.shade300),
  //     ),
  //     child: SingleChildScrollView(
  //       scrollDirection: Axis.horizontal,
  //       child: Row(
  //         // spacing: 16,
  //         // runSpacing: 16,
  //         // crossAxisAlignment: WrapCrossAlignment.center,
  //         children: [
  //           const Text(
  //             "Período:",
  //             style: TextStyle(
  //               fontWeight: FontWeight.bold,
  //               fontSize: 16,
  //             ),
  //           ),
  //           SizedBox(width: 4),
  //           OutlinedButton.icon(
  //             icon: const Icon(
  //               Icons.calendar_today,
  //               color: Colors.orange,
  //             ),
  //             label: Text(
  //               dataInicial == null
  //                   ? "Data Inicial"
  //                   : DateFormat("dd/MM/yyyy").format(dataInicial!),
  //             ),
  //             onPressed: () async {
  //               final data = await showDatePicker(
  //                 context: context,
  //                 initialDate: dataInicial ?? DateTime.now(),
  //                 firstDate: DateTime(2024),
  //                 lastDate: DateTime(2035),
  //               );

  //               if (data != null) {
  //                 setState(() {
  //                   dataInicial = data;
  //                 });
  //               }
  //             },
  //           ),
  //           SizedBox(width: 4),
  //           OutlinedButton.icon(
  //             icon: const Icon(Icons.calendar_today, color: Colors.orange),
  //             label: Text(
  //               dataFinal == null
  //                   ? "Data Final"
  //                   : DateFormat("dd/MM/yyyy").format(dataFinal!),
  //             ),
  //             onPressed: () async {
  //               final data = await showDatePicker(
  //                 context: context,
  //                 initialDate: dataFinal ?? DateTime.now(),
  //                 firstDate: DateTime(2024),
  //                 lastDate: DateTime(2035),
  //               );

  //               if (data != null) {
  //                 setState(() {
  //                   dataFinal = data;
  //                 });
  //               }
  //             },
  //           ),
  //           SizedBox(width: 4),
  //           ElevatedButton.icon(
  //             icon: const Icon(Icons.search, color: Colors.white),
  //             label: const Text("Filtrar"),
  //             onPressed: () {
  //               if (filialSelecionada != null) {
  //                 // _carregarEstatisticas(filialSelecionada!.id);
  //                 _carregarEstatisticas(
  //                   filialSelecionada!.id,
  //                   dataInicial: dataInicial,
  //                   dataFinal: dataFinal,
  //                 );
  //               }
  //             },
  //           ),
  //           if (dataInicial != null || dataFinal != null)
  //             TextButton(
  //               child: const Text("Limpar"),
  //               onPressed: () {
  //                 setState(() {
  //                   dataInicial = null;
  //                   dataFinal = null;
  //                 });

  //                 _carregarEstatisticas(filialSelecionada!.id);
  //               },
  //             ),
  //         ],
  //       ),
  //     ),
  //   );
  // }
  Widget _buildFiltroPeriodo() {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        final novoPeriodo = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2024),
          lastDate: DateTime(2035),
          initialDateRange: periodoSelecionado,
        );

        if (novoPeriodo == null) return;

        setState(() {
          periodoSelecionado = novoPeriodo;
        });

        _carregarEstatisticas(
          filialSelecionada!.id,
          dataInicial: novoPeriodo.start,
          dataFinal: novoPeriodo.end,
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.date_range,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Período",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "${DateFormat('dd/MM/yyyy').format(periodoSelecionado!.start)}"
                    " até "
                    "${DateFormat('dd/MM/yyyy').format(periodoSelecionado!.end)}",
                  ),
                ],
              ),
            ),
            const Icon(Icons.edit_calendar)
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
                'Avaliações',
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
        if (MediaQuery.of(context).size.width >= 1024)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: DropdownButton<Filial>(
              value: filialSelecionada,
              items: filiais.map((filial) {
                return DropdownMenuItem(
                  value: filial,
                  // child: Text(filial.filial),
                  child: Text(
                    filial.filial,
                    style: TextStyle(
                      color: filial.id == "1749930481153"
                          ? Colors.black
                          : Colors.grey[400],
                    ),
                  ),
                );
              }).toList(),
              // onChanged: (filial) {
              //   if (filial != null) {
              //     _selecionarFilial(filial);
              //   }
              // },
              onChanged: (filial) {
                if (filial != null && filial.id == "1749930481153") {
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
            final isAtiva = filial.id ==
                "1749930481153"; // ← CORREÇÃO: Verificar cada filial

            return ListTile(
              title: Text(
                filial.filial,
                style: TextStyle(
                  color: isAtiva ? Colors.black : Colors.grey[400],
                ),
              ),
              selected: isSelected,
              selectedTileColor: AppTheme.primaryRed.withOpacity(0.1),
              leading: Icon(
                Icons.store,
                color: isSelected ? AppTheme.primaryRed : null,
              ),
              enabled: isAtiva,
              onTap: isAtiva
                  ? () {
                      _selecionarFilial(filial);
                      Navigator.pop(context);
                    }
                  : null,
              tileColor: isAtiva ? null : Colors.grey[100],
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildFiliaisSelector() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selecione uma Filial -',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          // 👇 Scroll horizontal em uma única linha
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: filiais.map((filial) {
                final isSelected = filialSelecionada?.id == filial.id;
                final isAtiva = filial.id ==
                    "1749930481153"; // ← CORREÇÃO: Verificar cada filial

                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: FilterChip(
                    label: Text(filial.filial),
                    selected: isSelected,
                    onSelected: isAtiva
                        ? (_) {
                            _selecionarFilial(filial);
                          }
                        : null,
                    backgroundColor:
                        isAtiva ? Colors.grey[100] : Colors.grey[300],
                    selectedColor: isAtiva
                        ? AppTheme.primaryRed.withOpacity(0.2)
                        : Colors.grey[300],
                    side: BorderSide(
                      color: isAtiva
                          ? (isSelected
                              ? AppTheme.primaryRed
                              : Colors.grey[300]!)
                          : Colors.grey[400]!,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói o título da filial (ORIGINAL)
  Widget _buildFilialTitle() {
    if (estatisticas == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.store,
                  color: AppTheme.primaryRed,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      estatisticas!.filialNome,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
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
              ],
            ),
            ElevatedButton.icon(
              onPressed: () {
                if (estatisticas == null) return;
                exportarEstatisticas(estatisticas!);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Excel gerado com sucesso!')),
                );
              },
              icon: const Icon(Icons.file_download, color: Colors.white),
              label: const Text('Exportar Excel'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Constrói o card de satisfação geral (ORIGINAL)
  Widget _buildSatisfacaoGeralCard() {
    if (estatisticas == null) return const SizedBox.shrink();

    final media = estatisticas!.mediaSatisfacaoGeral;
    final cor = _getCorPorMedia(media);
    final percentual = (media / 3.0) * 100;

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
                      '/ 3.0',
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
                    value: media / 3.0,
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

  /// Constrói um card de métrica individual (ORIGINAL - para mobile/tablet)
  Widget _buildMetricCard(String titulo, double valor, IconData icone) {
    final cor = _getCorPorMedia(valor);
    final percentual = (valor / 3.0) * 100;

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
                '/ 3',
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
              value: valor / 3.0,
              minHeight: 6,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(cor),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: cor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${percentual.toStringAsFixed(0)}% de satisfação',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cor,
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói um card de métrica GRANDE para desktop (NOVO DESIGN)
  Widget _buildMetricCardDesktop(String titulo, double valor, IconData icone) {
    final cor = _getCorPorMedia(valor);
    final percentual = (valor / 3.0) * 100;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                titulo,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icone, color: cor, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    valor.toStringAsFixed(1),
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: cor,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'de 3.0',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cor.withOpacity(0.1),
                  border: Border.all(color: cor, width: 3),
                ),
                child: Center(
                  child: Text(
                    '${percentual.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: cor,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 6,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: Colors.grey[200],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: valor / 3.0,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(cor),
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
        .toList();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(28),
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
                  style: TextStyle(
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
              children: comentarios.map((av) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              av.usuarioId,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Text(
                              DateFormat('dd/MM/yyyy HH:mm')
                                  .format(av.dataHoraResposta),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          av.comentarios,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            )
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Text(
                  'Nenhum comentário disponível',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[500],
                      ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGraficoLinha() {
    if (estatisticas == null || estatisticas!.avaliacoes.isEmpty) {
      return Container(
        width: double.infinity,
        height: 300,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!, width: 1),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Evolução das Avaliações',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Center(
                child: Text(
                  'Sem dados disponíveis',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[500],
                      ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Agrupar avaliações por data e calcular média
    final Map<String, List<double>> mediasPorDia = {};

    for (final avaliacao in estatisticas!.avaliacoes) {
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

    // Ordenar por data
    final datas = resultado.keys.toList();
    datas.sort((a, b) {
      final partsA = a.split('/');
      final partsB = b.split('/');
      final dataA = DateTime(2026, int.parse(partsA[1]), int.parse(partsA[0]));
      final dataB = DateTime(2026, int.parse(partsB[1]), int.parse(partsB[0]));
      return dataA.compareTo(dataB);
    });

    // Criar pontos para o gráfico
    final spots = <FlSpot>[];
    for (int i = 0; i < datas.length; i++) {
      spots.add(FlSpot(i.toDouble(), resultado[datas[i]]!));
    }

    // Se houver apenas 1 ponto, duplicar para mostrar linha
    if (spots.length == 1) {
      spots.add(FlSpot(1, spots[0].y));
      datas.add(datas[0]);
    }

    return Container(
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Evolução das Avaliações',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 1,
                  verticalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey[200],
                      strokeWidth: 1,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: Colors.grey[200],
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 0.5,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < datas.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              datas[index],
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toStringAsFixed(1),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.right,
                        );
                      },
                      reservedSize: 42,
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    left: BorderSide(color: Colors.grey[300]!, width: 1),
                    bottom: BorderSide(color: Colors.grey[300]!, width: 1),
                  ),
                ),
                minX: 0,
                maxX: (spots.length - 1).toDouble(),
                minY: 0,
                maxY: 3,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryRed,
                        AppTheme.primaryRed.withOpacity(0.7),
                      ],
                    ),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 5,
                          color: AppTheme.primaryRed,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryRed.withOpacity(0.3),
                          AppTheme.primaryRed.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  enabled: true,
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: AppTheme.primaryRed,
                    tooltipRoundedRadius: 8,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((touchedSpot) {
                        final index = touchedSpot.x.toInt();
                        final data = datas.length > index ? datas[index] : '';
                        return LineTooltipItem(
                          'Média: ${touchedSpot.y.toStringAsFixed(2)}\n$data',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // /// Retorna a cor baseada na média
  Color _getCorPorMedia(double media) {
    if (media >= 2.5) return Colors.green;
    if (media >= 1.8) return Colors.amber;
    return Colors.red;
  }
  // Color _getCorPorMedia(double media) {
  //   if (media >= 4.0) return Colors.green;
  //   if (media >= 3.0) return Colors.amber;
  //   return Colors.red;
  // }
}
