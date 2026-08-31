import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ICreatorApp());
}

// Sample initial videos so the app is never empty
List<Map<String, String>> globalVideos = [
  {
    'title': 'High Speed Supercar Action',
    'channel': 'SpeedRunner',
    'type': 'long',
    'video_url': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
    'views': '1.2M views • 2 days ago'
  },
  {
    'title': 'Insane Drift & Stunt Reel',
    'channel': 'KaifCreator',
    'type': 'reel',
    'video_url': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
    'views': '540K views'
  },
  {
    'title': 'Best Football Skills & Goals Compilation',
    'channel': 'ProArena',
    'type': 'long',
    'video_url': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
    'views': '890K views • 1 week ago'
  },
  {
    'title': 'Top Speed Test Moments #Shorts',
    'channel': 'DriftKing',
    'type': 'reel',
    'video_url': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
    'views': '2.1M views'
  }
];

class ICreatorApp extends StatelessWidget {
  const ICreatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'I-Creator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF0F0F0F), elevation: 0),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF0F0F0F),
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
        ),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  void _openUploadDialog() {
    final titleController = TextEditingController();
    final channelController = TextEditingController();
    final urlController = TextEditingController();
    String videoType = 'long';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text('Create & Upload Video', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Video Title', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: channelController,
                  decoration: const InputDecoration(labelText: 'Channel / Creator Name', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: urlController,
                  decoration: const InputDecoration(labelText: 'Video URL (MP4 Link)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Format: '),
                    ChoiceChip(
                      label: const Text('Long Video'),
                      selected: videoType == 'long',
                      onSelected: (val) => setModalState(() => videoType = 'long'),
                    ),
                    const SizedBox(width: 10),
                    ChoiceChip(
                      label: const Text('Short / Reel'),
                      selected: videoType == 'reel',
                      onSelected: (val) => setModalState(() => videoType = 'reel'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                    onPressed: () {
                      if (titleController.text.isNotEmpty && urlController.text.isNotEmpty) {
                        setState(() {
                          globalVideos.insert(0, {
                            'title': titleController.text,
                            'channel': channelController.text.isEmpty ? 'My Channel' : channelController.text,
                            'type': videoType,
                            'video_url': urlController.text,
                            'views': 'Just now'
                          });
                        });
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Video uploaded successfully!')),
                        );
                      }
                    },
                    child: const Text('Upload to App', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const HomeScreen(),
      const ReelsScreen(),
      const Center(), // Placeholder for + button
      const SubscriptionsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 2) {
            _openUploadDialog();
          } else {
            setState(() => _currentIndex = index);
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.play_circle_outline), label: 'Shorts'),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline, size: 36, color: Colors.white),
            label: '',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.subscriptions_outlined), label: 'Subscriptions'),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle_outlined), label: 'You'),
        ],
      ),
    );
  }
}

// --- 1. HOME SCREEN (YouTube Style) ---
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final longVideos = globalVideos.where((v) => v['type'] == 'long').toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(Icons.play_arrow_rounded, color: Colors.redAccent, size: 30),
            SizedBox(width: 6),
            Text('I-Creator', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: -0.5)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.cast), onPressed: () {}),
          IconButton(icon: const Icon(Icons.notifications_none), onPressed: () {}),
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        ],
      ),
      body: ListView.builder(
        itemCount: longVideos.length,
        itemBuilder: (context, index) {
          final video = longVideos[index];
          return YouTubeVideoCard(video: video);
        },
      ),
    );
  }
}

class YouTubeVideoCard extends StatefulWidget {
  final Map<String, String> video;
  const YouTubeVideoCard({super.key, required this.video});

  @override
  State<YouTubeVideoCard> createState() => _YouTubeVideoCardState();
}

class _YouTubeVideoCardState extends State<YouTubeVideoCard> {
  late VideoPlayerController _playerController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _playerController = VideoPlayerController.networkUrl(Uri.parse(widget.video['video_url']!));
    _playerController.initialize().then((_) {
      if (mounted) {
        setState(() {
          _chewieController = ChewieController(
            videoPlayerController: _playerController,
            autoPlay: false,
            looping: false,
            aspectRatio: 16 / 9,
          );
        });
      }
    });
  }

  @override
  void dispose() {
    _playerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: _chewieController != null && _playerController.value.isInitialized
              ? Chewie(controller: _chewieController!)
              : const Center(child: CircularProgressIndicator(color: Colors.redAccent)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                backgroundColor: Colors.redAccent,
                child: Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.video['title'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.video['channel']} • ${widget.video['views']}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.more_vert, size: 20, color: Colors.grey),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

// --- 2. REELS / SHORTS SCREEN ---
class ReelsScreen extends StatelessWidget {
  const ReelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reels = globalVideos.where((v) => v['type'] == 'reel').toList();

    return Scaffold(
      body: PageView.builder(
        scrollDirection: Axis.vertical,
        itemCount: reels.length,
        itemBuilder: (context, index) {
          return ShortVideoItem(reel: reels[index]);
        },
      ),
    );
  }
}

class ShortVideoItem extends StatefulWidget {
  final Map<String, String> reel;
  const ShortVideoItem({super.key, required this.reel});

  @override
  State<ShortVideoItem> createState() => _ShortVideoItemState();
}

class _ShortVideoItemState extends State<ShortVideoItem> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.reel['video_url']!))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {});
          _controller.play();
          _controller.setLooping(true);
        }
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
            ? GestureDetector(
                onTap: () {
                  _controller.value.isPlaying ? _controller.pause() : _controller.play();
                },
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller.value.size.width,
                    height: _controller.value.size.height,
                    child: VideoPlayer(_controller),
                  ),
                ),
              )
            : const Center(child: CircularProgressIndicator(color: Colors.redAccent)),
        Positioned(
          right: 12,
          bottom: 40,
          child: Column(
            children: const [
              Icon(Icons.thumb_up_alt_outlined, size: 30, color: Colors.white),
              SizedBox(height: 4),
              Text('45K', style: TextStyle(fontSize: 12)),
              SizedBox(height: 18),
              Icon(Icons.comment_outlined, size: 30, color: Colors.white),
              SizedBox(height: 4),
              Text('1.2K', style: TextStyle(fontSize: 12)),
              SizedBox(height: 18),
              Icon(Icons.share, size: 30, color: Colors.white),
              SizedBox(height: 4),
              Text('Share', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
        Positioned(
          left: 16,
          bottom: 30,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('@${widget.reel['channel']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 6),
              Text(widget.reel['title'] ?? '', style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }
}

// --- 3. SUBSCRIPTIONS SCREEN ---
class SubscriptionsScreen extends StatelessWidget {
  const SubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subscriptions')),
      body: const Center(
        child: Text('Subscribed channels will appear here.', style: TextStyle(color: Colors.grey)),
      ),
    );
  }
}

// --- 4. PROFILE & LOGIN/SIGN-UP SCREEN ---
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isLoggedIn = false;
  String userName = 'Guest User';
  String userEmail = '';

  void _showAuthDialog() {
    final emailController = TextEditingController();
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF222222),
        title: const Text('Sign in / Create Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Channel / User Name')),
            const SizedBox(height: 10),
            TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email Address')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                setState(() {
                  isLoggedIn = true;
                  userName = nameController.text;
                  userEmail = emailController.text;
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('You'),
        actions: [
          IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () {}),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.redAccent,
                  child: Text(userName[0].toUpperCase(), style: const TextStyle(fontSize: 26, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(isLoggedIn ? userEmail : 'Not signed in', style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (!isLoggedIn)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                  icon: const Icon(Icons.login),
                  label: const Text('Sign In / Create Channel'),
                  onPressed: _showAuthDialog,
                ),
              ),
            const SizedBox(height: 20),
            const Divider(color: Colors.grey),
            const ListTile(
              leading: Icon(Icons.video_library_outlined),
              title: Text('Your videos'),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
            ),
            const ListTile(
              leading: Icon(Icons.download_outlined),
              title: Text('Downloads'),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
            ),
            const ListTile(
              leading: Icon(Icons.history),
              title: Text('History'),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
            ),
          ],
        ),
      ),
    );
  }
}
