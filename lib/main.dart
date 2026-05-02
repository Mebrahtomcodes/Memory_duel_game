import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'screens/game_screen.dart';
import 'services/game_service.dart';

void main() {
  runApp(const MyApp());
}

// Helper to launch URLs
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
      theme: ThemeData.dark(),
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
  final TextEditingController playerA = TextEditingController();
  final TextEditingController playerB = TextEditingController();
  final GameService _gameService = GameService();
  List leaderboard = [];

  @override
  void initState() {
    super.initState();
    fetchLeaderboard();
  }

  Future<void> fetchLeaderboard() async {
    final data = await _gameService.getLeaderboard();
    setState(() {
      leaderboard = data;
    });
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

  void createGame() {
    if (playerA.text.isEmpty || playerB.text.isEmpty) return;
    final game = _gameService.createGame(playerA.text, playerB.text);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GameScreen(gameId: game.gameId)),
    ).then((_) => fetchLeaderboard());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white54),
            onPressed: () {
              showAboutDialog(
                context: context,
                applicationName: "Memory Duel",
                applicationVersion: "1.0.0",
                applicationIcon: const Icon(Icons.memory, size: 40, color: Colors.blue),
                applicationLegalese: "© 2026 Mebre Lala. All rights reserved.",
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    "👤 About Developer",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 10),
                  const Text(
                    "👤 Mebre Lala",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  InkWell(
                    onTap: () => _launchURL("mailto:mebreg4@gmail.com"),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(Icons.email_outlined, size: 16, color: Colors.blue),
                          SizedBox(width: 8),
                          Text("mebreg4@gmail.com", style: TextStyle(color: Colors.blue)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "💼 Mobile & Flutter Developer | Spring Boot Backend Developer",
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                  const Text(
                    "🚀 Open for freelance work",
                    style: TextStyle(fontSize: 14, color: Colors.greenAccent),
                  ),
                  const SizedBox(height: 15),
                  InkWell(
                    onTap: () => _launchURL("https://github.com/Mebrahtomcodes"),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(Icons.link, size: 16, color: Colors.blue),
                          SizedBox(width: 8),
                          Text("GitHub: Mebrahtomcodes", style: TextStyle(color: Colors.blue)),
                        ],
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => _launchURL("https://www.linkedin.com/in/mebrahtom-guesh-168b2b389"),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(Icons.link, size: 16, color: Colors.blue),
                          SizedBox(width: 8),
                          Text("LinkedIn Profile", style: TextStyle(color: Colors.blue)),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.emoji_events, size: 80, color: Colors.yellow),
                const SizedBox(height: 10),
                const Text(
                  "Memory Duel",
                  style: TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),
                TextField(
                  controller: playerA,
                  decoration: InputDecoration(
                    labelText: "Player 1 Name",
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: playerB,
                  decoration: InputDecoration(
                    labelText: "Player 2 Name",
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                ),
                const SizedBox(height: 25),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 55,
                        child: OutlinedButton.icon(
                          onPressed: _showRules,
                          icon: const Icon(Icons.help_outline, color: Colors.orange, size: 18),
                          label: const Text(
                            "HOW TO PLAY",
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white24),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 55,
                        child: ElevatedButton(
                          onPressed: createGame,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                          child: const Text("START DUEL", style: TextStyle(fontSize: 18, color: Colors.white)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                const Text(
                  "🏆 TOP 3 FASTEST WINNERS",
                  style: TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 10),
                if (leaderboard.isEmpty)
                  const Text("No records yet", style: TextStyle(color: Colors.white54))
                else
                  ...leaderboard.map((entry) => Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("${entry['playerName']}", style: const TextStyle(color: Colors.white, fontSize: 16)),
                        Text("${entry['timeInSeconds']}s", style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )),
                const SizedBox(height: 60),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.code, color: Colors.white24, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      "Developed by Mebre Lala".toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white24,
                        fontSize: 12,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
