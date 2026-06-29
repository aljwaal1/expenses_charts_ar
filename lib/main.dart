import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const App());

const appTitle = 'مصاريفي';
const appVersion = 'V4';
const seed = Color(0xFF0F766E);

class RowItem {
  final String title;
  final double value;
  final bool income;
  final String category;
  final DateTime date;
  const RowItem(this.title, this.value, this.income, this.category, this.date);
  String encode() => [title, value.toString(), income ? '1' : '0', category, date.toIso8601String()].join('|||');
  static RowItem decode(String raw) { final p = raw.split('|||'); return RowItem(p.isNotEmpty ? p[0] : 'عملية', p.length > 1 ? double.tryParse(p[1]) ?? 0 : 0, p.length > 2 ? p[2] == '1' : false, p.length > 3 ? p[3] : 'عام', p.length > 4 ? DateTime.tryParse(p[4]) ?? DateTime.now() : DateTime.now()); }
}

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: appTitle,
    locale: const Locale('ar'),
    supportedLocales: const [Locale('ar')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: seed), scaffoldBackgroundColor: const Color(0xFFECFDF5), fontFamily: 'Arial'),
    home: const Directionality(textDirection: TextDirection.rtl, child: Home()),
  );
}

class Home extends StatefulWidget { const Home({super.key}); @override State<Home> createState() => _HomeState(); }

class _HomeState extends State<Home> {
  int tab = 0;
  bool income = false;
  String category = 'عام';
  final title = TextEditingController();
  final amount = TextEditingController();
  final search = TextEditingController();
  List<RowItem> rows = [];

  @override void initState() { super.initState(); load(); }
  Future<void> load() async { final p = await SharedPreferences.getInstance(); final saved = p.getStringList('expenses_v4') ?? p.getStringList('expenses_v3') ?? []; setState(() => rows = saved.map(RowItem.decode).toList()); }
  Future<void> save() async { final p = await SharedPreferences.getInstance(); await p.setStringList('expenses_v4', rows.map((e) => e.encode()).toList()); }

  double get inc => rows.where((e) => e.income).fold(0, (s, e) => s + e.value);
  double get out => rows.where((e) => !e.income).fold(0, (s, e) => s + e.value);
  double get net => inc - out;
  List<RowItem> get visible { final q = search.text.trim(); return q.isEmpty ? rows : rows.where((e) => e.title.contains(q) || e.category.contains(q)).toList(); }

  void add() { final v = double.tryParse(amount.text.trim()) ?? 0; final t = title.text.trim(); if (v <= 0) return; setState(() { rows.insert(0, RowItem(t.isEmpty ? 'عملية' : t, v, income, category, DateTime.now())); title.clear(); amount.clear(); }); save(); SystemSound.play(SystemSoundType.click); }
  void remove(RowItem item) { final i = rows.indexOf(item); setState(() => rows.remove(item)); save(); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('تم حذف العملية'), action: SnackBarAction(label: 'تراجع', onPressed: () { setState(() => rows.insert(i < 0 ? 0 : i, item)); save(); }))); }
  void copyReport() { final text = StringBuffer()..writeln('$appTitle $appVersion')..writeln('الدخل: ${inc.toStringAsFixed(2)}')..writeln('المصروف: ${out.toStringAsFixed(2)}')..writeln('الصافي: ${net.toStringAsFixed(2)}')..writeln('---'); for (final e in rows) { text.writeln('${e.title} | ${e.income ? 'دخل' : 'مصروف'} | ${e.category} | ${e.value.toStringAsFixed(2)}'); } Clipboard.setData(ClipboardData(text: text.toString())); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ التقرير'))); }

  @override Widget build(BuildContext context) { final pages = [dashboard(), formPage(), report(), about()]; return Scaffold(body: SafeArea(child: AnimatedSwitcher(duration: const Duration(milliseconds: 220), child: pages[tab])), bottomNavigationBar: NavigationBar(selectedIndex: tab, onDestinationSelected: (v) => setState(() => tab = v), destinations: const [NavigationDestination(icon: Icon(Icons.home_rounded), label: 'الرئيسية'), NavigationDestination(icon: Icon(Icons.add_rounded), label: 'إضافة'), NavigationDestination(icon: Icon(Icons.bar_chart_rounded), label: 'التقرير'), NavigationDestination(icon: Icon(Icons.info_rounded), label: 'عن')]),); }

  Widget dashboard() => ListView(padding: const EdgeInsets.all(16), children: [hero(), const SizedBox(height: 12), Row(children: [Expanded(child: stat('دخل', inc, Icons.trending_up_rounded)), const SizedBox(width: 10), Expanded(child: stat('مصروف', out, Icons.trending_down_rounded))]), const SizedBox(height: 12), chart(), const SizedBox(height: 12), formCard(), const SizedBox(height: 12), header('آخر العمليات'), if (rows.isEmpty) card(const Center(child: Text('لا توجد عمليات بعد'))), ...rows.take(4).map(tile)]);
  Widget formPage() => ListView(padding: const EdgeInsets.all(16), children: [header('إضافة حركة'), formCard()]);
  Widget report() => ListView(padding: const EdgeInsets.all(16), children: [header('التقرير'), card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('ملخص سريع', style: TextStyle(fontWeight: FontWeight.w900)), const SizedBox(height: 8), Text('الصافي: ${net.toStringAsFixed(2)}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)), const SizedBox(height: 8), LinearProgressIndicator(value: inc == 0 ? 0 : (out / inc).clamp(0, 1), minHeight: 10, borderRadius: BorderRadius.circular(20))])), const SizedBox(height: 12), FilledButton.icon(onPressed: copyReport, icon: const Icon(Icons.copy_all_rounded), label: const Text('نسخ التقرير')), const SizedBox(height: 12), TextField(controller: search, onChanged: (_) => setState(() {}), decoration: input('بحث في العمليات', Icons.search_rounded)), const SizedBox(height: 12), if (visible.isEmpty) card(const Center(child: Text('لا توجد عمليات'))), ...visible.map(tile)]);
  Widget about() => ListView(padding: const EdgeInsets.all(16), children: [header('عن التطبيق'), card(const Text('$appTitle V4\nتحسين بصري أهدأ، حفظ على V4 مع قراءة V3، تصنيفات، تقرير، بحث، وحذف مع تراجع.'))]);

  Widget hero() => Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF0F766E), Color(0xFF14B8A6)]), borderRadius: BorderRadius.circular(32), boxShadow: [BoxShadow(color: seed.withValues(alpha: .20), blurRadius: 28, offset: const Offset(0, 14))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('$appTitle V4', style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w900)), const SizedBox(height: 8), Text('الصافي: ${net.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900)), Text('${rows.length} حركة محفوظة', style: const TextStyle(color: Colors.white70))]));
  Widget chart() { final max = inc > out ? inc : out; return card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('مقارنة سريعة', style: TextStyle(fontWeight: FontWeight.w900)), const SizedBox(height: 10), bar('دخل', inc, max), const SizedBox(height: 8), bar('مصروف', out, max)])); }
  Widget bar(String t, double v, double max) => Row(children: [SizedBox(width: 62, child: Text(t)), Expanded(child: LinearProgressIndicator(value: max == 0 ? 0 : v / max, minHeight: 12, borderRadius: BorderRadius.circular(20))), const SizedBox(width: 8), Text(v.toStringAsFixed(0))]);
  Widget formCard() => card(Column(children: [TextField(controller: title, decoration: input('الوصف', Icons.edit_note_rounded)), const SizedBox(height: 8), TextField(controller: amount, keyboardType: TextInputType.number, decoration: input('المبلغ', Icons.payments_rounded)), const SizedBox(height: 8), DropdownButtonFormField<String>(value: category, decoration: input('التصنيف', Icons.category_rounded), items: ['عام', 'طعام', 'مواصلات', 'منزل', 'عمل', 'أخرى'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => setState(() => category = v ?? category)), const SizedBox(height: 10), SegmentedButton<bool>(segments: const [ButtonSegment(value: true, label: Text('دخل')), ButtonSegment(value: false, label: Text('مصروف'))], selected: {income}, onSelectionChanged: (s) => setState(() => income = s.first)), const SizedBox(height: 12), SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: add, icon: const Icon(Icons.save_rounded), label: const Text('حفظ')))]));
  Widget tile(RowItem r) => Padding(padding: const EdgeInsets.only(bottom: 10), child: card(ListTile(leading: CircleAvatar(child: Icon(r.income ? Icons.add_rounded : Icons.remove_rounded)), title: Text(r.title, style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text('${r.income ? 'دخل' : 'مصروف'} • ${r.category} • ${date(r.date)}'), trailing: Row(mainAxisSize: MainAxisSize.min, children: [Text(r.value.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.w900)), IconButton(onPressed: () => remove(r), icon: const Icon(Icons.delete_outline_rounded))]))));
  Widget stat(String t, double v, IconData icon) => card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: seed), const SizedBox(height: 8), Text(v.toStringAsFixed(2), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)), Text(t)]));
  Widget header(String t) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(t, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)));
  InputDecoration input(String label, IconData icon) => InputDecoration(labelText: label, prefixIcon: Icon(icon), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none));
  Widget card(Widget child) => Container(width: double.infinity, padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .045), blurRadius: 22, offset: const Offset(0, 10))]), child: child);
  String date(DateTime d) => '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
}
