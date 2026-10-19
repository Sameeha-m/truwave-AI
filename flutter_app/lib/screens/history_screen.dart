import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../database/verification_model.dart';
import '../widgets/shared_history_widgets.dart';
import 'home_screen.dart';
import 'verification_result_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _searchController = TextEditingController();
  late Future<List<Verification>> _history;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    _history = DatabaseHelper.instance.getVerifications();
  }

  Future<void> _openVerification(Verification verification) async {
    final id = verification.id;
    if (id == null) return;
    final sources = await DatabaseHelper.instance.getSources(id);
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => VerificationResultScreen(
          verification: verification,
          sources: sources,
        ),
      ),
    );
  }

  Future<void> _deleteVerification(Verification verification) async {
    if (verification.id == null) return;
    await DatabaseHelper.instance.deleteVerification(verification.id!);
    if (!mounted) return;
    setState(_loadHistory);
  }

  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear all history?'),
        content: const Text(
          'This will permanently delete all saved verifications.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear all'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await DatabaseHelper.instance.deleteAllVerifications();
    if (!mounted) return;
    setState(_loadHistory);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFD),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Back to Home',
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        Navigator.pushReplacement<void, void>(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const HomeScreen(),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const Expanded(
                    child: Text(
                      'History',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _clearHistory,
                    child: const Text('Clear all'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextField(
                controller: _searchController,
                onChanged: (value) =>
                    setState(() => _query = value.trim().toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Search claims...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<Verification>>(
                future: _history,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(child: Text('Could not load history.'));
                  }
                  final all = snapshot.data ?? [];
                  final verifications = all
                      .where(
                        (item) => item.claim.toLowerCase().contains(_query),
                      )
                      .toList();
                  if (verifications.isEmpty) {
                    return Center(
                      child: Text(
                        all.isEmpty
                            ? 'No saved verifications yet.'
                            : 'No claims match your search.',
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                    itemCount: verifications.length,
                    itemBuilder: (context, index) {
                      final verification = verifications[index];
                      return VerificationHistoryCard(
                        verification: verification,
                        showMetadata: true,
                        onTap: () => _openVerification(verification),
                        trailing: IconButton(
                          tooltip: 'Delete verification',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _deleteVerification(verification),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
