import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() => runApp(const App());

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFF0F766E)),
      home: const Directionality(textDirection: TextDirection.rtl, child: Home()),
    );
  }
}

class RowItem { final String title; final double value; final bool income; const RowItem(this.title, this.value, this.income); }

class Home extends StatefulWidget { const Home({super.key}); @override State<Home> createState() => _HomeState(); }
class _HomeState extends State<Home> {
  int tab = 0;
  final title = TextEditingController();
  final amount = TextEditingController();
  final rows = <RowItem>[];
  double get inc => rows.where((e) => e.income).fold(0, (s, e) => s + e.value);
  double get out => rows.where((e) => !e.income).fold(0, (s, e) => s + e.value);
  void add(bool income) { final v = double.tryParse(amount.text.trim()) ?? 0; final t = title.text.trim(); if (v <= 0) return; setState(() { rows.insert(0, RowItem(t.isEmpty ? 'عملية' : t, v, income)); title.clear(); amount.clear(); }); }
  @override Widget build(BuildContext context) { final pages = [dashboard(), formPage(), report(), about()]; return Scaffold(backgroundColor: const Color(0xFFEEF7F2), body: SafeArea(child: pages[tab]), bottomNavigationBar: NavigationBar(selectedIndex: tab, onDestinationSelected: (v) => setState(() => tab = v), destinations: const [NavigationDestination(icon: Icon(Icons.home_rounded), label: 'الرئيسية'), NavigationDestination(icon: Icon(Icons.add_rounded), label: 'إضافة'), NavigationDestination(icon: Icon(Icons.bar_chart_rounded), label: 'التقرير'), NavigationDestination(icon: Icon(Icons.info_rounded), label: 'عن')]),); }
  Widget dashboard() => ListView(padding: const EdgeInsets.all(16), children: [hero(), const SizedBox(height: 12), Row(children: [Expanded(child: stat('دخل', inc)), const SizedBox(width: 10), Expanded(child: stat('مصروف', out))]), const SizedBox(height: 12), formCard(), const SizedBox(height: 12), ...rows.take(4).map(tile)]);
  Widget formPage() => ListView(padding: const EdgeInsets.all(16), children: [header('إضافة حركة'), formCard()]);
  Widget report() => ListView(padding: const EdgeInsets.all(16), children: [header('التقرير'), card(Text('الصافي: ${(inc - out).toStringAsFixed(2)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900))), const SizedBox(height: 12), ...rows.map(tile)]);
  Widget about() => ListView(padding: const EdgeInsets.all(16), children: [header('عن التطبيق'), card(const Text('مصاريفي V2 - واجهة Material 3 مع إضافة دخل ومصروف وتقرير مختصر.'))]);
  Widget hero() => Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF0F766E), Color(0xFF14B8A6)]), borderRadius: BorderRadius.circular(28)), child: Text('الصافي: ${(inc - out).toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)));
  Widget formCard() => card(Column(children: [TextField(controller: title, decoration: const InputDecoration(labelText: 'الوصف')), TextField(controller: amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'المبلغ')), const SizedBox(height: 12), Row(children: [Expanded(child: FilledButton(onPressed: () => add(true), child: const Text('دخل'))), const SizedBox(width: 10), Expanded(child: OutlinedButton(onPressed: () => add(false), child: const Text('مصروف')))]) ]));
  Widget tile(RowItem r) => Padding(padding: const EdgeInsets.only(bottom: 10), child: card(ListTile(title: Text(r.title), subtitle: Text(r.income ? 'دخل' : 'مصروف'), trailing: Text(r.value.toStringAsFixed(2)))));
  Widget stat(String t, double v) => card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(v.toStringAsFixed(2), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)), Text(t)]));
  Widget header(String t) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(t, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)));
  Widget card(Widget child) => Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)), child: child);
}
