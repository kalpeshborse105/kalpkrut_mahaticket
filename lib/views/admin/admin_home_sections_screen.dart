import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/home_section_model.dart';
import '../../data/services/supabase_service.dart';

class AdminHomeSectionsScreen extends StatefulWidget {
  const AdminHomeSectionsScreen({super.key});

  @override
  State<AdminHomeSectionsScreen> createState() => _AdminHomeSectionsScreenState();
}

class _AdminHomeSectionsScreenState extends State<AdminHomeSectionsScreen> {
  final _supabase = SupabaseService();
  bool _loading = true;
  bool _saving = false;
  List<HomeSectionModel> _sections = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final rows = await _supabase.getHomeSections(visibleOnly: false);
    if (!mounted) return;
    setState(() {
      _sections = rows.isNotEmpty
          ? (List<HomeSectionModel>.from(rows)
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)))
          : [
              const HomeSectionModel(id: 0, sectionKey: 'hero', titleEn: 'Featured', titleMr: 'विशेष आकर्षण', sortOrder: 1),
              const HomeSectionModel(id: 0, sectionKey: 'trending', titleEn: 'Trending', titleMr: 'ट्रेंडिंग', sortOrder: 2),
              const HomeSectionModel(id: 0, sectionKey: 'categories', titleEn: 'Categories', titleMr: 'श्रेणी', sortOrder: 3),
              const HomeSectionModel(id: 0, sectionKey: 'today', titleEn: 'Today', titleMr: 'आजचे प्रयोग', sortOrder: 4),
              const HomeSectionModel(id: 0, sectionKey: 'promoted', titleEn: 'Promoted', titleMr: 'प्रमोटेड', sortOrder: 5),
              const HomeSectionModel(id: 0, sectionKey: 'drama', titleEn: 'Theatre', titleMr: 'नाटके', sortOrder: 6),
              const HomeSectionModel(id: 0, sectionKey: 'music', titleEn: 'Music', titleMr: 'संगीत', sortOrder: 7),
              const HomeSectionModel(id: 0, sectionKey: 'venues', titleEn: 'Venues', titleMr: 'नाट्यगृहे', sortOrder: 8),
            ];
      _loading = false;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final ok = await _supabase.upsertHomeSections(_sections);
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Home sections saved. Customer app will show updated titles/order.'
            : 'Save failed. Check home_sections table permissions.'),
      ),
    );
  }

  void _editSection(int index) {
    final s = _sections[index];
    final titleEn = TextEditingController(text: s.titleEn);
    final titleMr = TextEditingController(text: s.titleMr);
    final subtitleEn = TextEditingController(text: s.subtitleEn);
    final subtitleMr = TextEditingController(text: s.subtitleMr);
    final badgeEn = TextEditingController(text: s.badgeEn);
    final badgeMr = TextEditingController(text: s.badgeMr);
    final sortCtrl = TextEditingController(text: '${s.sortOrder}');
    var visible = s.isVisible;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            title: Text('Edit ${s.sectionKey}', style: const TextStyle(fontSize: 16)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: titleMr, decoration: const InputDecoration(labelText: 'Title (Marathi)')),
                  TextField(controller: titleEn, decoration: const InputDecoration(labelText: 'Title (English)')),
                  TextField(controller: subtitleMr, decoration: const InputDecoration(labelText: 'Subtitle (Marathi)')),
                  TextField(controller: subtitleEn, decoration: const InputDecoration(labelText: 'Subtitle (English)')),
                  TextField(controller: badgeMr, decoration: const InputDecoration(labelText: 'Badge (Marathi)')),
                  TextField(controller: badgeEn, decoration: const InputDecoration(labelText: 'Badge (English)')),
                  TextField(
                    controller: sortCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Sort order'),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Visible on home', style: TextStyle(color: Colors.white)),
                    value: visible,
                    onChanged: (v) => setLocal(() => visible = v),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _sections[index] = s.copyWith(
                      titleEn: titleEn.text.trim(),
                      titleMr: titleMr.text.trim(),
                      subtitleEn: subtitleEn.text.trim(),
                      subtitleMr: subtitleMr.text.trim(),
                      badgeEn: badgeEn.text.trim(),
                      badgeMr: badgeMr.text.trim(),
                      sortOrder: int.tryParse(sortCtrl.text.trim()) ?? s.sortOrder,
                      isVisible: visible,
                    );
                    _sections.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
                  });
                  Navigator.pop(ctx);
                },
                child: const Text('Apply'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('होम स्क्रीन सेक्शन्स (Home Sections)'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _sections.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final s = _sections[index];
                return Card(
                  color: AppColors.surface,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: s.isVisible ? AppColors.primary.withAlpha(40) : Colors.white10,
                      child: Text('${s.sortOrder}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    title: Text(s.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      '${s.sectionKey} • ${s.isVisible ? "Visible" : "Hidden"}\n${s.titleEn}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                    isThreeLine: true,
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, color: AppColors.gold),
                      onPressed: () => _editSection(index),
                    ),
                    onTap: () => _editSection(index),
                  ),
                );
              },
            ),
    );
  }
}
