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
    final imageNames = [
      'ship.png',
      'fisherman.png',
      'hook.png',
      'deephook.png',
      'wave.png',
      'blood.png',
      'bullet.png',
      'machineGun.png',
      'singleShot.png',
      'sky1.png',
      'sky2.png',
      'sky3.png',
      'ocean1.png',
      'ocean2.png',
      'ocean3.png',
      'crab.png',
      'dolphin.png',
      // Style 1 fish
      for (int i = 1; i <= 18; i++) 'fish$i.png',
      // Style 2 fish
      for (int i = 1; i <= 16; i++) if (i != 2) 'style2_$i.png',
      // Style 3 fish
      for (int i = 1; i <= 9; i++) 'style3_$i.png',
    ];

    for (final name in imageNames) {
      try {
        final data = await rootBundle.load('assets/images/$name');
        final bytes = Uint8List.view(data.buffer);
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        _cache[name] = frame.image;
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
                fontFamily: 'Villa',
                color: Color(0xFFFF9E00),
                fontSize: 42,
                letterSpacing: 4,
              ),
            ),
            const Text(
              'FISHING',
              style: TextStyle(
                fontFamily: 'Villa',
                color: Colors.white,
                fontSize: 26,
                letterSpacing: 6,
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
            const SizedBox(height: 12),
            const Text('A carregar sprites...',
                style: TextStyle(color: Colors.white60, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────── MODELS ─────────────────────────────────────────
enum GamePhase { menu, descending, ascending, airborne, gameOver }

class FishEntity {
  final int id;
  final String spriteName;
  final int value;
  final double scale;
  final double baseSpeed;
  final bool isDangerous; // takes away points like jellyfish

  double x;
  double y;
  double vx;
  double vy = 0;
  bool isCaught = false;
  double caughtOffsetX = 0;
  double caughtOffsetY = 0;
  double rotation = 0;
  bool isDead = false;

  FishEntity({
    required this.id,
    required this.spriteName,
    required this.value,
    required this.scale,
    required this.baseSpeed,
    required this.x,
    required this.y,
    required this.vx,
    this.isDangerous = false,
  });
}

class BloodSplash {
  Offset position;
  double time = 0;
  final double maxTime = 1.2;
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
  int _lureLvl = 0;  // catch radius

  double get _maxDepth => 600.0 + 350.0 * _depthLvl;
  int get _maxCaughtFish => 4 + 3 * _hooksLvl;
  double get _hookRadius => 20.0 + 6.0 * _lureLvl;

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

  // Theme style (0: style1, 1: style2, 2: style3)
  int _currentStyle = 0;

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
      _lureLvl = _prefs.getInt('rf_lure') ?? 0;
      _ready = true;
    });
  }

  Future<void> _saveState() async {
    await _prefs.setInt('rf_money', _money);
    await _prefs.setInt('rf_depth', _depthLvl);
    await _prefs.setInt('rf_hooks', _hooksLvl);
    await _prefs.setInt('rf_gun', _gunLvl);
    await _prefs.setInt('rf_lure', _lureLvl);
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
      _waveOffset -= 35 * dt;
      if (_waveOffset < -25) _waveDirectionLeft = false;
    } else {
      _waveOffset += 35 * dt;
      if (_waveOffset > 25) _waveDirectionLeft = true;
    }

    // Combo timer
    if (_combo > 0) {
      _comboTimer -= dt;
      if (_comboTimer <= 0) _combo = 0;
    }

    // Free swimming fish
    for (final f in _fishes) {
      if (!f.isCaught && _phase != GamePhase.airborne) {
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
        _hookY += (240 + _depthLvl * 20) * dt;
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
        f.vy += 620 * dt; // Gravity
        f.y += f.vy * dt;
        f.x += f.vx * dt;
        f.rotation += (f.vx > 0 ? 3 : -3) * dt;

        // Bounce off screen walls
        if (f.x < 30 || f.x > _screenSize.width - 30) f.vx = -f.vx * 0.8;
      }

      // Remove fish that fell below water line
      _fishes.removeWhere((f) => f.y > 50 && f.vy > 0);
      if (_fishes.isEmpty) {
        _phase = GamePhase.gameOver;
        _money += _sessionScore;
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

      if (dist < _hookRadius + 22.0 * f.scale) {
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
      if (d < 50 * f.scale + 20 && d < closest) {
        closest = d;
        hitFish = f;
      }
    }

    if (hitFish != null) {
      _fishes.remove(hitFish);
      _combo++;
      _comboTimer = 1.3;
      final multiplier = _combo > 1 ? _combo : 1;
      final scoreEarned = hitFish.value * multiplier;
      _sessionScore += scoreEarned;

      _splashes.add(BloodSplash(Offset(hitFish.x, hitFish.y)));
      _bullets.add(BulletFx(boatPos, Offset(hitFish.x, hitFish.y)));
      _popups.add(PopupText(
        Offset(hitFish.x, hitFish.y),
        '+$scoreEarned${_combo > 1 ? " x$_combo" : ""}',
        _combo > 2 ? const Color(0xFFFF5252) : const Color(0xFFFFD700),
      ));
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

    // Available fish sprites according to current theme style
    final List<String> availableSprites = [];
    if (_currentStyle == 0) {
      for (int i = 1; i <= 18; i++) availableSprites.add('fish$i.png');
    } else if (_currentStyle == 1) {
      for (int i = 1; i <= 16; i++) if (i != 2) availableSprites.add('style2_$i.png');
    } else {
      for (int i = 1; i <= 9; i++) availableSprites.add('style3_$i.png');
    }

    final fishCount = max(14, (_maxDepth / 30).round());
    for (int i = 0; i < fishCount; i++) {
      final depth = 60 + _rnd.nextDouble() * (_maxDepth - 100);
      final sprite = availableSprites[_rnd.nextInt(availableSprites.length)];
      final dir = _rnd.nextBool() ? 1.0 : -1.0;
      final speed = (30 + _rnd.nextDouble() * 55) * dir;
      final baseVal = (4 + (depth / 35)).round();
      final scale = 0.8 + _rnd.nextDouble() * 0.5;

      _fishes.add(FishEntity(
        id: i,
        spriteName: sprite,
        value: baseVal,
        scale: scale,
        baseSpeed: speed.abs(),
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
              // Custom Painter with Real Sprites
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
                    currentStyle: _currentStyle,
                    gunLvl: _gunLvl,
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
    final depth = (_hookY / 10).round();
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
                    fontFamily: 'Villa',
                    color: Color(0xFFFF9E00),
                    fontSize: 32,
                  ),
                ),
                if (_phase == GamePhase.descending || _phase == GamePhase.ascending)
                  Text(
                    '${depth}m  |  $caught/$_maxCaughtFish peixes',
                    style: const TextStyle(
                      fontFamily: 'Villa',
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                if (_phase == GamePhase.airborne && _combo > 1)
                  Text(
                    'COMBO x$_combo!',
                    style: const TextStyle(
                      fontFamily: 'Villa',
                      color: Color(0xFFFF3D00),
                      fontSize: 22,
                    ),
                  ),
              ],
            ),
            if (_phase == GamePhase.menu)
              IconButton(
                icon: const Icon(Icons.palette, color: Colors.white, size: 28),
                onPressed: () {
                  setState(() => _currentStyle = (_currentStyle + 1) % 3);
                },
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
                fontFamily: 'Villa',
                color: Color(0xFFFF9E00),
                fontSize: 24,
                letterSpacing: 2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            if (isOver) ...[
              Text(
                'Pontuacao: +$_sessionScore \$',
                style: const TextStyle(
                  fontFamily: 'Villa',
                  color: Colors.white,
                  fontSize: 18,
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
                style: TextStyle(fontFamily: 'Villa', fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.white24),
            const Text('UPGRADES', style: TextStyle(fontFamily: 'Villa', color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 8),
            _upgradeBtn('Profundidade (+350m)', 40 * (_depthLvl + 1), () {
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
            _upgradeBtn('Arma (+Dano/Cadencia)', 80 * (_gunLvl + 1), () {
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
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
            Text('$cost \$', style: TextStyle(color: canBuy ? const Color(0xFFFF9E00) : Colors.white38, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────── CUSTOM PAINTER (SPRITES) ───────────────────────
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
  final int currentStyle;
  final int gunLvl;

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
    required this.currentStyle,
    required this.gunLvl,
  });

  double get surfaceY => screenSize.height * 0.38;
  double worldToScreenY(double y) => surfaceY + y - cameraY;

  @override
  void paint(Canvas canvas, Size size) {
    final mgr = SpriteManager.instance;
    final sy0 = worldToScreenY(0);

    // 1. SKY BACKGROUND
    final skySprite = mgr.get(currentStyle == 0 ? 'sky1.png' : currentStyle == 1 ? 'sky2.png' : 'sky3.png');
    if (sy0 > 0) {
      final skyRect = Rect.fromLTWH(0, 0, size.width, sy0);
      if (skySprite != null) {
        canvas.drawImageRect(
          skySprite,
          Rect.fromLTWH(0, 0, skySprite.width.toDouble(), skySprite.height.toDouble()),
          skyRect,
          Paint(),
        );
      } else {
        canvas.drawRect(skyRect, Paint()..color = const Color(0xFFFFB300));
      }
    }

    // 2. OCEAN BACKGROUND
    final oceanSprite = mgr.get(currentStyle == 0 ? 'ocean1.png' : currentStyle == 1 ? 'ocean2.png' : 'ocean3.png');
    final waterTop = max(0.0, sy0);
    final waterRect = Rect.fromLTWH(0, waterTop, size.width, size.height - waterTop);
    if (oceanSprite != null) {
      canvas.drawImageRect(
        oceanSprite,
        Rect.fromLTWH(0, 0, oceanSprite.width.toDouble(), oceanSprite.height.toDouble()),
        waterRect,
        Paint(),
      );
    } else {
      canvas.drawRect(
        waterRect,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0077B6), Color(0xFF03045E)],
          ).createShader(waterRect),
      );
    }

    // 3. WAVES ON SURFACE
    final waveSprite = mgr.get('wave.png');
    if (waveSprite != null) {
      final waveW = size.width * 1.3;
      final waveH = 26.0;
      canvas.drawImageRect(
        waveSprite,
        Rect.fromLTWH(0, 0, waveSprite.width.toDouble(), waveSprite.height.toDouble()),
        Rect.fromLTWH(waveOffset - 20, sy0 - 13, waveW, waveH),
        Paint()..color = Colors.white.withOpacity(0.85),
      );
    } else {
      canvas.drawLine(
        Offset(0, sy0),
        Offset(size.width, sy0),
        Paint()..color = Colors.white70..strokeWidth = 3,
      );
    }

    // 4. FISHES (SPRITES)
    for (final f in fishes) {
      final screenY = worldToScreenY(f.y);
      if (screenY < -120 || screenY > size.height + 120) continue;

      final sprite = mgr.get(f.spriteName);
      if (sprite != null) {
        canvas.save();
        canvas.translate(f.x, screenY);
        canvas.rotate(f.rotation);

        final facingLeft = f.vx < 0;
        if (facingLeft) canvas.scale(-1, 1);

        final destW = sprite.width.toDouble() * 0.7 * f.scale;
        final destH = sprite.height.toDouble() * 0.7 * f.scale;
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
      final hookSprite = mgr.get(hookY > 800 ? 'deephook.png' : 'hook.png');
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
            fontFamily: 'Villa',
            color: p.color.withOpacity(a),
            fontSize: 22,
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
