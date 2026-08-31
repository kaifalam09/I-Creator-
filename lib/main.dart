import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

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

  const VideoModel({
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
  const VideoModel(
    title: 'Welcome to I-Creator: Ultimate Platform Tour',
    channel: 'I-Creator Official',
    type: 'long',
    views: '1.4M views • 1 day ago',
    networkUrl:
        'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
  ),
  const VideoModel(
    title: 'Top Speed Drift Highlights #Shorts',
    channel: 'SpeedRunner',
    type: 'reel',
    views: '850K views',
    networkUrl:
        'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
  ),
];

// ============================================================
// APP
// ============================================================

class ICreatorApp extends StatelessWidget {
  const ICreatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'I-Creator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.redAccent,
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F0F0F),
          elevation: 0,
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
  int currentIndex = 0;

  final ImagePicker picker = ImagePicker();

  // ==========================================================
  // CREATE MENU
  // ==========================================================

  void showCreateMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF212121),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Create',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
                  'Select a vertical video from your phone',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  pickVideo('reel');
                },
              ),

              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF333333),
                  child: Icon(
                    Icons.video_library,
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
                  'Select a video from your phone',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  pickVideo('long');
                },
              ),

              const SizedBox(height: 15),
            ],
          ),
        );
      },
    );
  }

  // ==========================================================
  // PICK VIDEO
  // ==========================================================

  Future<void> pickVideo(String type) async {
    if (!UserSession.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Please sign in first to upload videos.',
          ),
          action: SnackBarAction(
            label: 'SIGN IN',
            onPressed: () {
              setState(() {
                currentIndex = 4;
              });
            },
          ),
        ),
      );
      return;
    }

    try {
      final XFile? file = await picker.pickVideo(
        source: ImageSource.gallery,
      );

      if (file == null || !mounted) {
        return;
      }

      showVideoDetails(file.path, type);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Video select failed: $e',
          ),
        ),
      );
    }
  }

  // ==========================================================
  // VIDEO DETAILS
  // ==========================================================

  void showVideoDetails(
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
            left: 20,
            right: 20,
            top: 20,
            bottom:
                MediaQuery.of(ctx).viewInsets.bottom + 20,
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
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 15),

              TextField(
                controller: titleController,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Video title',
                  hintText: 'Enter a title',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    final String title =
                        titleController.text.trim();

                    if (title.isEmpty) {
                      ScaffoldMessenger.of(ctx)
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please enter a title.',
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

              const SizedBox(height: 5),
            ],
          ),
        );
      },
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const HomeScreen(),
      const ReelsScreen(),
      const SizedBox(),
      const SubscriptionsScreen(),
      ProfileScreen(
        onStateChanged: () {
          setState(() {});
        },
      ),
    ];

    return Scaffold(
      body: screens[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          if (index == 2) {
            showCreateMenu();
            return;
          }

          setState(() {
            currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.play_circle_outline),
            label: 'Shorts',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.add_circle,
              size: 36,
              color: Colors.white,
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.subscriptions_outlined),
            label: 'Subscriptions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle_outlined),
            label: 'You',
          ),
        ],
      ),
    );
  }
}

// ============================================================
// HOME
// ============================================================

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<VideoModel> videos = globalVideos
        .where((video) => video.type == 'long')
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(
              Icons.play_arrow_rounded,
              color: Colors.redAccent,
              size: 32,
            ),
            SizedBox(width: 5),
            Text(
              'I-Creator',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
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
      body: videos.isEmpty
          ? const Center(
              child: Text(
                'No videos available',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            )
          : ListView.builder(
              itemCount: videos.length,
              itemBuilder: (context, index) {
                return VideoCard(
                  video: videos[index],
                );
              },
            ),
    );
  }
}

// ============================================================
// VIDEO CARD
// ============================================================

class VideoCard extends StatefulWidget {
  final VideoModel video;

  const VideoCard({
    super.key,
    required this.video,
  });

  @override
  State<VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<VideoCard> {
  VideoPlayerController? controller;
  String? error;

  @override
  void initState() {
    super.initState();
    initializeVideo();
  }

  Future<void> initializeVideo() async {
    try {
      if (widget.video.filePath != null) {
        controller = VideoPlayerController.file(
          File(widget.video.filePath!),
        );
      } else if (widget.video.networkUrl != null) {
        controller =
            VideoPlayerController.networkUrl(
          Uri.parse(widget.video.networkUrl!),
        );
      } else {
        if (mounted) {
          setState(() {
            error = 'Video source unavailable';
          });
        }
        return;
      }

      await controller!.initialize();

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = 'Unable to load video';
        });
      }
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget player;

    if (error != null) {
      player = Container(
        color: Colors.black,
        child: Center(
          child: Text(
            error!,
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
        ),
      );
    } else if (controller != null &&
        controller!.value.isInitialized) {
      player = Stack(
        alignment: Alignment.center,
        children: [
          VideoPlayer(controller!),
          if (!controller!.value.isPlaying)
            const Icon(
              Icons.play_circle_fill,
              size: 60,
              color: Colors.white70,
            ),
        ],
      );
    } else {
      player = const Center(
        child: CircularProgressIndicator(
          color: Colors.redAccent,
        ),
      );
    }

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: GestureDetector(
            onTap: () {
              if (controller == null ||
                  !controller!.value.isInitialized) {
                return;
              }

              if (controller!.value.isPlaying) {
                controller!.pause();
              } else {
                controller!.play();
              }

              setState(() {});
            },
            child: Container(
              color: Colors.black,
              child: player,
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: Colors.redAccent,
                child: Text(
                  widget.video.channel.isNotEmpty
                      ? widget.video.channel[0]
                          .toUpperCase()
                      : 'U',
                  style: const TextStyle(
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
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 5),

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
                color: Colors.grey,
              ),
            ],
          ),
        ),

        const SizedBox(height: 5),
      ],
    );
  }
}

// ============================================================
// SHORTS
// ============================================================

class ReelsScreen extends StatelessWidget {
  const ReelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<VideoModel> reels = globalVideos
        .where((video) => video.type == 'reel')
        .toList();

    if (reels.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'No Shorts available',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        scrollDirection: Axis.vertical,
        itemCount: reels.length,
        itemBuilder: (context, index) {
          return ShortVideo(
            video: reels[index],
          );
        },
      ),
    );
  }
}

// ============================================================
// SHORT VIDEO
// ============================================================

class ShortVideo extends StatefulWidget {
  final VideoModel video;

  const ShortVideo({
    super.key,
    required this.video,
  });

  @override
  State<ShortVideo> createState() => _ShortVideoState();
}

class _ShortVideoState extends State<ShortVideo> {
  VideoPlayerController? controller;
  String? error;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  Future<void> initialize() async {
    try {
      if (widget.video.filePath != null) {
        controller = VideoPlayerController.file(
          File(widget.video.filePath!),
        );
      } else if (widget.video.networkUrl != null) {
        controller =
            VideoPlayerController.networkUrl(
          Uri.parse(widget.video.networkUrl!),
        );
      } else {
        if (mounted) {
          setState(() {
            error = 'Video unavailable';
          });
        }
        return;
      }

      await controller!.initialize();
      await controller!.setLooping(true);
      await controller!.play();

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = 'Unable to load Short';
        });
      }
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(color: Colors.black),

        if (error != null)
          Center(
            child: Text(
              error!,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
          )
        else if (controller != null &&
            controller!.value.isInitialized)
          GestureDetector(
            onTap: () {
              if (controller!.value.isPlaying) {
                controller!.pause();
              } else {
                controller!.play();
              }

              setState(() {});
            },
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: controller!.value.size.width,
                height: controller!.value.size.height,
                child: VideoPlayer(controller!),
              ),
            ),
          )
        else
          const Center(
            child: CircularProgressIndicator(
              color: Colors.redAccent,
            ),
          ),

        Positioned(
          left: 16,
          right: 80,
          bottom: 30,
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                '@${widget.video.channel}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                widget.video.title,
                maxLines: 3,
                overflow:
                    TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),

        Positioned(
          right: 14,
          bottom: 35,
          child: Column(
            children: [
              const Icon(
                Icons.thumb_up_alt_outlined,
                size: 30,
              ),
              const SizedBox(height: 5),
              const Text('42K'),

              const SizedBox(height: 20),

              const Icon(
                Icons.comment_outlined,
                size: 30,
              ),
              const SizedBox(height: 5),
              const Text('1.8K'),

              const SizedBox(height: 20),

              const Icon(
                Icons.share,
                size: 30,
              ),
              const SizedBox(height: 5),
              const Text('Share'),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================
// SUBSCRIPTIONS
// ============================================================

class SubscriptionsScreen extends StatelessWidget {
  const SubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscriptions'),
      ),
      body: const Center(
        child: Text(
          'Channels you subscribe to will appear here.',
          style: TextStyle(
            color: Colors.grey,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// PROFILE
// ============================================================

class ProfileScreen extends StatefulWidget {
  final VoidCallback onStateChanged;

  const ProfileScreen({
    super.key,
    required this.onStateChanged,
  });

  @override
  State<ProfileScreen> createState() =>
      _ProfileScreenState();
}

class _ProfileScreenState
    extends State<ProfileScreen> {

  // ==========================================================
  // AUTH
  // ==========================================================

  void openAuth() {
    final TextEditingController emailController =
        TextEditingController();

    final TextEditingController passwordController =
        TextEditingController();

    final TextEditingController nameController =
        TextEditingController();

    bool signUp = false;

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
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom:
                    MediaQuery.of(ctx).viewInsets.bottom +
                        20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      signUp
                          ? 'Create Your Channel'
                          : 'Sign In',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 20),

                    if (signUp) ...[
                      TextField(
                        controller: nameController,
                        decoration:
                            const InputDecoration(
                          labelText: 'Channel Name',
                          border:
                              OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    TextField(
                      controller: emailController,
                      keyboardType:
                          TextInputType.emailAddress,
                      decoration:
                          const InputDecoration(
                        labelText: 'Email',
                        border:
                            OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration:
                          const InputDecoration(
                        labelText: 'Password',
                        border:
                            OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 18),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style:
                            ElevatedButton.styleFrom(
                          backgroundColor:
                              Colors.redAccent,
                          foregroundColor:
                              Colors.white,
                        ),
                        onPressed: () {
                          final String email =
                              emailController.text
                                  .trim();

                          final String password =
                              passwordController.text;

                          final String name =
                              nameController.text
                                  .trim();

                          if (!email.contains('@') ||
                              password.length < 4) {
                            ScaffoldMessenger.of(ctx)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Enter a valid email and password of at least 4 characters.',
                                ),
                              ),
                            );
                            return;
                          }

                          if (signUp && name.isEmpty) {
                            ScaffoldMessenger.of(ctx)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please enter a channel name.',
                                ),
                              ),
                            );
                            return;
                          }

                          setState(() {
                            UserSession.isLoggedIn =
                                true;

                            UserSession.email =
                                email;

                            UserSession.channelName =
                                signUp
                                    ? name
                                    : email
                                        .split('@')
                                        .first;
                          });

                          widget.onStateChanged();

                          Navigator.pop(ctx);

                          ScaffoldMessenger.of(context)
                              .showSnackBar(
                            SnackBar(
                              content: Text(
                                signUp
                                    ? 'Channel created successfully!'
                                    : 'Signed in successfully!',
                              ),
                            ),
                          );
                        },
                        child: Text(
                          signUp
                              ? 'Create Account'
                              : 'Sign In',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    TextButton(
                      onPressed: () {
                        setSheetState(() {
                          signUp = !signUp;
                        });
                      },
                      child: Text(
                        signUp
                            ? 'Already have an account? Sign In'
                            : 'Create a new account',
                      ),
                    ),

                    const SizedBox(height: 5),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ==========================================================
  // LOGOUT
  // ==========================================================

  void logout() {
    setState(() {
      UserSession.isLoggedIn = false;
      UserSession.email = '';
      UserSession.channelName = 'Guest User';
    });

    widget.onStateChanged();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Signed out successfully.'),
      ),
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final bool loggedIn = UserSession.isLoggedIn;

    return Scaffold(
      appBar: AppBar(
        title: const Text('You'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          CircleAvatar(
            radius: 42,
            backgroundColor: Colors.redAccent,
            child: Text(
              UserSession.channelName.isNotEmpty
                  ? UserSession.channelName[0]
                      .toUpperCase()
                  : 'U',
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 15),

          Center(
            child: Text(
              UserSession.channelName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 5),

          Center(
            child: Text(
              loggedIn
                  ? UserSession.email
                  : 'Not signed in',
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
          ),

          const SizedBox(height: 25),

          if (!loggedIn)
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Colors.redAccent,
                  foregroundColor: Colors.white,
                ),
                onPressed: openAuth,
                icon: const Icon(Icons.login),
                label: const Text(
                  'Sign In / Create Account',
                ),
              ),
            ),

          if (loggedIn) ...[
            ListTile(
              leading:
                  const Icon(Icons.person),
              title:
                  const Text('Your Channel'),
              subtitle: Text(
                UserSession.channelName,
              ),
            ),

            ListTile(
              leading:
                  const Icon(Icons.email),
              title: const Text('Email'),
              subtitle: Text(
                UserSession.email,
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              height: 50,
              child: OutlinedButton.icon(
                onPressed: logout,
                icon:
                    const Icon(Icons.logout),
                label:
                    const Text('Sign Out'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
