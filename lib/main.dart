import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://YOUR_PROJECT_ID.supabase.co',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );
  runApp(const BharatStreamApp());
}

final supabase = Supabase.instance.client;

class BharatStreamApp extends StatelessWidget {
  const BharatStreamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.black,
          selectedItemColor: Colors.redAccent,
          unselectedItemColor: Colors.grey,
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  final List<Widget> _screens = const [LongVideoFeed(), ReelsFeed()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.play_arrow_rounded), label: 'Reels'),
        ],
      ),
    );
  }
}

// --- LONG VIDEO FEED ---
class LongVideoFeed extends StatelessWidget {
  const LongVideoFeed({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('I-Creator', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase.from('videos').stream(primaryKey: ['id']).eq('type', 'long'),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.redAccent));
          final videos = snapshot.data!;
          if (videos.isEmpty) return const Center(child: Text('No long videos found.'));

          return ListView.builder(
            itemCount: videos.length,
            itemBuilder: (context, index) {
              final video = videos[index];
              return LongVideoCard(
                title: video['title'] ?? '',
                channel: video['channel'] ?? '',
                videoUrl: video['video_url'] ?? '',
              );
            },
          );
        },
      ),
    );
  }
}

class LongVideoCard extends StatefulWidget {
  final String title;
  final String channel;
  final String videoUrl;

  const LongVideoCard({super.key, required this.title, required this.channel, required this.videoUrl});

  @override
  State<LongVideoCard> createState() => _LongVideoCardState();
}

class _LongVideoCardState extends State<LongVideoCard> {
  late VideoPlayerController _controller;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    _controller.initialize().then((_) {
      setState(() {
        _chewieController = ChewieController(
          videoPlayerController: _controller,
          autoPlay: false,
          looping: false,
          aspectRatio: 16 / 9,
        );
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: _chewieController != null && _controller.value.isInitialized
                ? Chewie(controller: _chewieController!)
                : const Center(child: CircularProgressIndicator(color: Colors.redAccent)),
          ),
          ListTile(
            leading: const CircleAvatar(backgroundColor: Colors.grey, child: Icon(Icons.person, color: Colors.white)),
            title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(widget.channel, style: const TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}

// --- REELS FEED ---
class ReelsFeed extends StatelessWidget {
  const ReelsFeed({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase.from('videos').stream(primaryKey: ['id']).eq('type', 'reel'),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.redAccent));
        final reels = snapshot.data!;
        if (reels.isEmpty) return const Center(child: Text('No reels found.'));

        return PageView.builder(
          scrollDirection: Axis.vertical,
          itemCount: reels.length,
          itemBuilder: (context, index) {
            final reel = reels[index];
            return ReelItem(
              title: reel['title'] ?? '',
              channel: reel['channel'] ?? '',
              videoUrl: reel['video_url'] ?? '',
            );
          },
        );
      },
    );
  }
}

class ReelItem extends StatefulWidget {
  final String title;
  final String channel;
  final String videoUrl;

  const ReelItem({super.key, required this.title, required this.channel, required this.videoUrl});

  @override
  State<ReelItem> createState() => _ReelItemState();
}

class _ReelItemState extends State<ReelItem> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
        _controller.setLooping(true);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _controller.value.isInitialized
            ? FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              )
            : const Center(child: CircularProgressIndicator(color: Colors.redAccent)),
        Positioned(
          left: 16,
          bottom: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('@${widget.channel}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 6),
              Text(widget.title, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }
}
