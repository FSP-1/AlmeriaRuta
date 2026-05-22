import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/operario_viewmodel.dart';
import 'widgets/operario_notice_tab.dart';
import 'widgets/operario_stops_tab.dart';
import 'widgets/operario_card_requests_tab.dart';

class OperarioPanelView extends StatefulWidget {
  const OperarioPanelView({super.key});

  @override
  State<OperarioPanelView> createState() => _OperarioPanelViewState();
}

class _OperarioPanelViewState extends State<OperarioPanelView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OperarioViewModel>().loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Operario'),
        elevation: 0,
        backgroundColor: const Color(0xFF0EA5E9),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              icon: Icon(Icons.campaign_outlined),
              text: 'Avisos',
            ),
            Tab(
              icon: Icon(Icons.bus_alert),
              text: 'Paradas',
            ),
            Tab(
              icon: Icon(Icons.credit_card_outlined),
              text: 'Solicitudes',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const OperarioNoticeTab(),
          const OperarioStopsTab(),
          const OperarioCardRequestsTab(),
        ],
      ),
    );
  }
}