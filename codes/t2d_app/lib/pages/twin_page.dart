import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'mimic_t2d_page.dart';
import 'nhanes_page.dart'; // class: NhpPage
import 'dfu_page.dart';
import 'dr_page.dart';

class TwinPage extends StatefulWidget {
  const TwinPage({super.key});
  @override
  State<TwinPage> createState() => _TwinPageState();
}

class _TwinPageState extends State<TwinPage> with TickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Digital Twin'),
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: const [
            Tab(text: 'MIMIC-IV'),
            Tab(text: 'NHANES'),
            Tab(text: 'DFU'),
            Tab(text: 'DR'),
          ],
        ),
        actions: [
          if (user?.email != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(child: Text(user!.email!, style: const TextStyle(fontSize: 13))),
            ),
          IconButton(
            tooltip: 'AI Consultation',
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () => context.push('/gemini'),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          MimicT2DPage(),
          NhpPage(),
          DfuPage(),
          DrPage(),
        ],
      ),
    );
  }
}
