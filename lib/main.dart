import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ICreatorApp());
}

// ============================================================
// USER SESSION
// ============================================================

class UserSession {
  static bool isLoggedIn = false;
  static String channelName = 'Guest User';
  static String email = '';
}

// ============================================================
// VIDEO MODEL
// ============================================================

class VideoModel {
  final String title;
  final String channel;
  final String type; // long / reel
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

// ============================================================
// IN-MEMORY VIDEO DATABASE
// ============================================================

final List<VideoModel> globalVideos = [
  VideoModel(
    title: 'Welcome to I-Creator: Ultimate Platform Tour',
    channel: 'I-Creator Official',
    type: 'long',
    views: '1.4M views • 1 day ago',
    networkUrl:
        'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
  ),
  VideoModel(
    title: 'Top Speed Drift Highlights #Shorts',
    channel: 'SpeedRunner',
    type: 'reel',
    views: '850K views',
    networkUrl:
        'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
  ),
];

// ============================================================
// MAIN APP
// ============================================================

class ICreatorApp extends StatelessWidget {
  const ICreatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'I-Creator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F0F0F),
          elevation: 0,
        ),
        bottomNavigationBarTheme:
            const BottomNavigationBarThemeData(
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

// ============================================================
// MAIN SCREEN
// ============================================================

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final ImagePicker _picker = ImagePicker();

  // ----------------------------------------------------------
  // CREATE MENU
  // ----------------------------------------------------------

  void _showYouTubePlusSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF212121),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Create',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        Navigator.pop(ctx);
                      },
                    ),
                  ],
                ),
              ),

              // CREATE SHORT
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF333333),
                  child: Icon(
                    Icons.play_circle_fill_rounded,
                    color: Colors.white,
                  ),
                ),
                title: const Text(
                  'Create a Short',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text(
                  'Share a 60-second vertical video',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadVideo('reel');
                },
              ),

              // UPLOAD VIDEO
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF333333),
                  child: Icon(
                    Icons.upload_file_rounded,
                    color: Colors.white,
                  ),
                ),
                title: const Text(
                  'Upload a video',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text(
                  'Select a video file from your phone storage',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
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

  // ----------------------------------------------------------
  // PICK VIDEO
  // ----------------------------------------------------------

  Future<void> _pickAndUploadVideo(String videoType) async {
    if (!UserSession.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Please sign in first to upload videos!',
          ),
          action: SnackBarAction(
            label: 'Sign In',
            textColor: Colors.redAccent,
            onPressed: () {
              setState(() {
                _currentIndex = 4;
              });
            },
          ),
        ),
      );
      return;
    }

    try {
      final XFile? pickedFile =
          await _picker.pickVideo(
        source: ImageSource.gallery,
      );

      if (pickedFile != null && mounted) {
        _showVideoDetailsForm(
          pickedFile.path,
          videoType,
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to select video: $e',
          ),
        ),
      );
    }
  }

  // ----------------------------------------------------------
  // VIDEO DETAILS
  // ----------------------------------------------------------

  void _showVideoDetailsForm(
    String filePath,
    String type,
  ) {
    final TextEditingController titleController =
        TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom:
                MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                type == 'reel'
                    ? 'Add details to Short'
                    : 'Add details to Video',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                  ),
                  onPressed: () {
                    final String title =
                        titleController.text.trim();

                    if (title.isEmpty) {
                      ScaffoldMessenger.of(ctx)
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please enter a video title.',
                          ),
                        ),
                      );
                      return;
                    }

                    setState(() {
                      globalVideos.insert(
                        0,
                        VideoModel(
                          title: title,
                          channel:
                              UserSession.channelName,
                          type: type,
                          views: 'Just now',
                          filePath: filePath,
                        ),
                      );
                    });

                    Navigator.pop(ctx);

                    ScaffoldMessenger.of(context)
                        .showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Video published successfully!',
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    'Publish Video',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  // ----------------------------------------------------------
  // MAIN BUILD
  // ----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const HomeScreen(),
      const ReelsScreen(),
      const Center(),
      const SubscriptionsScreen(),
      ProfileScreen(
        onStateChanged: () {
          setState(() {});
        },
      ),
    ];

    return Scaffold(
      body: screens[_currentIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,

        onTap: (index) {
          if (index == 2) {
            _showYouTubePlusSheet();
          } else {
            setState(() {
              _currentIndex = index;
            });
          }
        },

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: 'Home',
          ),

          BottomNavigationBarItem(
            icon: Icon(
              Icons.play_circle_outline,
            ),
            label: 'Shorts',
          ),

          BottomNavigationBarItem(
            icon: Icon(
              Icons.add_circle_outline,
              size: 36,
              color: Colors.white,
            ),
            label: '',
          ),

          BottomNavigationBarItem(
            icon: Icon(
              Icons.subscriptions_outlined,
            ),
            label: 'Subscriptions',
          ),

          BottomNavigationBarItem(
            icon: Icon(
              Icons.account_circle_outlined,
            ),
            label: 'You',
          ),
        ],
      ),
    );
  }
}

// ============================================================
// HOME SCREEN
// ============================================================

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<VideoModel> longVideos =
        globalVideos
            .where((video) => video.type == 'long')
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(
              Icons.play_arrow_rounded,
              color: Colors.redAccent,
              size: 32,
            ),
            SizedBox(width: 6),
            Text(
              'I-Creator',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 21,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),

        actions: [
          IconButton(
            icon: const Icon(Icons.cast),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(
              Icons.notifications_none,
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),

      body: longVideos.isEmpty
          ? const Center(
              child: Text(
                'No videos available',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            )
          : ListView.builder(
              itemCount: longVideos.length,
              itemBuilder: (context, index) {
                return YouTubeVideoCard(
                  video: longVideos[index],
                );
              },
            ),
    );
  }
}

// ============================================================
// YOUTUBE VIDEO CARD
// ============================================================

class YouTubeVideoCard extends StatefulWidget {
  final VideoModel video;

  const YouTubeVideoCard({
    super.key,
    required this.video,
  });

  @override
  State<YouTubeVideoCard> createState() =>
      _YouTubeVideoCardState();
}

class _YouTubeVideoCardState
    extends State<YouTubeVideoCard> {
  VideoPlayerController? _controller;
  ChewieController? _chewieController;

  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      if (widget.video.filePath != null) {
        _controller =
            VideoPlayerController.file(
          File(widget.video.filePath!),
        );
      } else if (widget.video.networkUrl != null) {
        _controller =
            VideoPlayerController.networkUrl(
          Uri.parse(widget.video.networkUrl!),
        );
      } else {
        setState(() {
          _error = 'Video source not available.';
        });
        return;
      }

      await _controller!.initialize();

      if (!mounted) return;

      _chewieController = ChewieController(
        videoPlayerController: _controller!,
        autoPlay: false,
        looping: false,
        aspectRatio: 16 / 9,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
      );

      setState(() {});
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'Unable to load video.';
      });
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget videoWidget;

    if (_error != null) {
      videoWidget = Container(
        color: Colors.black,
        child: Center(
          child: Text(
            _error!,
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
        ),
      );
    } else if (_chewieController != null &&
        _controller != null &&
        _controller!.value.isInitialized) {
      videoWidget = Chewie(
        controller: _chewieController!,
      );
    } else {
      videoWidget = Container(
        color: Colors.black26,
        child: const Center(
          child: CircularProgressIndicator(
            color: Colors.redAccent,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: videoWidget,
        ),

        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor:
                    Colors.redAccent,
                child: Text(
                  widget.video.channel.isNotEmpty
                      ? widget.video.channel[0]
                          .toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.video.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    Text(
                      '${widget.video.channel} • ${widget.video.views}',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.more_vert,
                size: 20,
                color: Colors.grey,
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),
      ],
    );
  }
}

// ============================================================
// SHORTS / REELS SCREEN
// ============================================================

class ReelsScreen extends StatelessWidget {
  const ReelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<VideoModel> reels =
        globalVideos
            .where((video) => video.type == 'reel')
            .toList();

    if (reels.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'No Shorts available',
            style: TextStyle(
              color: Colors
