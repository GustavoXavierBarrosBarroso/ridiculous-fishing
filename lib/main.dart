import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Ridiculous Fishing',
    home: GameLoaderScreen(),
  ));
}

// ─────────────────────────── SPRITE MANAGER ─────────────────────────────────
class SpriteManager {
  static final SpriteManager instance = SpriteManager._();
  SpriteManager._();

  final Map<String, ui.Image> _cache = {};

  ui.Image? get(String name) => _cache[name];

  Future<void> loadAll() async {
    final imagePaths = [
      // Official Billy & Boat
      'assets/billy/BillyNormalFish@2x.png',
      'assets/billy/BillyNormalShoot@2x.png',
      'assets/billy/shop_BG_boat@2x.png',
      // Nautical & Gameplay elements
      'assets/images/hook.png',
      'assets/images/deephook.png',
      'assets/images/wave.png',
      'assets/images/blood.png',
      'assets/images/bullet.png',
      // Lures & Chainsaw
      'assets/lures/lure0@2x.png',
      'assets/lures/lure4@2x.png',
      'assets/lures/lure4_swipe@2x.png',
      // Authentic Vlambeer fish spritesheets
      'assets/original_fish/guppy@2x.png',
      'assets/original_fish/guppyGold@2x.png',
      'assets/original_fish/pike@2x.png',
      'assets/original_fish/pikeGold@2x.png',
      'assets/original_fish/goldfish@2x.png',
      'assets/original_fish/jellySmall@2x.png',
      'assets/original_fish/jellyBig@2x.png',
      'assets/original_fish/seahorse@2x.png',
      'assets/original_fish/seahorseGold@2x.png',
      'assets/original_fish/anglerFish@2x.png',
      'assets/original_fish/gnarwal@2x.png',
      'assets/original_fish/dolphin@2x.png',
      'assets/original_fish/eel@2x.png',
      'assets/original_fish/boneFish@2x.png',
      'assets/original_fish/crab@2x.png',
      'assets/original_fish/clam@2x.png',
      'assets/original_fish/bass@2x.png',
      'assets/original_fish/cuttlefish@2x.png',
      'assets/original_fish/flounder@2x.png',
      'assets/original_fish/seaTurtle@2x.png',
      'assets/original_fish/frog@2x.png',
    ];

    for (final path in imagePaths) {
      try {
        final data = await rootBundle.load(path);
        final bytes = Uint8List.view(data.buffer);
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        final key = path.split('/').last;
        _cache[key] = frame.image;
      } catch (_) {}
    }
  }
}

// ─────────────────────────── LOADER SCREEN ──────────────────────────────────
class GameLoaderScreen extends StatefulWidget {
  const GameLoaderScreen({super.key});
  @override
  State<GameLoaderScreen> createState() => _GameLoaderScreenState();
}

class _GameLoaderScreenState extends State<GameLoaderScreen> {
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() => _progress = 0.4);
    await SpriteManager.instance.loadAll();
    setState(() => _progress = 1.0);
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const RidiculousFishingGame(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1A2A),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'RIDICULOUS',
              style: TextStyle(
                fontFamily: '04B03',
                color: Color(0xFFFF9E00),
                fontSize: 38,
                letterSpacing: 2,
              ),
            ),
            const Text(
              'FISHING',
              style: TextStyle(
                fontFamily: '04B03',
                color: Colors.white,
                fontSize: 26,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 36),
            SizedBox(
              width: 180,
              child: LinearProgressIndicator(
                value: _progress,
                color: const Color(0xFFFF9E00),
                backgroundColor: Colors.white12,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'A carregar Vlambeer Animated Sprites...',
              style: TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────── DATA STRUCTURES ────────────────────────────────
class FishData {
  final String key;
  final String sprite;
  final String displayName;
  final String description;
  final int value;
  final int health;
  final double minDepth;
  final double maxDepth;
  final double speed;
  final int cols;
  final int rows;
  final bool avoidsHook;
  final bool isJelly;

  const FishData({
    required this.key,
    required this.sprite,
    required this.displayName,
    required this.description,
    required this.value,
    required this.health,
    required this.minDepth,
    required this.maxDepth,
    required this.speed,
    required this.cols,
    required this.rows,
    this.avoidsHook = false,
    this.isJelly = false,
  });
}

// Exactly extracted from Vlambeer XML files with frame columns and rows
const List<FishData> kFishCatalog = [
  FishData(
    key: 'guppy',
    sprite: 'guppy@2x.png',
    displayName: 'Jim',
    description: 'This one with the chin was my friend once.',
    value: 3,
    health: 3,
    minDepth: 1,
    maxDepth: 100,
    speed: 1.5,
    cols: 2,
    rows: 2,
  ),
  FishData(
    key: 'guppyGold',
    sprite: 'guppyGold@2x.png',
    displayName: 'Golden Jim',
    description: 'A richer version of Jim.',
    value: 15,
    health: 6,
    minDepth: 30,
    maxDepth: 140,
    speed: 2.2,
    cols: 2,
    rows: 2,
    avoidsHook: true,
  ),
  FishData(
    key: 'pike',
    sprite: 'pike@2x.png',
    displayName: 'Turnpike',
    description: 'Rides a bike.',
    value: 10,
    health: 12,
    minDepth: 10,
    maxDepth: 180,
    speed: 2.5,
    cols: 4,
    rows: 2,
  ),
  FishData(
    key: 'bass',
    sprite: 'bass@2x.png',
    displayName: 'Bass',
    description: 'All about that bass.',
    value: 18,
    health: 20,
    minDepth: 20,
    maxDepth: 160,
    speed: 2.0,
    cols: 4,
    rows: 2,
  ),
  FishData(
    key: 'goldfish',
    sprite: 'goldfish@2x.png',
    displayName: 'Goldfish',
    description: 'A fish made out of gold colored fish.',
    value: 30,
    health: 8,
    minDepth: 50,
    maxDepth: 170,
    speed: 2.0,
    cols: 4,
    rows: 3,
    avoidsHook: true,
  ),
  FishData(
    key: 'jellySmall',
    sprite: 'jellySmall@2x.png',
    displayName: 'Boy-o-War',
    description: 'Based on the 2010 original. Makes you lose money!',
    value: -5,
    health: 1,
    minDepth: 60,
    maxDepth: 230,
    speed: 0.6,
    cols: 2,
    rows: 2,
    isJelly: true,
  ),
  FishData(
    key: 'seaTurtle',
    sprite: 'seaTurtle@2x.png',
    displayName: 'Sea Turtle',
    description: 'A very weird fish.',
    value: 25,
    health: 18,
    minDepth: 70,
    maxDepth: 250,
    speed: 1.2,
    cols: 4,
    rows: 2,
  ),
  FishData(
    key: 'seahorse',
    sprite: 'seahorse@2x.png',
    displayName: 'Day Horse',
    description: 'I wonder why little girls never get obsessed with seahorses...',
    value: 20,
    health: 6,
    minDepth: 150,
    maxDepth: 280,
    speed: 1.2,
    cols: 4,
    rows: 2,
  ),
  FishData(
    key: 'seahorseGold',
    sprite: 'seahorseGold@2x.png',
    displayName: 'Night Horse',
    description: 'Hey rich girls.',
    value: 60,
    health: 12,
    minDepth: 180,
    maxDepth: 290,
    speed: 2.0,
    cols: 4,
    rows: 2,
    avoidsHook: true,
  ),
  FishData(
    key: 'eel',
    sprite: 'eel@2x.png',
    displayName: 'Eel',
    description: 'Basically just a snake.',
    value: 35,
    health: 14,
    minDepth: 100,
    maxDepth: 260,
    speed: 2.8,
    cols: 4,
    rows: 2,
  ),
  FishData(
    key: 'frog',
    sprite: 'frog@2x.png',
    displayName: 'Froggo',
    description: 'Very rare, tastes good with some garlic.',
    value: 90,
    health: 10,
    minDepth: 70,
    maxDepth: 200,
    speed: 2.4,
    cols: 4,
    rows: 2,
    avoidsHook: true,
  ),
  FishData(
    key: 'anglerFish',
    sprite: 'anglerFish@2x.png',
    displayName: 'Anglerfish',
    description: 'A fish made of angles.',
    value: 50,
    health: 20,
    minDepth: 220,
    maxDepth: 295,
    speed: 1.0,
    cols: 4,
    rows: 2,
  ),
  FishData(
    key: 'jellyBig',
    sprite: 'jellyBig@2x.png',
    displayName: 'Man-o-War',
    description: 'R u jelly? Severe fine if shot!',
    value: -25,
    health: 1,
    minDepth: 160,
    maxDepth: 280,
    speed: 0.4,
    cols: 2,
    rows: 2,
    isJelly: true,
  ),
  FishData(
    key: 'gnarwal',
    sprite: 'gnarwal@2x.png',
    displayName: 'Gnarwal (Boss)',
    description: 'Long in the tooth. Chillin at the bottom of Home Waters.',
    value: 800,
    health: 140,
    minDepth: 290,
    maxDepth: 310,
    speed: 1.8,
    cols: 5,
    rows: 4,
  ),
];

// ─────────────────────────── GAMEPLAY ENTITIES ──────────────────────────────
enum GamePhase { phoneMenu, descending, ascending, airborne, summary }

class ActiveFish {
  final int id;
  final FishData data;
  double x, y, vx;
  double vy = 0;
  bool caught = false;
  double hookOffsetX = 0;
  double hookOffsetY = 0;
  double rotation = 0;
  double animTimer = 0;
  int currentHp;

  ActiveFish({
    required this.id,
    required this.data,
    required this.x,
    required this.y,
    required this.vx,
  }) : currentHp = data.health;
}

class ShotPellet {
  Offset from;
  Offset to;
  double t = 0;
  ShotPellet(this.from, this.to);
}

class SplashFx {
  Offset pos;
  double t = 0;
  SplashFx(this.pos);
}

class ScorePopup {
  Offset pos;
  String text;
  Color color;
  double t = 0;
  ScorePopup(this.pos, this.text, this.color);
}

// ─────────────────────────── MAIN GAME STATE ────────────────────────────────
class RidiculousFishingGame extends StatefulWidget {
  const RidiculousFishingGame({super.key});

  @override
  State<RidiculousFishingGame> createState() => _RidiculousFishingGameState();
}

class _RidiculousFishingGameState extends State<RidiculousFishingGame>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _lastTick = Duration.zero;
  Size _screenSize = Size.zero;
  final Random _rnd = Random();

  GamePhase _phase = GamePhase.phoneMenu;
  int _phoneTab = 0; // 0: Home/Play, 1: Fishopedia, 2: Shop, 3: Byrdr

  // Player Stats & Gear (Official IDs from storeContents.xml)
  int _money = 0;
  int _sessionGain = 0;
  int _comboCount = 0;
  double _comboTimer = 0;

  // Selected Equipment
  int _selectedReel = 0; // 0: 50m, 1: 100m, 2: 200m, 3: 300m, 4: 500m
  int _selectedGun = 0;  // 0: Pistol, 1: Shotgun, 2: Uzi, 3: Magnum, 4: Bazooka
  bool _hasChainsawLure = false;
  bool _isChainsawActive = false;
  double _fuel = 300.0;
  final double _maxFuel = 300.0;

  // Fishopedia discovered flags
  final Set<String> _discoveredFish = {};
  final Set<String> _ownedItems = {'reel_0', 'gun_0', 'lure_0'};

  // Movement & Camera
  double _hookX = 0;
  double _hookY = 0;
  double _targetHookX = 0;
  double _cameraY = 0;
  double _waveOffset = 0;
  bool _waveLeft = true;

  // Active game entities
  final List<ActiveFish> _fishes = [];
  final List<ShotPellet> _pellets = [];
  final List<SplashFx> _splashes = [];
  final List<ScorePopup> _popups = [];

  // Derived properties from tweaks.xml
  double get _maxDepthMeters {
    switch (_selectedReel) {
      case 0: return 50.0;
      case 1: return 100.0;
      case 2: return 200.0;
      case 3: return 300.0;
      case 4: return 500.0;
      default: return 50.0;
    }
  }

  int get _maxCaughtFish => 4 + _selectedReel * 2;

  late SharedPreferences _prefs;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
    _loadSave();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  Future<void> _loadSave() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _money = _prefs.getInt('rf_money') ?? 0;
      _selectedReel = _prefs.getInt('rf_reel') ?? 0;
      _selectedGun = _prefs.getInt('rf_gun') ?? 0;
      _hasChainsawLure = _prefs.getBool('rf_chainsaw') ?? false;

      final disc = _prefs.getStringList('rf_discovered') ?? [];
      _discoveredFish.addAll(disc);

      final owned = _prefs.getStringList('rf_owned') ?? ['reel_0', 'gun_0', 'lure_0'];
      _ownedItems.addAll(owned);

      _ready = true;
    });
  }

  Future<void> _saveGame() async {
    await _prefs.setInt('rf_money', _money);
    await _prefs.setInt('rf_reel', _selectedReel);
    await _prefs.setInt('rf_gun', _selectedGun);
    await _prefs.setBool('rf_chainsaw', _hasChainsawLure);
    await _prefs.setStringList('rf_discovered', _discoveredFish.toList());
    await _prefs.setStringList('rf_owned', _ownedItems.toList());
  }

  // ─────────────────────────── TICK & GAME LOOP ─────────────────────────────
  void _tick(Duration d) {
    final dt = ((d - _lastTick).inMicroseconds / 1e6).clamp(0.0, 0.04).toDouble();
    _lastTick = d;
    if (_screenSize == Size.zero || !_ready) return;

    _update(dt);
    setState(() {});
  }

  void _update(double dt) {
    // Wave animation
    if (_waveLeft) {
      _waveOffset -= 28 * dt;
      if (_waveOffset < -24) _waveLeft = false;
    } else {
      _waveOffset += 28 * dt;
      if (_waveOffset > 24) _waveLeft = true;
    }

    // Combo timer
    if (_comboCount > 0) {
      _comboTimer -= dt;
      if (_comboTimer <= 0) _comboCount = 0;
    }

    // Fuel consumption if chainsaw active
    if (_isChainsawActive && _phase == GamePhase.descending) {
      _fuel -= 70 * dt;
      if (_fuel <= 0) {
        _fuel = 0;
        _isChainsawActive = false;
      }
    }

    // Free fish swimming & animation ticker
    for (final f in _fishes) {
      f.animTimer += dt;
      if (!f.caught && _phase != GamePhase.airborne) {
        if (f.data.avoidsHook && (_phase == GamePhase.descending || _phase == GamePhase.ascending)) {
          final dx = f.x - _hookX;
          final dy = f.y - _hookY;
          final dist = sqrt(dx * dx + dy * dy);
          if (dist < 100) {
            f.vx += (dx > 0 ? 1 : -1) * 220 * dt;
            f.vx = f.vx.clamp(-180.0, 180.0);
          }
        }
        f.x += f.vx * dt;
        if (f.x < -80) f.x = _screenSize.width + 80;
        if (f.x > _screenSize.width + 80) f.x = -80;
      }
    }

    // Hook logic
    if (_phase == GamePhase.descending || _phase == GamePhase.ascending) {
      _hookX += (_targetHookX - _hookX) * min(1.0, dt * 9);
      _hookX = _hookX.clamp(20.0, _screenSize.width - 20.0);

      if (_phase == GamePhase.descending) {
        _hookY += (240 + _selectedReel * 20) * dt;
        _checkHookCollisions();
        if (_hookY >= _maxDepthMeters) {
          _phase = GamePhase.ascending;
          HapticFeedback.heavyImpact();
        }
      } else if (_phase == GamePhase.ascending) {
        _hookY -= (320 + _selectedReel * 25) * dt;
        _checkHookCollisions();
        if (_hookY <= 0) {
          _hookY = 0;
          _launchAirborne();
        }
      }

      // Drag hooked fish
      for (final f in _fishes.where((f) => f.caught)) {
        f.x = _hookX + f.hookOffsetX;
        f.y = _hookY + f.hookOffsetY;
      }

      // Smooth camera
      final targetCam = max(0.0, _hookY - _screenSize.height * 0.35);
      _cameraY += (targetCam - _cameraY) * min(1.0, dt * 7);
    } else if (_phase == GamePhase.airborne) {
      // Physics tuned exactly to tweaks.xml:
      // launchGravity: 0.06 (scaled), returnToWaterGravity: 1.3
      for (final f in _fishes) {
        final gravity = f.vy < 0 ? 240.0 : 650.0;
        f.vy += gravity * dt;
        f.y += f.vy * dt;
        f.x += f.vx * dt;
        f.rotation += (f.vx > 0 ? 3.5 : -3.5) * dt;

        // Wall bounce
        if (f.x < 30 || f.x > _screenSize.width - 30) f.vx = -f.vx * 0.8;
      }

      // Drop back in ocean
      _fishes.removeWhere((f) => f.y > 60 && f.vy > 0);
      if (_fishes.isEmpty) {
        _phase = GamePhase.summary;
        _money += _sessionGain;
        if (_money < 0) _money = 0;
        _saveGame();
        HapticFeedback.mediumImpact();
      }

      // Camera centering on airborne fish
      if (_fishes.isNotEmpty) {
        final highestY = _fishes.map((f) => f.y).reduce(min);
        final targetCam = min(0.0, highestY - 140.0);
        _cameraY += (targetCam - _cameraY) * min(1.0, dt * 6);
      } else {
        _cameraY += (0.0 - _cameraY) * min(1.0, dt * 5);
      }
    } else {
      _cameraY += (0.0 - _cameraY) * min(1.0, dt * 6);
    }

    // Effect timers
    for (final s in _splashes) s.t += dt;
    _splashes.removeWhere((s) => s.t >= 1.0);

    for (final b in _pellets) b.t += dt;
    _pellets.removeWhere((b) => b.t >= 0.12);

    for (final p in _popups) p.t += dt;
    _popups.removeWhere((p) => p.t >= 1.0);
  }

  void _checkHookCollisions() {
    int caughtCount = _fishes.where((f) => f.caught).length;
    for (final f in _fishes) {
      if (f.caught || caughtCount >= _maxCaughtFish) continue;

      final dx = f.x - _hookX;
      final dy = f.y - _hookY;
      final dist = sqrt(dx * dx + dy * dy);

      if (dist < 26.0) {
        // If chainsaw active on descent -> shred through fish without hooking!
        if (_isChainsawActive && _phase == GamePhase.descending) {
          f.currentHp = 0;
          _splashes.add(SplashFx(Offset(f.x, f.y)));
          _fishes.remove(f);
          HapticFeedback.lightImpact();
          break;
        }

        f.caught = true;
        f.hookOffsetX = (_rnd.nextDouble() - 0.5) * 36;
        f.hookOffsetY = 14 + _rnd.nextDouble() * 26;
        caughtCount++;
        _discoveredFish.add(f.data.key);
        HapticFeedback.selectionClick();

        // Reaching first fish on descent triggers ascension
        if (_phase == GamePhase.descending) {
          _phase = GamePhase.ascending;
        }
      }
    }
  }

  void _launchAirborne() {
    final caught = _fishes.where((f) => f.caught).toList();
    _fishes.clear();
    _fishes.addAll(caught);

    if (_fishes.isEmpty) {
      _phase = GamePhase.summary;
      return;
    }

    for (final f in _fishes) {
      f.y = -10;
      f.vy = -(460 + _rnd.nextDouble() * 260);
      f.vx = (_rnd.nextDouble() - 0.5) * 260;
    }
    _phase = GamePhase.airborne;
    HapticFeedback.heavyImpact();
  }

  // ─────────────────────────── BALLISTIC SHOOTING ───────────────────────────
  void _fireWeapon(Offset tapPos) {
    final worldY = tapPos.dy - (_screenSize.height * 0.38) + _cameraY;
    final worldPos = Offset(tapPos.dx, worldY);
    final boatPos = Offset(_screenSize.width * 0.5 + 40, -40);

    // Weapon mechanics matching tweaks.xml
    if (_selectedGun == 1) {
      // SHOTGUN: 9 pellets in spread cone (shotgunSpread: 160)
      for (int i = 0; i < 9; i++) {
        final spreadX = (_rnd.nextDouble() - 0.5) * 160;
        final spreadY = (_rnd.nextDouble() - 0.5) * 80;
        final target = worldPos.translate(spreadX, spreadY);
        _pellets.add(ShotPellet(boatPos, target));
        _damageAt(target, 5);
      }
    } else if (_selectedGun == 2) {
      // UZI: Rapid burst (uziSpread: 150)
      for (int i = 0; i < 3; i++) {
        final spreadX = (_rnd.nextDouble() - 0.5) * 50;
        final target = worldPos.translate(spreadX, 0);
        _pellets.add(ShotPellet(boatPos, target));
        _damageAt(target, 5);
      }
    } else if (_selectedGun == 3) {
      // MAGNUM: Heavy single punch (magnumDamage: 18)
      _pellets.add(ShotPellet(boatPos, worldPos));
      _damageAt(worldPos, 18);
    } else if (_selectedGun == 4) {
      // BAZOOKA: Massive area explosion (rpgDamage: 36, rpgExplosionSize: 80)
      _pellets.add(ShotPellet(boatPos, worldPos));
      _areaDamage(worldPos, 80, 36);
    } else {
      // PISTOL: Ol' Trusty (pistolDamage: 3)
      _pellets.add(ShotPellet(boatPos, worldPos));
      _damageAt(worldPos, 3);
    }

    HapticFeedback.mediumImpact();
  }

  void _damageAt(Offset pos, int damage) {
    ActiveFish? hit;
    double bestDist = 55.0;
    for (final f in _fishes) {
      final d = (Offset(f.x, f.y) - pos).distance;
      if (d < bestDist) {
        bestDist = d;
        hit = f;
      }
    }
    if (hit != null) _applyDamage(hit, damage);
  }

  void _areaDamage(Offset center, double radius, int damage) {
    final targets = _fishes.where((f) => (Offset(f.x, f.y) - center).distance <= radius).toList();
    for (final t in targets) {
      _applyDamage(t, damage);
    }
  }

  void _applyDamage(ActiveFish f, int damage) {
    f.currentHp -= damage;
    _splashes.add(SplashFx(Offset(f.x, f.y)));

    if (f.currentHp <= 0) {
      _fishes.remove(f);

      if (f.data.isJelly) {
        // Jelly penalty
        _sessionGain += f.data.value;
        _popups.add(ScorePopup(
          Offset(f.x, f.y),
          '${f.data.value} \$',
          const Color(0xFFFF1744),
        ));
      } else {
        _comboCount++;
        _comboTimer = 1.3;
        final multiplier = _comboCount > 1 ? _comboCount : 1;
        final score = f.data.value * multiplier;
        _sessionGain += score;

        _popups.add(ScorePopup(
          Offset(f.x, f.y),
          '+$score${_comboCount > 1 ? " x$_comboCount" : ""}',
          _comboCount > 2 ? const Color(0xFFFF5252) : const Color(0xFFFFD700),
        ));
      }
    }
  }

  // ─────────────────────────── GAME LAUNCH ──────────────────────────────────
  void _startFishingSession() {
    _fishes.clear();
    _pellets.clear();
    _splashes.clear();
    _popups.clear();
    _sessionGain = 0;
    _comboCount = 0;
    _fuel = _maxFuel;
    _isChainsawActive = false;

    final fishCount = max(18, (_maxDepthMeters / 12).round());
    for (int i = 0; i < fishCount; i++) {
      final depth = 15.0 + _rnd.nextDouble() * (_maxDepthMeters - 20.0);
      final eligible = kFishCatalog.where((s) => depth >= s.minDepth && depth <= s.maxDepth).toList();
      final spec = eligible.isNotEmpty ? eligible[_rnd.nextInt(eligible.length)] : kFishCatalog[0];

      final dir = _rnd.nextBool() ? 1.0 : -1.0;
      final speed = (spec.speed * 42.0 + _rnd.nextDouble() * 20.0) * dir;

      _fishes.add(ActiveFish(
        id: i,
        data: spec,
        x: _rnd.nextDouble() * _screenSize.width,
        y: depth,
        vx: speed,
      ));
    }

    _hookX = _screenSize.width * 0.5;
    _targetHookX = _hookX;
    _hookY = 0;
    _cameraY = 0;
    _phase = GamePhase.descending;
  }

  // ─────────────────────────── BUILD METHOD ─────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(builder: (ctx, constraints) {
        _screenSize = constraints.biggest;
        return GestureDetector(
          onTapDown: (e) {
            _targetHookX = e.localPosition.dx;
            if (_phase == GamePhase.airborne) _fireWeapon(e.localPosition);
            if (_phase == GamePhase.descending && _hasChainsawLure && _fuel > 0) {
              setState(() => _isChainsawActive = true);
            }
          },
          onTapUp: (_) {
            if (_isChainsawActive) setState(() => _isChainsawActive = false);
          },
          onPanUpdate: (e) {
            _targetHookX = e.localPosition.dx;
            if (_phase == GamePhase.airborne && _selectedGun == 2) {
              _fireWeapon(e.localPosition);
            }
          },
          child: Stack(
            children: [
              // Custom Painter Engine
              Positioned.fill(
                child: CustomPaint(
                  painter: _RidiculousPainter(
                    fishes: _fishes,
                    splashes: _splashes,
                    pellets: _pellets,
                    popups: _popups,
                    phase: _phase,
                    hookX: _hookX,
                    hookY: _hookY,
                    cameraY: _cameraY,
                    waveOffset: _waveOffset,
                    screenSize: _screenSize,
                    isChainsawActive: _isChainsawActive,
                  ),
                ),
              ),

              // HUD & Fuel Meter
              if (_phase != GamePhase.phoneMenu) _buildGameHUD(),

              // The Byrd Wood Phone Overlay Menu
              if (_phase == GamePhase.phoneMenu || _phase == GamePhase.summary)
                _buildPhoneInterface(),
            ],
          ),
        );
      }),
    );
  }

  // ─────────────────────────── HUD ─────────────────────────────────────────
  Widget _buildGameHUD() {
    final depth = _hookY.round();
    final caught = _fishes.where((f) => f.caught).length;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '\$$_money',
                  style: const TextStyle(
                    fontFamily: '04B03',
                    color: Color(0xFFFF9E00),
                    fontSize: 32,
                  ),
                ),
                if (_phase == GamePhase.descending || _phase == GamePhase.ascending)
                  Text(
                    '${depth}m  |  $caught/$_maxCaughtFish',
                    style: const TextStyle(
                      fontFamily: '04B03',
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                if (_phase == GamePhase.airborne && _comboCount > 1)
                  Text(
                    'COMBO x$_comboCount!',
                    style: const TextStyle(
                      fontFamily: '04B03',
                      color: Color(0xFFFF3D00),
                      fontSize: 22,
                    ),
                  ),
              ],
            ),
            // Chainsaw Fuel Gauge
            if (_phase == GamePhase.descending && _hasChainsawLure) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Text('FUEL: ', style: TextStyle(fontFamily: '04B03', color: Colors.white70, fontSize: 10)),
                  Container(
                    width: 120,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: (_fuel / _maxFuel).clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _isChainsawActive ? const Color(0xFFFF3D00) : const Color(0xFF00E676),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─────────────────────────── BYRD WOOD PHONE UI ───────────────────────────
  Widget _buildPhoneInterface() {
    return Center(
      child: Container(
        width: 340,
        height: 620,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF3E2723), // Wood shell
          borderRadius: BorderRadius.circular(36),
          border: Border.all(color: const Color(0xFF2E1C0C), width: 6),
          boxShadow: const [
            BoxShadow(color: Colors.black87, blurRadius: 28, offset: Offset(0, 12)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Column(
            children: [
              // Phone Top Bar
              Container(
                height: 38,
                color: const Color(0xFF1E130A),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('BYRD PHONE', style: TextStyle(fontFamily: '04B03', color: Color(0xFFFF9E00), fontSize: 11)),
                    Text('\$$_money', style: const TextStyle(fontFamily: '04B03', color: Colors.white, fontSize: 13)),
                  ],
                ),
              ),

              // Phone Screen Body
              Expanded(
                child: Container(
                  color: const Color(0xFF111D2E),
                  child: _buildPhoneTabContent(),
                ),
              ),

              // Phone Bottom Navigation Dock
              Container(
                height: 62,
                color: const Color(0xFF1E130A),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _phoneNavBtn(0, Icons.sailing, 'PESCAR'),
                    _phoneNavBtn(1, Icons.menu_book, 'PEIXES'),
                    _phoneNavBtn(2, Icons.shopping_bag, 'LOJA'),
                    _phoneNavBtn(3, Icons.chat, 'BYRDR'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _phoneNavBtn(int tabIndex, IconData icon, String label) {
    final active = _phoneTab == tabIndex;
    return GestureDetector(
      onTap: () => setState(() => _phoneTab = tabIndex),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: active ? const Color(0xFFFF9E00) : Colors.white38, size: 22),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontFamily: '04B03',
              color: active ? const Color(0xFFFF9E00) : Colors.white38,
              fontSize: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneTabContent() {
    switch (_phoneTab) {
      case 0: return _buildPlayScreen();
      case 1: return _buildFishopediaScreen();
      case 2: return _buildShopScreen();
      case 3: return _buildByrdrScreen();
      default: return _buildPlayScreen();
    }
  }

  // 1. PLAY / MAPS
  Widget _buildPlayScreen() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'HOME WATERS',
            style: TextStyle(fontFamily: '04B03', color: Color(0xFFFF9E00), fontSize: 24),
          ),
          const SizedBox(height: 8),
          Text(
            'Linha: ${_maxDepthMeters.round()}m  |  Anzóis: $_maxCaughtFish',
            style: const TextStyle(fontFamily: '04B03', color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF9E00),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 42, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 8,
            ),
            onPressed: _startFishingSession,
            child: const Text(
              'LANCAR LINHA!',
              style: TextStyle(fontFamily: '04B03', fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // 2. FISHOPEDIA
  Widget _buildFishopediaScreen() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: kFishCatalog.length,
      itemBuilder: (_, i) {
        final f = kFishCatalog[i];
        final discovered = _discoveredFish.contains(f.key);
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF1B2A40),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: discovered ? const Color(0xFFFF9E00).withOpacity(0.5) : Colors.white10),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: discovered
                    ? CustomPaint(
                        painter: _FishPreviewPainter(f),
                      )
                    : const Icon(Icons.help_outline, color: Colors.white24, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      discovered ? f.displayName : '???',
                      style: TextStyle(
                        fontFamily: '04B03',
                        color: discovered ? const Color(0xFFFF9E00) : Colors.white38,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      discovered ? f.description : 'Ainda não pescado em Home Waters.',
                      style: const TextStyle(color: Colors.white60, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 3. STORE
  Widget _buildShopScreen() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const Text('CARRETEIS (LINHAS)', style: TextStyle(fontFamily: '04B03', color: Color(0xFFFF9E00), fontSize: 11)),
        const SizedBox(height: 6),
        _shopItem('100m Line', '40 \$', 40, 'reel_1', () {
          setState(() {
            _money -= 40;
            _selectedReel = 1;
            _ownedItems.add('reel_1');
          });
          _saveGame();
        }),
        _shopItem('200m Line', '250 \$', 250, 'reel_2', () {
          setState(() {
            _money -= 250;
            _selectedReel = 2;
            _ownedItems.add('reel_2');
          });
          _saveGame();
        }),
        _shopItem('300m Line', '500 \$', 500, 'reel_3', () {
          setState(() {
            _money -= 500;
            _selectedReel = 3;
            _ownedItems.add('reel_3');
          });
          _saveGame();
        }),

        const SizedBox(height: 14),
        const Text('ARMAS DE DISPARO', style: TextStyle(fontFamily: '04B03', color: Color(0xFFFF9E00), fontSize: 11)),
        const SizedBox(height: 6),
        _shopItem('Shotgun (9 chumbos)', '200 \$', 200, 'gun_1', () {
          setState(() {
            _money -= 200;
            _selectedGun = 1;
            _ownedItems.add('gun_1');
          });
          _saveGame();
        }),
        _shopItem('Uzi (Rajada Rapida)', '580 \$', 580, 'gun_2', () {
          setState(() {
            _money -= 580;
            _selectedGun = 2;
            _ownedItems.add('gun_2');
          });
          _saveGame();
        }),
        _shopItem('Magnum (Dano 18)', '3000 \$', 3000, 'gun_3', () {
          setState(() {
            _money -= 3000;
            _selectedGun = 3;
            _ownedItems.add('gun_3');
          });
          _saveGame();
        }),
        _shopItem('Bazooka (Dano 36)', '50000 \$', 50000, 'gun_4', () {
          setState(() {
            _money -= 50000;
            _selectedGun = 4;
            _ownedItems.add('gun_4');
          });
          _saveGame();
        }),

        const SizedBox(height: 14),
        const Text('ISCAS ESPECIAIS', style: TextStyle(fontFamily: '04B03', color: Color(0xFFFF9E00), fontSize: 11)),
        const SizedBox(height: 6),
        _shopItem('Chainsaw Lure', '120 \$', 120, 'lure_chainsaw', () {
          setState(() {
            _money -= 120;
            _hasChainsawLure = true;
            _ownedItems.add('lure_chainsaw');
          });
          _saveGame();
        }),
      ],
    );
  }

  Widget _shopItem(String name, String costStr, int cost, String itemId, VoidCallback onBuy) {
    final owned = _ownedItems.contains(itemId);
    final canBuy = _money >= cost;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2A40),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: const TextStyle(fontFamily: '04B03', color: Colors.white, fontSize: 11)),
          owned
              ? const Text('COMPRADO', style: TextStyle(fontFamily: '04B03', color: Color(0xFF00E676), fontSize: 10))
              : ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canBuy ? const Color(0xFFFF9E00) : Colors.white12,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  ),
                  onPressed: canBuy ? onBuy : null,
                  child: Text(costStr, style: const TextStyle(fontFamily: '04B03', fontSize: 10)),
                ),
        ],
      ),
    );
  }

  // 4. BYRDR
  Widget _buildByrdrScreen() {
    final tweets = [
      {'user': '@vicebeak', 'msg': 'Yo, Chirp! Anyone out at Home Waters?'},
      {'user': '@OG_RodAndGun', 'msg': 'Breaking Bad! Auuugh we need satellite on this ship.'},
      {'user': '@BigInASmallPond', 'msg': 'My naturopath tells me I have a gluten allergy.'},
      {'user': '@GreatOceanDeals', 'msg': 'Feeling lonely #lovesick #wheresmyshipman #port2port'},
      {'user': '@RodAndGunMan', 'msg': 'Ridiculous. Fishing for compliments.'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: tweets.length,
      itemBuilder: (_, i) {
        final t = tweets[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF1B2A40),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t['user']!, style: const TextStyle(fontFamily: '04B03', color: Color(0xFFFF9E00), fontSize: 11)),
              const SizedBox(height: 4),
              Text(t['msg']!, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────── FISHOPEDIA PREVIEW ─────────────────────────────
class _FishPreviewPainter extends CustomPainter {
  final FishData fish;
  _FishPreviewPainter(this.fish);

  @override
  void paint(Canvas canvas, Size size) {
    final sprite = SpriteManager.instance.get(fish.sprite);
    if (sprite == null) return;
    final frameW = sprite.width / fish.cols;
    final frameH = sprite.height / fish.rows;
    final srcRect = Rect.fromLTWH(0, 0, frameW, frameH);
    final destRect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawImageRect(sprite, srcRect, destRect, Paint());
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─────────────────────────── GAME CANVAS PAINTER ────────────────────────────
class _RidiculousPainter extends CustomPainter {
  final List<ActiveFish> fishes;
  final List<SplashFx> splashes;
  final List<ShotPellet> pellets;
  final List<ScorePopup> popups;
  final GamePhase phase;
  final double hookX;
  final double hookY;
  final double cameraY;
  final double waveOffset;
  final Size screenSize;
  final bool isChainsawActive;

  _RidiculousPainter({
    required this.fishes,
    required this.splashes,
    required this.pellets,
    required this.popups,
    required this.phase,
    required this.hookX,
    required this.hookY,
    required this.cameraY,
    required this.waveOffset,
    required this.screenSize,
    required this.isChainsawActive,
  });

  double get surfaceY => screenSize.height * 0.38;
  double worldToScreenY(double y) => surfaceY + y - cameraY;

  @override
  void paint(Canvas canvas, Size size) {
    final mgr = SpriteManager.instance;
    final sy0 = worldToScreenY(0);

    // 1. EXACT VLAMBEER SKY PALETTE (pond.xml)
    if (sy0 > 0) {
      final skyRect = Rect.fromLTWH(0, 0, size.width, sy0);
      canvas.drawRect(
        skyRect,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF00FFFF),
              Color(0xFF00C5F0),
              Color(0xFF506CE0),
              Color(0xFF6C41BA),
            ],
          ).createShader(skyRect),
      );
    }

    // 2. EXACT VLAMBEER SEA PALETTE (pond.xml)
    final waterTop = max(0.0, sy0);
    final waterRect = Rect.fromLTWH(0, waterTop, size.width, size.height - waterTop);
    canvas.drawRect(
      waterRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF00FD9E),
            Color(0xFF00BC8F),
            Color(0xFF6188B8),
            Color(0xFF9955B9),
            Color(0xFF1B4F5A),
            Color(0xFF00312A),
            Color(0xFF021114),
          ],
        ).createShader(waterRect),
    );

    // 3. MOVING SURFACE WAVE
    final waveSprite = mgr.get('wave.png');
    if (waveSprite != null) {
      final waveW = size.width * 1.3;
      canvas.drawImageRect(
        waveSprite,
        Rect.fromLTWH(0, 0, waveSprite.width.toDouble(), waveSprite.height.toDouble()),
        Rect.fromLTWH(waveOffset - 20, sy0 - 13, waveW, 26.0),
        Paint()..color = Colors.white.withOpacity(0.9),
      );
    }

    // 4. ACTIVE ANIMATED FISHES (SPRITESHEET FRAME SLICING!)
    for (final f in fishes) {
      final screenY = worldToScreenY(f.y);
      if (screenY < -120 || screenY > size.height + 120) continue;

      final sprite = mgr.get(f.data.sprite);
      if (sprite != null) {
        canvas.save();
        canvas.translate(f.x, screenY);
        canvas.rotate(f.rotation);

        final facingLeft = f.vx < 0;
        if (facingLeft) canvas.scale(-1, 1);

        // Calculate active animation frame from Vlambeer XML grid specs
        final totalFrames = f.data.cols * f.data.rows;
        final frameIndex = ((f.animTimer * 9.0).floor()) % totalFrames;
        final frameCol = frameIndex % f.data.cols;
        final frameRow = frameIndex ~/ f.data.cols;
        final frameW = sprite.width / f.data.cols;
        final frameH = sprite.height / f.data.rows;

        final srcRect = Rect.fromLTWH(frameCol * frameW, frameRow * frameH, frameW, frameH);
        final destRect = Rect.fromCenter(center: Offset.zero, width: frameW * 0.9, height: frameH * 0.9);

        canvas.drawImageRect(sprite, srcRect, destRect, Paint());
        canvas.restore();
      }
    }

    // 5. FISHING LINE & LURE / CHAINSAW
    final boatTip = Offset(size.width * 0.5 + 46, sy0 - 24);
    final isHookActive = phase == GamePhase.descending || phase == GamePhase.ascending;
    final hookScreenPos = isHookActive ? Offset(hookX, worldToScreenY(hookY)) : Offset(boatTip.dx, sy0 - 5);

    canvas.drawLine(boatTip, hookScreenPos, Paint()..color = Colors.white70..strokeWidth = 1.6);

    if (isHookActive) {
      final lureKey = isChainsawActive ? 'lure4_swipe@2x.png' : 'lure0@2x.png';
      final lureSprite = mgr.get(lureKey) ?? mgr.get('hook.png');
      if (lureSprite != null) {
        final lw = 28.0;
        final lh = 38.0;
        canvas.drawImageRect(
          lureSprite,
          Rect.fromLTWH(0, 0, lureSprite.width.toDouble(), lureSprite.height.toDouble()),
          Rect.fromLTWH(hookScreenPos.dx - lw / 2, hookScreenPos.dy, lw, lh),
          Paint(),
        );
      }
    }

    // 6. OFFICIAL BOAT & OFFICIAL BILLY ANIMATIONS!
    final boatSprite = mgr.get('shop_BG_boat@2x.png') ?? mgr.get('ship.png');
    final bx = size.width * 0.5;
    final by = sy0;

    if (boatSprite != null) {
      final bw = 150.0;
      final bh = bw * (boatSprite.height / boatSprite.width);
      canvas.drawImageRect(
        boatSprite,
        Rect.fromLTWH(0, 0, boatSprite.width.toDouble(), boatSprite.height.toDouble()),
        Rect.fromCenter(center: Offset(bx, by - 12), width: bw, height: bh),
        Paint(),
      );
    }

    // Official Billy sitting in boat or shooting up into the sky!
    final billySprite = (phase == GamePhase.airborne)
        ? mgr.get('BillyNormalShoot@2x.png')
        : mgr.get('BillyNormalFish@2x.png');

    if (billySprite != null) {
      if (phase == GamePhase.airborne) {
        // Billy pointing gun straight up
        final bw = 42.0;
        final bh = bw * (billySprite.height / billySprite.width);
        canvas.drawImageRect(
          billySprite,
          Rect.fromLTWH(0, 0, billySprite.width.toDouble(), billySprite.height.toDouble()),
          Rect.fromCenter(center: Offset(bx + 10, by - 46), width: bw, height: bh),
          Paint(),
        );
      } else {
        // Billy sitting with fishing rod
        final bw = 68.0;
        final bh = bw * (billySprite.height / billySprite.width);
        canvas.drawImageRect(
          billySprite,
          Rect.fromLTWH(0, 0, billySprite.width.toDouble(), billySprite.height.toDouble()),
          Rect.fromCenter(center: Offset(bx + 6, by - 40), width: bw, height: bh),
          Paint(),
        );
      }
    }

    // 7. WEAPON PELLETS / BULLETS
    for (final b in pellets) {
      final a = (1.0 - (b.t / 0.12)).clamp(0.0, 1.0);
      final bulletSprite = mgr.get('bullet.png');
      final target = Offset(b.to.dx, worldToScreenY(b.to.dy));
      if (bulletSprite != null) {
        canvas.drawImageRect(
          bulletSprite,
          Rect.fromLTWH(0, 0, bulletSprite.width.toDouble(), bulletSprite.height.toDouble()),
          Rect.fromCenter(center: target, width: 14, height: 14),
          Paint()..color = Colors.white.withOpacity(a),
        );
      }
      canvas.drawLine(
        Offset(b.from.dx, b.from.dy - cameraY + surfaceY),
        target,
        Paint()
          ..color = Colors.yellowAccent.withOpacity(a)
          ..strokeWidth = 2.5,
      );
    }

    // 8. BLOOD SPLATTERS
    final bloodSprite = mgr.get('blood.png');
    for (final s in splashes) {
      final a = (1.0 - s.t).clamp(0.0, 1.0);
      final sy = worldToScreenY(s.pos.dy);
      if (bloodSprite != null) {
        final bw = 48.0 * (1.0 + s.t * 0.4);
        canvas.drawImageRect(
          bloodSprite,
          Rect.fromLTWH(0, 0, bloodSprite.width.toDouble(), bloodSprite.height.toDouble()),
          Rect.fromCenter(center: Offset(s.pos.dx, sy), width: bw, height: bw),
          Paint()..color = Colors.white.withOpacity(a),
        );
      }
    }

    // 9. POPUPS
    for (final p in popups) {
      final a = (1.0 - p.t).clamp(0.0, 1.0);
      final sy = worldToScreenY(p.pos.dy) - p.t * 50;
      final tp = TextPainter(
        text: TextSpan(
          text: p.text,
          style: TextStyle(
            fontFamily: '04B03',
            color: p.color.withOpacity(a),
            fontSize: 20,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(p.pos.dx - tp.width / 2, sy));
    }
  }

  @override
  bool shouldRepaint(covariant _RidiculousPainter old) => true;
}
