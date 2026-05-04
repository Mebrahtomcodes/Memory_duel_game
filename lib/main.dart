import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'screens/game_screen.dart';
import 'screens/history_screen.dart';
import 'services/game_service.dart';

void main() {
  runApp(const MyApp());
}

void _launchURL(String urlString) async {
  final Uri url = Uri.parse(urlString);
  if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
    debugPrint("Could not launch $urlString");
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Memory Duel',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
        primaryColor: Colors.blue,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GameService _gameService = GameService();

  void _startSinglePlayer() {
    final TextEditingController nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => _buildNameDialog(
        title: "Single Player",
        controllers: [nameController],
        labels: ["Your Name"],
        onStart: () {
          if (nameController.text.isNotEmpty) {
            final game = _gameService.createGame([nameController.text, "Computer"], isVsComputer: true);
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => GameScreen(gameId: game.gameId)));
          }
        },
      ),
    );
  }

  void _startTwoPlayer() {
    final TextEditingController p1Controller = TextEditingController();
    final TextEditingController p2Controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => _buildNameDialog(
        title: "Two Player Duel",
        controllers: [p1Controller, p2Controller],
        labels: ["Player 1 Name", "Player 2 Name"],
        onStart: () {
          if (p1Controller.text.isNotEmpty && p2Controller.text.isNotEmpty) {
            final game = _gameService.createGame([p1Controller.text, p2Controller.text]);
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => GameScreen(gameId: game.gameId)));
          }
        },
      ),
    );
  }

  void _startThreePlayer() {
    final TextEditingController p1Controller = TextEditingController();
    final TextEditingController p2Controller = TextEditingController();
    final TextEditingController p3Controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => _buildNameDialog(
        title: "Three Player Duel",
        controllers: [p1Controller, p2Controller, p3Controller],
        labels: ["Player 1", "Player 2", "Player 3"],
        onStart: () {
          if (p1Controller.text.isNotEmpty && p2Controller.text.isNotEmpty && p3Controller.text.isNotEmpty) {
            final game = _gameService.createGame([p1Controller.text, p2Controller.text, p3Controller.text]);
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => GameScreen(gameId: game.gameId)));
          }
        },
      ),
    );
  }

  void _showRules() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.lightbulb_outline, color: Colors.orange),
            SizedBox(width: 10),
            Text("How to Play", style: TextStyle(color: Colors.white)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _ruleItem("🎯 Goal", "Find and flip cards 1, 2, 3... up to 12 in order."),
              _ruleItem("✅ Correct", "If you find the right number, you keep playing!"),
              _ruleItem("❌ Wrong", "If you miss, your turn ends and cards are hidden."),
              _ruleItem("⏳ 10s Timer", "You must move fast! 10 seconds per turn."),
              _ruleItem("🏆 Win", "Flip all 12 cards in one single turn to win!"),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("READY!", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _ruleItem(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 16)),
          Text(desc, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildNameDialog({
    required String title,
    required List<TextEditingController> controllers,
    required List<String> labels,
    required VoidCallback onStart,
  }) {
    return AlertDialog(
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(controllers.length, (i) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: TextField(
              controller: controllers[i],
              decoration: InputDecoration(
                labelText: labels[i],
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          )),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
        ElevatedButton(
          onPressed: onStart,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
          child: const Text("START"),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white54),
            onPressed: _showAbout,
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F0F0F)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                const Icon(Icons.emoji_events, size: 100, color: Colors.yellow),
                const SizedBox(height: 20),
                const Text(
                  "MEMORY DUEL",
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  "Test your focus. Outsmart your rivals.",
                  style: TextStyle(color: Colors.white54, fontSize: 16),
                ),
                const SizedBox(height: 40),
                _MenuButton(
                  icon: Icons.person,
                  label: "SINGLE PLAYER",
                  color: Colors.blueAccent,
                  onTap: _startSinglePlayer,
                ),
                _MenuButton(
                  icon: Icons.people,
                  label: "TWO PLAYER",
                  color: Colors.greenAccent,
                  onTap: _startTwoPlayer,
                ),
                _MenuButton(
                  icon: Icons.groups,
                  label: "THREE PLAYER",
                  color: Colors.orangeAccent,
                  onTap: _startThreePlayer,
                ),
                _MenuButton(
                  icon: Icons.history,
                  label: "HISTORY",
                  color: Colors.purpleAccent,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen())),
                ),
                _MenuButton(
                  icon: Icons.help_outline,
                  label: "HOW TO PLAY",
                  color: Colors.yellowAccent,
                  onTap: _showRules,
                ),
                const SizedBox(height: 40),
                _buildDeveloperInfo(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeveloperInfo() {
    return InkWell(
      onTap: () => _showAbout(),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.code, color: Colors.white24, size: 16),
              const SizedBox(width: 8),
              Text(
                "Developed by Mebre Lala".toUpperCase(),
                style: const TextStyle(
                  color: Colors.white24,
                  fontSize: 10,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("👤 About / Developer", style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "👤 Mebre Lala",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 10),
              _contactItem(
                icon: Icons.email_outlined,
                label: "mebreg4@gmail.com",
                onTap: () => _launchURL("mailto:mebreg4@gmail.com"),
              ),
              const SizedBox(height: 20),
              const Text(
                "💼 Mobile & Flutter Developer | Spring Boot Backend Developer",
                style: TextStyle(fontSize: 14, color: Colors.white70),
              ),
              const Text(
                "🚀 Open for freelance work",
                style: TextStyle(fontSize: 14, color: Colors.greenAccent),
              ),
              const SizedBox(height: 20),
              _contactItem(
                icon: Icons.link,
                label: "GitHub: Mebrahtomcodes",
                onTap: () => _launchURL("https://github.com/Mebrahtomcodes"),
              ),
              const SizedBox(height: 10),
              _contactItem(
                icon: Icons.link,
                label: "LinkedIn Profile",
                onTap: () => _launchURL("https://www.linkedin.com/in/mebrahtom-guesh-168b2b389"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CLOSE", style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  Widget _contactItem({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.blue),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MenuButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: color.withOpacity(0.3), width: 1),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 20),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              const Icon(Icons.chevron_right, color: Colors.white24),
            ],
          ),
        ),
      ),
    );
  }
}
