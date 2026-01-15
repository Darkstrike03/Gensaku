import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'widgets/navigationpanel.dart';
import 'core/theme.dart';
import 'screens/home.dart';
import 'widgets/selfolder.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final initialFolder = prefs.getString('gensaku_app_folder');
  final themeNotifier = ThemeNotifier(AppTheme.light);
  runApp(GensakuApp(themeNotifier: themeNotifier, initialFolder: initialFolder));
}

class GensakuApp extends StatelessWidget {
  final ThemeNotifier themeNotifier;
  final String? initialFolder;
  const GensakuApp({required this.themeNotifier, this.initialFolder, super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themeNotifier,
      builder: (context, _) {
        return MaterialApp(
          title: 'Gensaku',
          theme: themeNotifier.themeData,
          home: StartupFlow(themeNotifier: themeNotifier, initialFolder: initialFolder),
        );
      },
    );
  }
}

class StartupFlow extends StatefulWidget {
  final ThemeNotifier themeNotifier;
  final String? initialFolder;

  const StartupFlow({required this.themeNotifier, this.initialFolder, super.key});

  @override
  State<StartupFlow> createState() => _StartupFlowState();
}

class _StartupFlowState extends State<StartupFlow> {
  String? _folderPath;
  bool _proceed = false;

  @override
  void initState() {
    super.initState();
    _folderPath = widget.initialFolder;
  }

  void _onFolderSelected(String? path) {
    setState(() => _folderPath = path);
  }

  @override
  Widget build(BuildContext context) {
    if (_proceed) {
      return MainLayout(themeNotifier: widget.themeNotifier);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Gensaku — Select Storage')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Choose where Gensaku should store application data.',
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 12),
                SelFolder(onFolderSelected: _onFolderSelected),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () async {
                        // Allow user to continue with browser storage (web) or without folder (desktop)
                        setState(() => _proceed = true);
                      },
                      child: const Text('Continue without folder'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: (_folderPath != null || Theme.of(context).platform == TargetPlatform.iOS || Theme.of(context).platform == TargetPlatform.android)
                          ? () => setState(() => _proceed = true)
                          : null,
                      child: const Text('Continue'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MainLayout extends StatefulWidget {
  final ThemeNotifier themeNotifier;
  const MainLayout({required this.themeNotifier, super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomePage(key: const ValueKey('home'), notifier: widget.themeNotifier),
      const Center(key: ValueKey('account'), child: Text("Account Screen", style: TextStyle(fontSize: 32))),
      const Center(key: ValueKey('settings'), child: Text("Settings Screen", style: TextStyle(fontSize: 32))),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationPanel(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}