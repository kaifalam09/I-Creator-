import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ICreatorApp());
}

// Global user profile state
class UserSession {
  static bool isLoggedIn = false;
  static String channelName = 'Guest User';
  static String email = '';
}

// Video Model
class VideoModel {
  final String title;
  final String channel;
  final String type; // 'long' or 'reel'
  final String views;
  final String? networkUrl;
  final String? filePath;

  VideoModel({
    required this.title,
    required this.channel,
    required this.type,
    required this.views,
    this.networkUrl,
    this.filePath,
  });
}

// In-Memory Database for Videos
List<VideoModel> globalVideos = [
  VideoModel(
    title: 'Welcome to I-Creator: Ultimate Platform Tour',
    channel: 'I-Creator Official',
    type: 'long',
    views: '1.4M views • 1 day ago',
    networkUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
  ),
  VideoModel(
    title: 'Top Speed Drift Highlights #Shorts',
    channel: 'SpeedRunner',
    type: 'reel',
    views: '850K views',
    networkUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
  ),
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
  final ImagePicker _picker = ImagePicker();

  void _showYouTubePlusSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF212121),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Create', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF333333),
                  child: Icon(Icons.play_circle_fill_rounded, color: Colors.white),
                ),
                title: const Text('Create a Short', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Share a 60-second vertical video', style: TextStyle(fontSize: 12, color: Colors.grey)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadVideo('reel');
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF333333),
                  child: Icon(Icons.upload_file_rounded, color: Colors.white),
                ),
                title: const Text('Upload a video', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Select a video file from your phone storage', style: TextStyle(fontSize: 12, color: Colors.grey)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadVideo('long');
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAndUploadVideo(String videoType) async {
    if (!UserSession.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please sign in first to upload videos!'),
          action: SnackBarAction(
            label: 'Sign In',
            textColor: Colors.redAccent,
            onPressed: () => setState(() => _currentIndex = 4),
          ),
        ),
      );
      return;
    }

    final XFile? pickedFile = await _picker.pickVideo(
      source: ImageSource.gallery,
    );

    if (pickedFile != null && mounted) {
      _showVideoDetailsForm(pickedFile.path, videoType);
    }
  }

  void _showVideoDetailsForm(String filePath, String type) {
    final titleController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              type == 'reel' ? 'Add details to Short' : 'Add details to Video',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Create a title (required)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                onPressed: () {
                  if (titleController.text.trim().isNotEmpty) {
                    setState(() {
                      globalVideos.insert(
                        0,
                        VideoModel(
                          title: titleController.text.trim(),
                          channel: UserSession.channelName,
                          type: type,
                          views: 'Just now',
                          filePath: filePath,
                        ),
                      );
                    });
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Video published successfully!')),
                    );
                  }
                },
                child: const Text('Publish Video', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const HomeScreen(),
      const ReelsScreen(),
      const Center(), // Placeholder for +
      const SubscriptionsScreen(),
      ProfileScreen(onStateChanged: () => setState(() {})),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 2) {
            _showYouTubePlusSheet();
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

// --- 1. HOME SCREEN ---
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final longVideos = globalVideos.where((v) => v.type == 'long').toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(Icons.play_arrow_rounded, color: Colors.redAccent, size: 32),
            SizedBox(width: 6),
            Text('I-Creator', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 21, letterSpacing: -0.5)),
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
          return YouTubeVideoCard(video: longVideos[index]);
        },
      ),
    );
  }
}

class YouTubeVideoCard extends StatefulWidget {
  final VideoModel video;
  const YouTubeVideoCard({super.key, required this.video});

  @override
  State<YouTubeVideoCard> createState() => _YouTubeVideoCardState();
}

class _YouTubeVideoCardState extends State<YouTubeVideoCard> {
  late VideoPlayerController _controller;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    if (widget.video.filePath != null) {
      _controller = VideoPlayerController.file(File(widget.video.filePath!));
    } else {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.video.networkUrl!));
    }

    _controller.initialize().then((_) {
      if (mounted) {
        setState(() {
          _chewieController = ChewieController(
            videoPlayerController: _controller,
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
    _controller.dispose();
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
          child: _chewieController != null && _controller.value.isInitialized
              ? Chewie(controller: _chewieController!)
              : Container(
                  color: Colors.black26,
                  child: const Center(child: CircularProgressIndicator(color: Colors.redAccent)),
                ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: Colors.redAccent,
                child: Text(widget.video.channel[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.video.title,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.video.channel} • ${widget.video.views}',
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

// --- 2. SHORTS / REELS SCREEN ---
class ReelsScreen extends StatelessWidget {
  const ReelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reels = globalVideos.where((v) => v.type == 'reel').toList();

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
  final VideoModel reel;
  const ShortVideoItem({super.key, required this.reel});

  @override
  State<ShortVideoItem> createState() => _ShortVideoItemState();
}

class _ShortVideoItemState extends State<ShortVideoItem> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    if (widget.reel.filePath != null) {
      _controller = VideoPlayerController.file(File(widget.reel.filePath!));
    } else {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.reel.networkUrl!));
    }

    _controller.initialize().then((_) {
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
                onTap: () => _controller.value.isPlaying ? _controller.pause() : _controller.play(),
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
          right: 14,
          bottom: 40,
          child: Column(
            children: const [
              Icon(Icons.thumb_up_alt_outlined, size: 28, color: Colors.white),
              SizedBox(height: 4),
              Text('42K', style: TextStyle(fontSize: 12)),
              SizedBox(height: 18),
              Icon(Icons.comment_outlined, size: 28, color: Colors.white),
              SizedBox(height: 4),
              Text('1.8K', style: TextStyle(fontSize: 12)),
              SizedBox(height: 18),
              Icon(Icons.share, size: 28, color: Colors.white),
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
              Text('@${widget.reel.channel}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 6),
              Text(widget.reel.title, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }
}

// --- 3. SUBSCRIPTIONS ---
class SubscriptionsScreen extends StatelessWidget {
  const SubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subscriptions')),
      body: const Center(
        child: Text('Channels you subscribe to will appear here.', style: TextStyle(color: Colors.grey)),
      ),
    );
  }
}

// --- 4. YOU / AUTHENTICATION & PROFILE SCREEN ---
class ProfileScreen extends StatefulWidget {
  final VoidCallback onStateChanged;
  const ProfileScreen({super.key, required this.onStateChanged});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  void _openAuthDialog() {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final nameController = TextEditingController();
    bool isSignUp = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isSignUp ? 'Create Your Account / Channel' : 'Sign in with Google / Email',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                if (isSignUp)
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Channel / Display Name', border: OutlineInputBorder()),
                  ),
                if (isSignUp) const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Gmail / Email Address', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                    onPressed: () {
                      if (emailController.text.contains('@') && passwordController.text.length >= 4) {
                        setState(() {
                          UserSession.isLoggedIn = true;
                          UserSession.email = emailController.text.trim();
                          UserSession.channelName = isSignUp && nameController.text.isNotEmpty
                              ? nameController.text.trim()
                              : emailController.text.split('@')[0];
                        });
                        widget.onStateChanged();
                        Navigator.pop(ctx);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter valid Gmail & Password (min 4 chars)
