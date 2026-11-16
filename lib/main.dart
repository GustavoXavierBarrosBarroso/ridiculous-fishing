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
      // Base assets
      'assets/images/ship.png',
      'assets/images/fisherman.png',
      'assets/images/hook.png',
      'assets/images/deephook.png',
      'assets/images/wave.png',
      'assets/images/blood.png',
      'assets/images/bullet.png',
      'assets/images/machineGun.png',
      'assets/images/singleShot.png',
      // Authentic Vlambeer fish assets directly extracted from APK
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
    ];

    for (final path in imagePaths) {
      try {
        final data = await rootBundle.load(path);
        final bytes = Uint8List.view(data.buffer);
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        final key = path.split('/').last;
        _cache[key] = frame.image;
      } catch (_) {
        // Fallback gracefully if single image fails
      }
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
    setState(() => _progress = 0.3);
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
              'A carregar Vlambeer APK Assets...',
              style: TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────── ORIGINAL FISH SPECS ────────────────────────────
class FishSpec {
  final String sprite;
  final String name;
  final int value;
  final int health;
  final double minDepth;
  final double maxDepth;
  final double speed;
  final bool avoidsHook;
  final bool isJelly; // causes penalty if shot

  const FishSpec({
    required this.sprite,
    required this.name,
    required this.value,
    required this.health,
    required this.minDepth,
    required this.maxDepth,
    required this.speed,
    this.avoidsHook = false,
    this.isJelly = false,
  });
}

// Exact specs directly from Vlambeer's pond.xml and Fish XML files
const List<FishSpec> kOriginalSpecs = [
  FishSpec(sprite: 'guppy@2x.png', name: 'Guppy', value: 3, health: 3, minDepth: 1, maxDepth: 100, speed: 1.5),
  FishSpec(sprite: 'guppyGold@2x.png', name: 'Golden Guppy', value: 15, health: 6, minDepth: 30, maxDepth: 140, speed: 2.2, avoidsHook: true),
  FishSpec(sprite: 'bass@2x.png', name: 'Bass', value: 8, health: 8, minDepth: 20, maxDepth: 150, speed: 1.8),
  FishSpec(sprite: 'pike@2x.png', name: 'Pike', value: 10, health: 12, minDepth: 30, maxDepth: 180, speed: 2.5),
  FishSpec(sprite: 'goldfish@2x.png', name: 'Goldfish', value: 30, health: 8, minDepth: 50, maxDepth: 170, speed: 2.0, avoidsHook: true),
  FishSpec(sprite: 'jellySmall@2x.png', name: 'Jellyfish', value: -5, health: 1, minDepth: 60, maxDepth: 230, speed: 0.6, isJelly: true),
  FishSpec(sprite: 'jellyBig@2x.png', name: 'Big Jellyfish', value: -15, health: 1, minDepth: 160, maxDepth: 280, speed: 0.4, isJelly: true),
  FishSpec(sprite: 'seahorse@2x.png', name: 'Seahorse', value: 20, health: 6, minDepth: 150, maxDepth: 280, speed: 1.2),
  FishSpec(sprite: 'seahorseGold@2x.png', name: 'Golden Seahorse', value: 60, health: 12, minDepth: 180, maxDepth: 290, speed: 2.0, avoidsHook: true),
  FishSpec(sprite: 'eel@2x.png', name: 'Electric Eel', value: 25, health: 14, minDepth: 100, maxDepth: 260, speed: 2.8),
  FishSpec(sprite: 'boneFish@2x.png', name: 'Bone Fish', value: 35, health: 16, minDepth: 140, maxDepth: 280, speed: 1.7),
  FishSpec(sprite: 'anglerFish@2x.png', name: 'Angler Fish', value: 50, health: 20, minDepth: 220, maxDepth: 350, speed: 1.0),
  FishSpec(sprite: 'dolphin@2x.png', name: 'Dolphin', value: 120, health: 40, minDepth: 100, maxDepth: 300, speed: 3.2, avoidsHook: true),
  FishSpec(sprite: 'gnarwal@2x.png', name: 'Gnarwal (Boss)', value: 800, health: 140, minDepth: 290, maxDepth: 400, speed: 2.0),
];

// ─────────────────────────── MODELS ─────────────────────────────────────────
enum GamePhase { menu, descending, ascending, airborne, gameOver }

class FishEntity {
  final int id;
  final FishSpec spec;

  double x;
  double y;
  double vx;
  double vy = 0;
  bool isCaught = false;
  double caughtOffsetX = 0;
  double caughtOffsetY = 0;
  double rotation = 0;
  int currentHealth;

  FishEntity({
    required this.id,
    required this.spec,
    required this.x,
    required this.y,
    required this.vx,
  }) : currentHealth = spec.health;
}

class BloodSplash {
  Offset position;
  double time = 0;
  final double maxTime = 1.0;
  BloodSplash(this.position);
}

class BulletFx {
  Offset from;
  Offset to;
  double t = 0;
  BulletFx(this.from, this.to);
}

class PopupText {
  Offset position;
  String text;
  Color color;
  double t = 0;
  PopupText(this.position, this.text, this.color);
}

// ─────────────────────────── MAIN GAME WIDGET ───────────────────────────────
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

  GamePhase _phase = GamePhase.menu;
  int _money = 0;
  int _sessionScore = 0;
  int _combo = 0;
  double _comboTimer = 0;

  // Upgrades
  int _depthLvl = 0; // max depth
  int _hooksLvl = 0; // max caught
  int _gunLvl = 0;   // 0: Pistol, 1: MachineGun, 2: Shotgun

  double get _maxDepth => 300.0 + 150.0 * _depthLvl;
  int get _maxCaughtFish => 4 + 3 * _hooksLvl;
  double get _hookRadius => 24.0;

  // Position trackers
  double _hookX = 0;
  double _hookY = 0;
  double _targetHookX = 0;
  double _cameraY = 0;
  double _waveOffset = 0;
  bool _waveDirectionLeft = true;

  // Entities
  final List<FishEntity> _fishes = [];
  final List<BloodSplash> _splashes = [];
  final List<BulletFx> _bullets = [];
  final List<PopupText> _popups = [];

  late SharedPreferences _prefs;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
    _loadState();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  Future<void> _loadState() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _money = _prefs.getInt('rf_money') ?? 0;
      _depthLvl = _prefs.getInt('rf_depth') ?? 0;
      _hooksLvl = _prefs.getInt('rf_hooks') ?? 0;
      _gunLvl = _prefs.getInt('rf_gun') ?? 0;
      _ready = true;
    });
  }

  Future<void> _saveState() async {
    await _prefs.setInt('rf_money', _money);
    await _prefs.setInt('rf_depth', _depthLvl);
    await _prefs.setInt('rf_hooks', _hooksLvl);
    await _prefs.setInt('rf_gun', _gunLvl);
  }

  void _tick(Duration d) {
    final dt = ((d - _lastTick).inMicroseconds / 1e6).clamp(0.0, 0.04).toDouble();
    _lastTick = d;
    if (_screenSize == Size.zero || !_ready) return;

    _update(dt);
    setState(() {});
  }

  // ─────────────────────────── GAME UPDATE ──────────────────────────────────
  void _update(double dt) {
    // Wave oscillation
    if (_waveDirectionLeft) {
      _waveOffset -= 30 * dt;
      if (_waveOffset < -25) _waveDirectionLeft = false;
    } else {
      _waveOffset += 30 * dt;
      if (_waveOffset > 25) _waveDirectionLeft = true;
    }

    // Combo timer
    if (_combo > 0) {
      _comboTimer -= dt;
      if (_comboTimer <= 0) _combo = 0;
    }

    // Swimming fish in sea
    for (final f in _fishes) {
      if (!f.isCaught && _phase != GamePhase.airborne) {
        // Dodge hook if species avoids
        if (f.spec.avoidsHook && (_phase == GamePhase.descending || _phase == GamePhase.ascending)) {
          final dx = f.x - _hookX;
          final dy = f.y - _hookY;
          final dist = sqrt(dx * dx + dy * dy);
          if (dist < 100) {
            f.vx += (dx > 0 ? 1 : -1) * 200 * dt;
            f.vx = f.vx.clamp(-180.0, 180.0);
          }
        }

        f.x += f.vx * dt;
        if (f.x < -80) f.x = _screenSize.width + 80;
        if (f.x > _screenSize.width + 80) f.x = -80;
      }
    }

    // Hook movement
    if (_phase == GamePhase.descending || _phase == GamePhase.ascending) {
      _hookX += (_targetHookX - _hookX) * min(1.0, dt * 9);
      _hookX = _hookX.clamp(20.0, _screenSize.width - 20.0);

      if (_phase == GamePhase.descending) {
        _hookY += (240 + _depthLvl * 25) * dt;
        _checkHookCollisions();
        if (_hookY >= _maxDepth) {
          _phase = GamePhase.ascending;
          HapticFeedback.heavyImpact();
        }
      } else if (_phase == GamePhase.ascending) {
        _hookY -= (300 + _depthLvl * 30) * dt;
        _checkHookCollisions();
        if (_hookY <= 0) {
          _hookY = 0;
          _launchAirborne();
        }
      }

      // Drag caught fish
      for (final f in _fishes.where((f) => f.isCaught)) {
        f.x = _hookX + f.caughtOffsetX;
        f.y = _hookY + f.caughtOffsetY;
      }

      // Camera follows hook
      final targetCam = max(0.0, _hookY - _screenSize.height * 0.35);
      _cameraY += (targetCam - _cameraY) * min(1.0, dt * 7);
    } else if (_phase == GamePhase.airborne) {
      // Airborne physics
      for (final f in _fishes) {
        f.vy += 600 * dt; // Gravity
        f.y += f.vy * dt;
        f.x += f.vx * dt;
        f.rotation += (f.vx > 0 ? 3 : -3) * dt;

        // Bounce off screen walls
        if (f.x < 30 || f.x > _screenSize.width - 30) f.vx = -f.vx * 0.8;
      }

      // Remove fish that fell below water line
      _fishes.removeWhere((f) => f.y > 60 && f.vy > 0);
      if (_fishes.isEmpty) {
        _phase = GamePhase.gameOver;
        _money += _sessionScore;
        if (_money < 0) _money = 0;
        _saveState();
        HapticFeedback.mediumImpact();
      }

      // Camera smoothly centers around highest fish
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

    // Splashes & Particles
    for (final s in _splashes) s.time += dt;
    _splashes.removeWhere((s) => s.time >= s.maxTime);

    // Bullet animations
    for (final b in _bullets) b.t += dt;
    _bullets.removeWhere((b) => b.t >= 0.12);

    // Floating texts
    for (final p in _popups) p.t += dt;
    _popups.removeWhere((p) => p.t >= 1.0);
  }

  void _checkHookCollisions() {
    int caughtCount = _fishes.where((f) => f.isCaught).length;
    for (final f in _fishes) {
      if (f.isCaught || caughtCount >= _maxCaughtFish) continue;

      final dx = f.x - _hookX;
      final dy = f.y - _hookY;
      final dist = sqrt(dx * dx + dy * dy);

      if (dist < _hookRadius + 22.0) {
        f.isCaught = true;
        f.caughtOffsetX = (_rnd.nextDouble() - 0.5) * 40;
        f.caughtOffsetY = 15 + _rnd.nextDouble() * 30;
        caughtCount++;
        HapticFeedback.selectionClick();

        // If touching fish on descend -> trigger ascension immediately!
        if (_phase == GamePhase.descending) {
          _phase = GamePhase.ascending;
        }
      }
    }
  }

  void _launchAirborne() {
    final caught = _fishes.where((f) => f.isCaught).toList();
    _fishes.clear();
    _fishes.addAll(caught);

    if (_fishes.isEmpty) {
      _phase = GamePhase.gameOver;
      return;
    }

    for (final f in _fishes) {
      f.y = -10;
      f.vy = -(440 + _rnd.nextDouble() * 260);
      f.vx = (_rnd.nextDouble() - 0.5) * 260;
    }
    _phase = GamePhase.airborne;
    HapticFeedback.heavyImpact();
  }

  // ─────────────────────────── SHOOTING ─────────────────────────────────────
  void _shoot(Offset screenPos) {
    final worldY = screenPos.dy - (_screenSize.height * 0.38) + _cameraY;
    final worldPos = Offset(screenPos.dx, worldY);
    final boatPos = Offset(_screenSize.width * 0.5 + 40, -40);

    FishEntity? hitFish;
    double closest = double.infinity;

    for (final f in _fishes) {
      final d = (Offset(f.x, f.y) - worldPos).distance;
      if (d < 50 && d < closest) {
        closest = d;
        hitFish = f;
      }
    }

    if (hitFish != null) {
      final damage = _gunLvl == 0 ? 10 : (_gunLvl == 1 ? 25 : 50);
      hitFish.currentHealth -= damage;

      _splashes.add(BloodSplash(Offset(hitFish.x, hitFish.y)));
      _bullets.add(BulletFx(boatPos, Offset(hitFish.x, hitFish.y)));

      if (hitFish.currentHealth <= 0) {
        _fishes.remove(hitFish);

        if (hitFish.spec.isJelly) {
          // Jellyfish penalty!
          _sessionScore += hitFish.spec.value;
          _popups.add(PopupText(
            Offset(hitFish.x, hitFish.y),
            '${hitFish.spec.value} \$',
            const Color(0xFFFF1744),
          ));
        } else {
          _combo++;
          _comboTimer = 1.3;
          final multiplier = _combo > 1 ? _combo : 1;
          final scoreEarned = hitFish.spec.value * multiplier;
          _sessionScore += scoreEarned;

          _popups.add(PopupText(
            Offset(hitFish.x, hitFish.y),
            '+$scoreEarned${_combo > 1 ? " x$_combo" : ""}',
            _combo > 2 ? const Color(0xFFFF5252) : const Color(0xFFFFD700),
          ));
        }
      }
      HapticFeedback.mediumImpact();
    } else {
      _bullets.add(BulletFx(boatPos, worldPos));
    }
  }

  // ─────────────────────────── GAME SETUP ───────────────────────────────────
  void _startFishing() {
    _fishes.clear();
    _splashes.clear();
    _bullets.clear();
    _popups.clear();
    _sessionScore = 0;
    _combo = 0;

    final fishCount = max(16, (_maxDepth / 20).round());
    for (int i = 0; i < fishCount; i++) {
      final depth = 20 + _rnd.nextDouble() * (_maxDepth - 40);

      // Filter eligible specs for current depth
      final eligible = kOriginalSpecs.where((s) => depth >= s.minDepth && depth <= s.maxDepth).toList();
      final spec = eligible.isNotEmpty ? eligible[_rnd.nextInt(eligible.length)] : kOriginalSpecs[0];

      final dir = _rnd.nextBool() ? 1.0 : -1.0;
      final speed = (spec.speed * 40 + _rnd.nextDouble() * 20) * dir;

      _fishes.add(FishEntity(
        id: i,
        spec: spec,
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

  // ─────────────────────────── UI & INPUT ───────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(builder: (ctx, constraints) {
        _screenSize = constraints.biggest;
        return GestureDetector(
          onTapDown: (e) {
            _targetHookX = e.localPosition.dx;
            if (_phase == GamePhase.airborne) _shoot(e.localPosition);
          },
          onPanUpdate: (e) {
            _targetHookX = e.localPosition.dx;
            if (_phase == GamePhase.airborne) _shoot(e.localPosition);
          },
          child: Stack(
            children: [
              // Custom Painter with Authentic Vlambeer Colors & Assets
              Positioned.fill(
                child: CustomPaint(
                  painter: _RidiculousPainter(
                    fishes: _fishes,
                    splashes: _splashes,
                    bullets: _bullets,
                    popups: _popups,
                    phase: _phase,
                    hookX: _hookX,
                    hookY: _hookY,
                    cameraY: _cameraY,
                    waveOffset: _waveOffset,
                    screenSize: _screenSize,
                    gunLvl: _gunLvl,
                    maxDepth: _maxDepth,
                  ),
                ),
              ),

              // HUD
              _buildHUD(),

              // Menus
              if (_phase == GamePhase.menu || _phase == GamePhase.gameOver)
                _buildMenuOverlay(),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildHUD() {
    final depth = _hookY.round();
    final caught = _fishes.where((f) => f.isCaught).length;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
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
                    '${depth}m  |  $caught/$_maxCaughtFish peixes',
                    style: const TextStyle(
                      fontFamily: '04B03',
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                if (_phase == GamePhase.airborne && _combo > 1)
                  Text(
                    'COMBO x$_combo!',
                    style: const TextStyle(
                      fontFamily: '04B03',
                      color: Color(0xFFFF3D00),
                      fontSize: 22,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuOverlay() {
    final isOver = _phase == GamePhase.gameOver;
    return Center(
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xEE0B192E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFF9E00), width: 2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF9E00).withOpacity(0.3),
              blurRadius: 24,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isOver ? 'PESCA CONCLUIDA!' : 'RIDICULOUS FISHING',
              style: const TextStyle(
                fontFamily: '04B03',
                color: Color(0xFFFF9E00),
                fontSize: 22,
                letterSpacing: 2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            if (isOver) ...[
              Text(
                'Pontuacao: +$_sessionScore \$',
                style: const TextStyle(
                  fontFamily: '04B03',
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 14),
            ],
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9E00),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _startFishing,
              child: const Text(
                'LANCAR LINHA!',
                style: TextStyle(fontFamily: '04B03', fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.white24),
            const Text('UPGRADES', style: TextStyle(fontFamily: '04B03', color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 8),
            _upgradeBtn('Linha Mais Funda (+150m)', 40 * (_depthLvl + 1), () {
              if (_money >= 40 * (_depthLvl + 1)) {
                setState(() {
                  _money -= 40 * (_depthLvl + 1);
                  _depthLvl++;
                });
                _saveState();
              }
            }),
            _upgradeBtn('Mais Anzois (+3)', 50 * (_hooksLvl + 1), () {
              if (_money >= 50 * (_hooksLvl + 1)) {
                setState(() {
                  _money -= 50 * (_hooksLvl + 1);
                  _hooksLvl++;
                });
                _saveState();
              }
            }),
            _upgradeBtn('Arma (+Dano)', 80 * (_gunLvl + 1), () {
              if (_money >= 80 * (_gunLvl + 1)) {
                setState(() {
                  _money -= 80 * (_gunLvl + 1);
                  _gunLvl++;
                });
                _saveState();
              }
            }),
          ],
        ),
      ),
    );
  }

  Widget _upgradeBtn(String label, int cost, VoidCallback onTap) {
    final canBuy = _money >= cost;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: canBuy ? const Color(0xFFFF9E00) : Colors.white24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        onPressed: canBuy ? onTap : null,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
            Text('$cost \$', style: TextStyle(color: canBuy ? const Color(0xFFFF9E00) : Colors.white38, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────── CUSTOM PAINTER ─────────────────────────────────
class _RidiculousPainter extends CustomPainter {
  final List<FishEntity> fishes;
  final List<BloodSplash> splashes;
  final List<BulletFx> bullets;
  final List<PopupText> popups;
  final GamePhase phase;
  final double hookX;
  final double hookY;
  final double cameraY;
  final double waveOffset;
  final Size screenSize;
  final int gunLvl;
  final double maxDepth;

  _RidiculousPainter({
    required this.fishes,
    required this.splashes,
    required this.bullets,
    required this.popups,
    required this.phase,
    required this.hookX,
    required this.hookY,
    required this.cameraY,
    required this.waveOffset,
    required this.screenSize,
    required this.gunLvl,
    required this.maxDepth,
  });

  double get surfaceY => screenSize.height * 0.38;
  double worldToScreenY(double y) => surfaceY + y - cameraY;

  @override
  void paint(Canvas canvas, Size size) {
    final mgr = SpriteManager.instance;
    final sy0 = worldToScreenY(0);

    // 1. SKY GRADIENT (Exact Vlambeer pond.xml palette)
    if (sy0 > 0) {
      final skyRect = Rect.fromLTWH(0, 0, size.width, sy0);
      canvas.drawRect(
        skyRect,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF00FFFF), // r=0, g=255, b=255
              Color(0xFF00C5F0), // r=0, g=197, b=240
              Color(0xFF506CE0), // r=80, g=108, b=224
              Color(0xFF6C41BA), // r=108, g=65, b=186
            ],
          ).createShader(skyRect),
      );
    }

    // 2. SEA GRADIENT (Exact Vlambeer pond.xml palette)
    final waterTop = max(0.0, sy0);
    final waterRect = Rect.fromLTWH(0, waterTop, size.width, size.height - waterTop);
    canvas.drawRect(
      waterRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF00FD9E), // r=0, g=253, b=158
            Color(0xFF00BC8F), // r=0, g=188, b=143
            Color(0xFF6188B8), // r=97, g=136, b=184
            Color(0xFF9955B9), // r=153, g=85, b=185
            Color(0xFF1B4F5A), // r=27, g=79, b=90
            Color(0xFF00312A), // r=0, g=49, b=42
            Color(0xFF021114), // r=2, g=17, b=20
          ],
        ).createShader(waterRect),
    );

    // 3. WAVES ON SURFACE
    final waveSprite = mgr.get('wave.png');
    if (waveSprite != null) {
      final waveW = size.width * 1.3;
      final waveH = 26.0;
      canvas.drawImageRect(
        waveSprite,
        Rect.fromLTWH(0, 0, waveSprite.width.toDouble(), waveSprite.height.toDouble()),
        Rect.fromLTWH(waveOffset - 20, sy0 - 13, waveW, waveH),
        Paint()..color = Colors.white.withOpacity(0.9),
      );
    } else {
      canvas.drawLine(
        Offset(0, sy0),
        Offset(size.width, sy0),
        Paint()..color = Colors.white70..strokeWidth = 3,
      );
    }

    // 4. FISHES (AUTHENTIC VLAMBEER APK SPRITES)
    for (final f in fishes) {
      final screenY = worldToScreenY(f.y);
      if (screenY < -120 || screenY > size.height + 120) continue;

      final sprite = mgr.get(f.spec.sprite);
      if (sprite != null) {
        canvas.save();
        canvas.translate(f.x, screenY);
        canvas.rotate(f.rotation);

        final facingLeft = f.vx < 0;
        if (facingLeft) canvas.scale(-1, 1);

        final destW = sprite.width.toDouble() * 0.7;
        final destH = sprite.height.toDouble() * 0.7;
        canvas.drawImageRect(
          sprite,
          Rect.fromLTWH(0, 0, sprite.width.toDouble(), sprite.height.toDouble()),
          Rect.fromCenter(center: Offset.zero, width: destW, height: destH),
          Paint(),
        );
        canvas.restore();
      }
    }

    // 5. FISHING LINE & HOOK
    final boatTip = Offset(size.width * 0.5 + 46, sy0 - 24);
    final isHookActive = phase == GamePhase.descending || phase == GamePhase.ascending;
    final hookScreenPos = isHookActive ? Offset(hookX, worldToScreenY(hookY)) : Offset(boatTip.dx, sy0 - 5);

    // Fishing line
    canvas.drawLine(boatTip, hookScreenPos, Paint()..color = Colors.white70..strokeWidth = 1.6);

    // Hook sprite
    if (isHookActive) {
      final hookSprite = mgr.get(hookY > 200 ? 'deephook.png' : 'hook.png');
      if (hookSprite != null) {
        final hw = 24.0;
        final hh = 34.0;
        canvas.drawImageRect(
          hookSprite,
          Rect.fromLTWH(0, 0, hookSprite.width.toDouble(), hookSprite.height.toDouble()),
          Rect.fromLTWH(hookScreenPos.dx - hw / 2, hookScreenPos.dy, hw, hh),
          Paint(),
        );
      } else {
        canvas.drawCircle(hookScreenPos, 7, Paint()..color = Colors.redAccent);
      }
    }

    // 6. SHIP & FISHERMAN SPRITE
    final shipSprite = mgr.get('ship.png');
    final bx = size.width * 0.5;
    final by = sy0;
    if (shipSprite != null) {
      final sw = 140.0;
      final sh = sw * (shipSprite.height / shipSprite.width);
      canvas.drawImageRect(
        shipSprite,
        Rect.fromLTWH(0, 0, shipSprite.width.toDouble(), shipSprite.height.toDouble()),
        Rect.fromCenter(center: Offset(bx, by - 20), width: sw, height: sh),
        Paint(),
      );
    }

    // Gun sprite in boat
    final gunSprite = mgr.get(gunLvl > 0 ? 'machineGun.png' : 'singleShot.png');
    if (gunSprite != null) {
      canvas.drawImageRect(
        gunSprite,
        Rect.fromLTWH(0, 0, gunSprite.width.toDouble(), gunSprite.height.toDouble()),
        Rect.fromLTWH(bx + 18, by - 48, 42, 22),
        Paint(),
      );
    }

    // 7. BULLETS & SHOOTING EFFECTS
    for (final b in bullets) {
      final alpha = (1.0 - (b.t / 0.12)).clamp(0.0, 1.0);
      final bulletSprite = mgr.get('bullet.png');
      final targetPos = Offset(b.to.dx, worldToScreenY(b.to.dy));
      if (bulletSprite != null) {
        canvas.drawImageRect(
          bulletSprite,
          Rect.fromLTWH(0, 0, bulletSprite.width.toDouble(), bulletSprite.height.toDouble()),
          Rect.fromCenter(center: targetPos, width: 14, height: 14),
          Paint()..color = Colors.white.withOpacity(alpha),
        );
      }
      canvas.drawLine(
        Offset(b.from.dx, b.from.dy - cameraY + surfaceY),
        targetPos,
        Paint()
          ..color = Colors.yellowAccent.withOpacity(alpha)
          ..strokeWidth = 3,
      );
    }

    // 8. BLOOD SPLASHES (SPRITES)
    final bloodSprite = mgr.get('blood.png');
    for (final s in splashes) {
      final a = (1.0 - (s.time / s.maxTime)).clamp(0.0, 1.0);
      final sy = worldToScreenY(s.position.dy);
      if (bloodSprite != null) {
        final bw = 46.0 * (1.0 + s.time * 0.5);
        canvas.drawImageRect(
          bloodSprite,
          Rect.fromLTWH(0, 0, bloodSprite.width.toDouble(), bloodSprite.height.toDouble()),
          Rect.fromCenter(center: Offset(s.position.dx, sy), width: bw, height: bw),
          Paint()..color = Colors.white.withOpacity(a),
        );
      }
    }

    // 9. POPUP TEXTS
    for (final p in popups) {
      final a = (1.0 - (p.t / 1.0)).clamp(0.0, 1.0);
      final sy = worldToScreenY(p.position.dy) - p.t * 50;
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
      tp.paint(canvas, Offset(p.position.dx - tp.width / 2, sy));
    }
  }

  @override
  bool shouldRepaint(covariant _RidiculousPainter old) => true;
}
