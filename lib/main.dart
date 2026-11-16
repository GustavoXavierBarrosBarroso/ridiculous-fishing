import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────── ENTRY POINT ────────────────────────────────────
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const RidiculousFishingApp());
}

// ─────────────────────────── APP ROOT ───────────────────────────────────────
class RidiculousFishingApp extends StatelessWidget {
  const RidiculousFishingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ridiculous Fishing',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A1628),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFFD700),
          secondary: Color(0xFF00E5FF),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

// ─────────────────────────── SPLASH SCREEN ──────────────────────────────────
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const GameScreen(),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: FadeTransition(
        opacity: _fade,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildBigFish(),
              const SizedBox(height: 32),
              const Text(
                'RIDICULOUS',
                style: TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 6,
                ),
              ),
              const Text(
                'FISHING',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBigFish() {
    return CustomPaint(
      size: const Size(120, 80),
      painter: _BigFishPainter(),
    );
  }
}

class _BigFishPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final cx = s.width / 2, cy = s.height / 2;
    final paint = Paint()..color = const Color(0xFF00BCD4);
    // body
    c.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: 90, height: 50),
        paint);
    // tail
    final tail = Path()
      ..moveTo(cx - 40, cy)
      ..lineTo(cx - 65, cy - 22)
      ..lineTo(cx - 65, cy + 22)
      ..close();
    c.drawPath(tail, paint);
    // fin
    final fin = Path()
      ..moveTo(cx + 5, cy - 20)
      ..lineTo(cx + 25, cy - 42)
      ..lineTo(cx + 35, cy - 20)
      ..close();
    c.drawPath(fin, Paint()..color = const Color(0xFF00ACC1));
    // eye
    c.drawCircle(Offset(cx + 28, cy - 6), 7, Paint()..color = Colors.white);
    c.drawCircle(Offset(cx + 29, cy - 6), 3.5, Paint()..color = Colors.black);
    // shine
    c.drawCircle(Offset(cx + 27, cy - 8), 1.5, Paint()..color = Colors.white);
    // mouth
    c.drawArc(Rect.fromCenter(center: Offset(cx + 36, cy + 2), width: 12, height: 8),
        0, pi, false, Paint()..color = Colors.white..strokeWidth = 2..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─────────────────────────── ENUMS & DATA MODELS ────────────────────────────
enum Phase { idle, descending, ascending, airborne, finished }

enum FishType { common, rare, epic, legendary, jellyfish, pufferfish, shark, anglerfish }

class FishDef {
  final FishType type;
  final String name;
  final Color color;
  final Color finColor;
  final double minDepth;
  final int baseValue;
  final double sizeMultiplier;
  final double speed;
  final bool avoids; // tries to dodge the hook

  const FishDef({
    required this.type,
    required this.name,
    required this.color,
    required this.finColor,
    required this.minDepth,
    required this.baseValue,
    this.sizeMultiplier = 1.0,
    this.speed = 1.0,
    this.avoids = false,
  });
}

const fishDefs = <FishDef>[
  FishDef(type: FishType.common,     name: 'Sardinha',    color: Color(0xFF78C8F0), finColor: Color(0xFF5BAED4), minDepth: 0,    baseValue: 2,  sizeMultiplier: 0.8),
  FishDef(type: FishType.common,     name: 'Carapau',     color: Color(0xFF90D090), finColor: Color(0xFF70B070), minDepth: 50,   baseValue: 4),
  FishDef(type: FishType.rare,       name: 'Dourada',     color: Color(0xFFFFD700), finColor: Color(0xFFE6C200), minDepth: 100,  baseValue: 10, sizeMultiplier: 1.2),
  FishDef(type: FishType.rare,       name: 'Robalo',      color: Color(0xFF9090F0), finColor: Color(0xFF7070D0), minDepth: 150,  baseValue: 15, sizeMultiplier: 1.1),
  FishDef(type: FishType.epic,       name: 'Atum',        color: Color(0xFF4040B0), finColor: Color(0xFF3030A0), minDepth: 250,  baseValue: 30, sizeMultiplier: 1.4, speed: 1.5),
  FishDef(type: FishType.epic,       name: 'Peixe-Espada',color: Color(0xFF8080FF), finColor: Color(0xFF6060FF), minDepth: 300,  baseValue: 40, sizeMultiplier: 1.6, speed: 1.8),
  FishDef(type: FishType.legendary,  name: 'Peixe Ouro',  color: Color(0xFFFF8C00), finColor: Color(0xFFCC7000), minDepth: 400,  baseValue: 80, sizeMultiplier: 1.8, avoids: true),
  FishDef(type: FishType.jellyfish,  name: 'Medusa',      color: Color(0x99FF69B4), finColor: Color(0x99FF1493), minDepth: 80,   baseValue: 6,  sizeMultiplier: 0.9),
  FishDef(type: FishType.pufferfish, name: 'Baiacu',      color: Color(0xFFFFFF00), finColor: Color(0xFFCCCC00), minDepth: 120,  baseValue: 12, sizeMultiplier: 1.0),
  FishDef(type: FishType.shark,      name: 'Tubarão',     color: Color(0xFF607080), finColor: Color(0xFF506070), minDepth: 350,  baseValue: 60, sizeMultiplier: 2.0, speed: 2.0, avoids: true),
  FishDef(type: FishType.anglerfish, name: 'Peixe-Lanterna', color: Color(0xFF1A1A3A), finColor: Color(0xFF0D0D2A), minDepth: 450, baseValue: 100, sizeMultiplier: 1.5),
];

class Fish {
  final FishDef def;
  double x, y, vx;
  final double radius;
  final int value;
  bool caught = false;
  double vy = 0, hookOffset = 0, hookDropY = 0;
  double wobble = 0; // animation timer
  bool inflated = false; // for pufferfish

  Fish(this.def, this.x, this.y, this.vx, this.radius, this.value);
}

class Shot {
  Offset from, to;
  double t = 0;
  bool hit;
  Shot(this.from, this.to, {this.hit = false});
}

class FloatText {
  Offset pos;
  String text;
  double t = 0;
  Color color;
  FloatText(this.pos, this.text, this.color);
}

class Particle {
  double x, y, vx, vy, life, maxLife, size;
  Color color;
  Particle(this.x, this.y, this.vx, this.vy, this.life, this.size, this.color)
      : maxLife = life;
}

// ─────────────────────────── SHOP ITEMS ─────────────────────────────────────
class ShopItem {
  final String id, name, description;
  final int Function(int level) cost;
  final int maxLevel;
  int level = 0;

  ShopItem({
    required this.id,
    required this.name,
    required this.description,
    required this.cost,
    required this.maxLevel,
  });

  int get nextCost => cost(level);
  bool get maxed => level >= maxLevel;
}

// ─────────────────────────── GAME SCREEN ────────────────────────────────────
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  final _rnd = Random();
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  Size _size = Size.zero;

  Phase _phase = Phase.idle;
  int _money = 0, _sessionGain = 0;
  double _hookX = 0, _targetX = 0, _hookY = 0, _camY = 0;
  bool _dragging = false;

  List<Fish> _fish = [];
  final List<Shot> _shots = [];
  final List<FloatText> _floats = [];
  final List<Particle> _particles = [];

  // ── Shop ──
  late final List<ShopItem> _shop = [
    ShopItem(id:'depth',   name:'Linha Mais Funda', description:'Mergulha mais fundo', cost:(l)=>40*(l+1),  maxLevel:8),
    ShopItem(id:'hooks',   name:'Mais Anzóis',      description:'Prende mais peixes',  cost:(l)=>60*(l+1),  maxLevel:7),
    ShopItem(id:'gun',     name:'Canhão Turbinado', description:'Cadência de fogo',    cost:(l)=>80*(l+1),  maxLevel:5),
    ShopItem(id:'magnet',  name:'Íman de Peixes',   description:'Raio de captura +',   cost:(l)=>50*(l+1),  maxLevel:6),
    ShopItem(id:'speed',   name:'Carretel Turbo',   description:'Velocidade da linha', cost:(l)=>35*(l+1),  maxLevel:6),
    ShopItem(id:'blender', name:'Liquidificador',   description:'Valor dos peixes +',  cost:(l)=>100*(l+1), maxLevel:5),
  ];

  // ── Derived stats ──
  double get _maxDepth      => 400 + 200.0 * _shopLvl('depth');
  int    get _maxHooks      => 2  + _shopLvl('hooks');
  double get _gunCooldown   => 0.12 - 0.015 * _shopLvl('gun');
  double get _catchRadius   => 14  + 4.0   * _shopLvl('magnet');
  double get _descendSpeed  => 180 + 30.0  * _shopLvl('speed');
  double get _ascendSpeed   => 220 + 40.0  * _shopLvl('speed');
  double get _valueMultiplier=> 1.0 + 0.25 * _shopLvl('blender');
  double get _surfaceY      => _size.height * 0.3;

  int _shopLvl(String id) => _shop.firstWhere((s) => s.id == id).level;

  double _gunTimer = 0;
  int _comboCount = 0;
  double _comboTimer = 0;
  bool _showShop = false;

  // persistence
  late SharedPreferences _prefs;
  bool _prefsLoaded = false;

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
    _money = _prefs.getInt('money') ?? 0;
    for (final s in _shop) {
      s.level = _prefs.getInt('shop_${s.id}') ?? 0;
    }
    if (mounted) setState(() => _prefsLoaded = true);
  }

  Future<void> _save() async {
    await _prefs.setInt('money', _money);
    for (final s in _shop) {
      await _prefs.setInt('shop_${s.id}', s.level);
    }
  }

  // ─── TICK ────────────────────────────────────────────────────────────────
  void _tick(Duration d) {
    final dt = ((d - _last).inMicroseconds / 1e6).clamp(0.0, 0.05).toDouble();
    _last = d;
    if (_size == Size.zero || !_prefsLoaded) return;
    _update(dt);
    setState(() {});
  }

  void _update(double dt) {
    final w = _size.width;

    // combo timer
    if (_comboCount > 0) {
      _comboTimer -= dt;
      if (_comboTimer <= 0) _comboCount = 0;
    }

    // gun cooldown
    if (_gunTimer > 0) _gunTimer -= dt;

    // wobble all fish
    for (final f in _fish) {
      f.wobble += dt * 3;
    }

    // swim free fish
    for (final f in _fish) {
      if (f.caught) continue;

      // avoidance behaviour
      if (f.def.avoids &&
          (_phase == Phase.descending || _phase == Phase.ascending)) {
        final dx = f.x - _hookX;
        final dy = f.y - _hookY;
        final dist = sqrt(dx * dx + dy * dy);
        if (dist < 90) {
          f.vx += (dx / dist) * 300 * dt;
          f.vx = f.vx.clamp(-220.0, 220.0);
        }
      }

      f.x += f.vx * dt;
      if (f.x < -50) f.x = w + 50;
      if (f.x > w + 50) f.x = -50;
    }

    if (_phase == Phase.descending || _phase == Phase.ascending) {
      // move hook X smoothly
      _hookX += (_targetX - _hookX) * min(1.0, dt * 8);
      _hookX = _hookX.clamp(10.0, w - 10.0);

      if (_phase == Phase.descending) {
        _hookY += _descendSpeed * dt;
        _tryHook();
        if (_hookY >= _maxDepth) _phase = Phase.ascending;
      } else {
        _hookY -= _ascendSpeed * dt;
        _tryHook();
        if (_hookY <= 0) {
          _hookY = 0;
          _launch();
        }
      }
      // drag caught fish with hook
      for (final f in _fish.where((f) => f.caught)) {
        f.x = _hookX + f.hookOffset;
        f.y = _hookY + f.hookDropY;
      }
    } else if (_phase == Phase.airborne) {
      for (final f in _fish) {
        f.vy += 650 * dt;
        f.y  += f.vy * dt;
        f.x  += f.vx * dt;
        if (f.x < 20 || f.x > w - 20) f.vx = -f.vx;
      }
      _fish.removeWhere((f) => f.y > 80 && f.vy > 0);
      if (_fish.isEmpty) {
        _phase = Phase.finished;
        _save();
      }
    }

    // camera
    if (_phase == Phase.descending || _phase == Phase.ascending) {
      final target = max(0.0, _hookY - _size.height * 0.25);
      _camY += (target - _camY) * min(1.0, dt * 7);
    } else if (_phase == Phase.airborne && _fish.isNotEmpty) {
      final minY = _fish.map((f) => f.y).reduce(min);
      final target = min(0.0, minY - 160.0);
      _camY += (target - _camY) * min(1.0, dt * 6);
    } else {
      _camY += (0.0 - _camY) * min(1.0, dt * 5);
    }

    // shots
    for (final s in _shots) s.t += dt;
    _shots.removeWhere((s) => s.t > 0.15);

    // float texts
    for (final f in _floats) f.t += dt;
    _floats.removeWhere((f) => f.t > 1.2);

    // particles
    for (final p in _particles) {
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.vy += 200 * dt;
      p.life -= dt;
    }
    _particles.removeWhere((p) => p.life <= 0);
  }

  void _tryHook() {
    var caught = _fish.where((f) => f.caught).length;
    for (final f in _fish) {
      if (f.caught || caught >= _maxHooks) continue;
      final dx = f.x - _hookX;
      final dy = f.y - _hookY;
      final dist = sqrt(dx * dx + dy * dy);
      if (dist < f.radius * 1.4 + _catchRadius) {
        f.caught = true;
        f.hookOffset = (_rnd.nextDouble() - .5) * 55;
        f.hookDropY  = 12 + _rnd.nextDouble() * 35;
        caught++;
        HapticFeedback.lightImpact();
      }
    }
  }

  void _launch() {
    final caught = _fish.where((f) => f.caught).toList();
    _fish = caught;
    if (caught.isEmpty) {
      _phase = Phase.finished;
      _save();
      return;
    }
    for (final f in caught) {
      f.y  = 0;
      f.vy = -(380 + _rnd.nextDouble() * 280);
      f.vx = (_rnd.nextDouble() - .5) * 240;
    }
    _phase = Phase.airborne;
    HapticFeedback.mediumImpact();
  }

  void _startFishing() {
    _fish = [];
    _shots.clear();
    _floats.clear();
    _particles.clear();
    _comboCount = 0;
    _sessionGain = 0;

    final count = max(8, (_maxDepth / 40).round());
    for (var i = 0; i < count; i++) {
      final depth = 50 + _rnd.nextDouble() * (_maxDepth - 80);
      // pick eligible fish defs
      final eligible = fishDefs.where((d) => d.minDepth <= depth).toList();
      // weight: rarer types less likely
      final weights = eligible.map((d) {
        switch (d.type) {
          case FishType.legendary:  return 1;
          case FishType.anglerfish: return 2;
          case FishType.shark:      return 3;
          case FishType.epic:       return 6;
          case FishType.rare:       return 12;
          default:                  return 25;
        }
      }).toList();
      final totalW = weights.fold<int>(0, (a, b) => a + b);
      var pick = _rnd.nextInt(totalW);
      late FishDef def;
      for (var j = 0; j < eligible.length; j++) {
        pick -= weights[j];
        if (pick < 0) { def = eligible[j]; break; }
      }
      def = eligible.last; // fallback

      final radius = (12 + _rnd.nextDouble() * 8) * def.sizeMultiplier;
      final speed  = (25 + _rnd.nextDouble() * 60) * def.speed;
      final dir    = _rnd.nextBool() ? 1 : -1;
      final value  = (def.baseValue * (1 + depth / 150) * _valueMultiplier).round();
      _fish.add(Fish(def, _rnd.nextDouble() * _size.width, depth,
          dir * speed, radius, value));
    }

    _hookX   = _size.width / 2;
    _targetX = _hookX;
    _hookY   = 0;
    _camY    = 0;
    _phase   = Phase.descending;
  }

  void _shoot(Offset screenPos) {
    if (_gunTimer > 0) return;
    _gunTimer = _gunCooldown;

    final worldPos = Offset(screenPos.dx, screenPos.dy - _surfaceY + _camY);
    final cannonOrigin = Offset(_size.width / 2 + 60, -55 + _camY);

    Fish? target;
    var bestDist = double.infinity;
    for (final f in _fish) {
      final d = (Offset(f.x, f.y) - worldPos).distance;
      if (d < 60 + f.radius && d < bestDist) {
        bestDist = d;
        target = f;
      }
    }

    if (target != null) {
      _fish.remove(target);
      final earned = target.value;
      _money       += earned;
      _sessionGain += earned;

      _comboCount++;
      _comboTimer = 1.5;
      final bonus = _comboCount > 1 ? ' x$_comboCount COMBO!' : '';

      _shots.add(Shot(cannonOrigin, Offset(target.x, target.y), hit: true));
      _floats.add(FloatText(
        Offset(target.x, target.y),
        '+\$$earned$bonus',
        _comboCount > 2 ? const Color(0xFFFF6B35) : const Color(0xFFFFD700),
      ));
      _spawnSplash(target.x, target.y, target.def.color);
      HapticFeedback.selectionClick();
    } else {
      _shots.add(Shot(cannonOrigin, worldPos, hit: false));
    }
  }

  void _spawnSplash(double x, double y, Color color) {
    for (var i = 0; i < 12; i++) {
      final angle = _rnd.nextDouble() * 2 * pi;
      final speed = 60 + _rnd.nextDouble() * 180;
      _particles.add(Particle(
        x, y,
        cos(angle) * speed, sin(angle) * speed - 80,
        0.5 + _rnd.nextDouble() * 0.3,
        3 + _rnd.nextDouble() * 5,
        color.withOpacity(0.9),
      ));
    }
  }

  // ─── INPUT ───────────────────────────────────────────────────────────────
  void _onPointerDown(Offset pos) {
    _dragging = true;
    _targetX  = pos.dx;
    if (_phase == Phase.airborne) _shoot(pos);
  }

  void _onPointerMove(Offset pos) {
    if (_dragging) _targetX = pos.dx;
    if (_phase == Phase.airborne) _shoot(pos);
  }

  void _onPointerUp() => _dragging = false;

  // ─── BUILD ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (!_prefsLoaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      body: LayoutBuilder(builder: (ctx, c) {
        _size = c.biggest;
        return Listener(
          onPointerDown: (e) => _onPointerDown(e.localPosition),
          onPointerMove: (e) => _onPointerMove(e.localPosition),
          onPointerUp:   (_) => _onPointerUp(),
          child: Stack(children: [
            // ── game canvas ──
            Positioned.fill(
              child: CustomPaint(
                painter: _GamePainter(
                  fish:        _fish,
                  shots:       _shots,
                  floats:      _floats,
                  particles:   _particles,
                  phase:       _phase,
                  hookX:       _hookX,
                  hookY:       _hookY,
                  camY:        _camY,
                  surfaceY:    _surfaceY,
                  maxDepth:    _maxDepth,
                  size:        _size,
                  comboCount:  _comboCount,
                ),
              ),
            ),

            // ── HUD ──
            if (_phase != Phase.idle && _phase != Phase.finished)
              _buildHUD(),

            // ── menus ──
            if (_phase == Phase.idle || _phase == Phase.finished)
              _showShop ? _buildShop() : _buildMenu(),
          ]),
        );
      }),
    );
  }

  // ─── HUD ─────────────────────────────────────────────────────────────────
  Widget _buildHUD() {
    final depth = (_hookY / 10).round();
    String hint;
    switch (_phase) {
      case Phase.descending:
        hint = 'Desliza → desviar / apanhar';
        break;
      case Phase.ascending:
        final hooked = _fish.where((f) => f.caught).length;
        hint = 'A subir! $hooked/$_maxHooks anzóis';
        break;
      case Phase.airborne:
        hint = _comboCount > 1 ? '🔥 COMBO x$_comboCount! Continua!' : 'Toca nos peixes para disparar!';
        break;
      default:
        hint = '';
    }
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Text('\$', style: TextStyle(color: Color(0xFFFFD700), fontSize: 20, fontWeight: FontWeight.bold)),
                Text('$_money', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              ]),
              Text(hint, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              if (_phase == Phase.descending || _phase == Phase.ascending)
                Text('${depth}m', style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 13, fontWeight: FontWeight.bold)),
            ]),
            if (_phase == Phase.airborne && _comboCount > 1)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B35).withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'x$_comboCount',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─── MAIN MENU ───────────────────────────────────────────────────────────
  Widget _buildMenu() {
    final isEnd = _phase == Phase.finished;
    return Center(
      child: Container(
        width: 320,
        margin: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF1A2A4A), Color(0xFF0D1A30)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.4), width: 1.5),
          boxShadow: [
            BoxShadow(color: const Color(0xFF00E5FF).withOpacity(0.15), blurRadius: 20),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isEnd) ...[
                const Text('PESCA TERMINADA!', style: TextStyle(color: Color(0xFFFFD700), fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 2)),
                const SizedBox(height: 8),
                Text('+\$$_sessionGain ganhos', style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 16)),
                const SizedBox(height: 4),
              ] else ...[
                const Text('RIDICULOUS', style: TextStyle(color: Color(0xFFFFD700), fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 3)),
                const Text('FISHING', style: TextStyle(color: Colors.white70, fontSize: 14, letterSpacing: 8)),
                const SizedBox(height: 4),
              ],
              Text('\$$_money total', style: const TextStyle(color: Colors.white, fontSize: 15)),
              const SizedBox(height: 20),
              _menuBtn('🎣  PESCAR!', const Color(0xFF00C853), _startFishing),
              const SizedBox(height: 10),
              _menuBtn('🛒  LOJA', const Color(0xFF1565C0), () => setState(() => _showShop = true)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuBtn(String label, Color color, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 6,
        ),
        onPressed: onTap,
        child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
      ),
    );
  }

  // ─── SHOP ────────────────────────────────────────────────────────────────
  Widget _buildShop() {
    return Container(
      color: const Color(0xEE0A1628),
      child: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('LOJA', style: TextStyle(color: Color(0xFFFFD700), fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 3)),
                Row(children: [
                  const Icon(Icons.attach_money, color: Color(0xFFFFD700)),
                  Text('$_money', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => setState(() => _showShop = false),
                  ),
                ]),
              ],
            ),
          ),
          const Divider(color: Color(0xFF00E5FF), thickness: 0.5),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _shop.length,
              itemBuilder: (_, i) => _shopCard(_shop[i]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _shopCard(ShopItem item) {
    final canBuy = !item.maxed && _money >= item.nextCost;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF152040),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: item.maxed
              ? const Color(0xFFFFD700).withOpacity(0.5)
              : const Color(0xFF00E5FF).withOpacity(0.2),
        ),
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
          Text(item.description, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 4),
          _levelBar(item),
        ])),
        const SizedBox(width: 12),
        item.maxed
            ? const Column(children: [
                Icon(Icons.star, color: Color(0xFFFFD700)),
                Text('MAX', style: TextStyle(color: Color(0xFFFFD700), fontSize: 11, fontWeight: FontWeight.bold)),
              ])
            : ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: canBuy ? const Color(0xFF00C853) : Colors.grey.shade800,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onPressed: canBuy ? () {
                  setState(() {
                    _money -= item.nextCost;
                    item.level++;
                  });
                  _save();
                } : null,
                child: Column(children: [
                  const Icon(Icons.arrow_upward, size: 16, color: Colors.white),
                  Text('\$${item.nextCost}', style: const TextStyle(color: Colors.white, fontSize: 11)),
                ]),
              ),
      ]),
    );
  }

  Widget _levelBar(ShopItem item) {
    return Row(
      children: List.generate(item.maxLevel, (i) => Expanded(
        child: Container(
          height: 5,
          margin: const EdgeInsets.only(right: 2),
          decoration: BoxDecoration(
            color: i < item.level ? const Color(0xFF00E5FF) : Colors.white12,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      )),
    );
  }
}

// ─────────────────────────── GAME PAINTER ───────────────────────────────────
class _GamePainter extends CustomPainter {
  final List<Fish> fish;
  final List<Shot> shots;
  final List<FloatText> floats;
  final List<Particle> particles;
  final Phase phase;
  final double hookX, hookY, camY, surfaceY, maxDepth;
  final Size size;
  final int comboCount;

  _GamePainter({
    required this.fish,
    required this.shots,
    required this.floats,
    required this.particles,
    required this.phase,
    required this.hookX,
    required this.hookY,
    required this.camY,
    required this.surfaceY,
    required this.maxDepth,
    required this.size,
    required this.comboCount,
  });

  // convert world-Y → screen-Y
  double sy(double y) => surfaceY + y - camY;

  @override
  void paint(Canvas c, Size s) {
    _drawBackground(c, s);
    _drawDepthZones(c, s);
    _drawBubbles(c, s); // decorative static bubbles
    _drawFish(c);
    _drawLineAndHook(c, s);
    _drawBoat(c, s);
    _drawShots(c, s);
    _drawParticles(c);
    _drawFloatTexts(c);
  }

  void _drawBackground(Canvas c, Size s) {
    final waterTop = max(0.0, sy(0));

    // Sky gradient
    if (sy(0) > 0) {
      final skyRect = Rect.fromLTWH(0, 0, s.width, sy(0));
      c.drawRect(
        skyRect,
        Paint()..shader = const LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Color(0xFFFF7043), Color(0xFFFFCC80)],
        ).createShader(skyRect),
      );
      // sun
      c.drawCircle(Offset(s.width * 0.75, sy(0) * 0.3), 32,
          Paint()..color = const Color(0xFFFFEE58).withOpacity(0.9));
      c.drawCircle(Offset(s.width * 0.75, sy(0) * 0.3), 44,
          Paint()..color = const Color(0xFFFFEE58).withOpacity(0.25));
    }

    // Water gradient
    final waterRect = Rect.fromLTWH(0, waterTop, s.width, s.height - waterTop + 200);
    c.drawRect(
      Rect.fromLTWH(0, waterTop, s.width, s.height - waterTop),
      Paint()..shader = LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF29B6F6),
          const Color(0xFF0D47A1),
          const Color(0xFF01002A),
        ],
        stops: [0, 0.5 + (camY / maxDepth) * 0.3, 1],
      ).createShader(waterRect),
    );

    // Water surface line
    c.drawLine(
      Offset(0, sy(0)), Offset(s.width, sy(0)),
      Paint()..color = Colors.white60..strokeWidth = 2.5,
    );
    // shimmer
    c.drawLine(
      Offset(0, sy(0) + 4), Offset(s.width, sy(0) + 4),
      Paint()..color = Colors.white24..strokeWidth = 1,
    );
  }

  void _drawDepthZones(Canvas c, Size s) {
    final zones = [
      (depth: 0.0,   color: const Color(0x0000BCD4), label: 'Zona Costeira'),
      (depth: 150.0, color: const Color(0x08001970), label: 'Zona Meso'),
      (depth: 350.0, color: const Color(0x10000000), label: 'Zona Profunda'),
    ];
    for (final z in zones) {
      final y = sy(z.depth);
      if (y > s.height || y < 0) continue;
      c.drawLine(Offset(0, y), Offset(s.width, y),
          Paint()..color = Colors.white10..strokeWidth = 0.8);
      final tp = TextPainter(
        text: TextSpan(
          text: z.label,
          style: const TextStyle(color: Colors.white10, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(c, Offset(8, y + 2));
    }
  }

  void _drawBubbles(Canvas c, Size s) {
    // Static decorative bubbles (deterministic from hash)
    final bPaint = Paint()..color = Colors.white.withOpacity(0.07)..style = PaintingStyle.stroke..strokeWidth = 1;
    final positions = [
      Offset(s.width * 0.1, sy(80)),  Offset(s.width * 0.3, sy(220)),
      Offset(s.width * 0.7, sy(140)), Offset(s.width * 0.85, sy(300)),
      Offset(s.width * 0.5, sy(400)), Offset(s.width * 0.2, sy(380)),
    ];
    for (final p in positions) {
      if (p.dy < surfaceY || p.dy > s.height) continue;
      c.drawCircle(p, 6, bPaint);
      c.drawCircle(p.translate(14, -20), 4, bPaint);
    }
  }

  void _drawFish(Canvas c) {
    for (final f in fish) {
      final screenY = sy(f.y);
      if (screenY < -80 || screenY > size.height + 80) continue;
      _paintFish(c, f, f.x, screenY);
    }
  }

  void _paintFish(Canvas c, Fish f, double x, double y) {
    final r = f.radius;
    final wobbleSin = sin(f.wobble) * 0.06;
    final dir = f.vx >= 0 ? 1.0 : -1.0;

    switch (f.def.type) {
      case FishType.jellyfish:
        _drawJellyfish(c, f, x, y);
        return;
      case FishType.pufferfish:
        _drawPufferfish(c, f, x, y);
        return;
      case FishType.shark:
        _drawShark(c, f, x, y);
        return;
      case FishType.anglerfish:
        _drawAnglerfish(c, f, x, y);
        return;
      default:
        break;
    }

    // Generic fish
    final bodyPaint = Paint()..color = f.def.color;
    final finPaint  = Paint()..color = f.def.finColor;

    // body (slightly wobbling)
    c.save();
    c.translate(x, y);
    c.rotate(wobbleSin * dir);
    c.drawOval(
      Rect.fromCenter(center: Offset.zero, width: r * 2.6, height: r * 1.8),
      bodyPaint,
    );
    // tail
    final tail = Path()
      ..moveTo(-dir * r * 1.1, 0)
      ..lineTo(-dir * r * 2.0, -r * 0.85)
      ..lineTo(-dir * r * 2.0,  r * 0.85)
      ..close();
    c.drawPath(tail, bodyPaint);
    // dorsal fin
    final fin = Path()
      ..moveTo(-r * 0.3, -r * 0.85)
      ..lineTo(r * 0.2,  -r * 1.6)
      ..lineTo(r * 0.7,  -r * 0.85)
      ..close();
    c.drawPath(fin, finPaint);
    // scale line
    c.drawArc(
      Rect.fromCenter(center: Offset(0, 0), width: r * 1.4, height: r * 1.0),
      0, pi, false,
      Paint()..color = Colors.white.withOpacity(0.15)..strokeWidth = 1..style = PaintingStyle.stroke,
    );
    // shine
    c.drawCircle(Offset(dir * r * 0.4,  -r * 0.3), r * 0.25, Paint()..color = Colors.white.withOpacity(0.35));
    // eye
    c.drawCircle(Offset(dir * r * 0.75, -r * 0.2), r * 0.22, Paint()..color = Colors.white);
    c.drawCircle(Offset(dir * r * 0.78, -r * 0.2), r * 0.11, Paint()..color = Colors.black);
    // rarity glow
    if (f.def.type == FishType.legendary) {
      c.drawCircle(Offset.zero, r * 1.5,
          Paint()..color = const Color(0xFFFF8C00).withOpacity(0.15)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
    } else if (f.def.type == FishType.epic) {
      c.drawCircle(Offset.zero, r * 1.3,
          Paint()..color = const Color(0xFF7B1FA2).withOpacity(0.1)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    }
    c.restore();
  }

  void _drawJellyfish(Canvas c, Fish f, double x, double y) {
    final r = f.radius;
    c.save();
    c.translate(x, y);
    // bell
    c.drawOval(Rect.fromCenter(center: Offset(0, -r * 0.3), width: r * 2, height: r * 1.3), Paint()..color = f.def.color);
    // tentacles
    final tPaint = Paint()..color = f.def.finColor..strokeWidth = 1.2..style = PaintingStyle.stroke;
    for (var i = -2; i <= 2; i++) {
      final startX = i * r * 0.4;
      c.drawLine(Offset(startX, r * 0.4), Offset(startX + sin(f.wobble + i) * r * 0.4, r * 1.4), tPaint);
    }
    c.restore();
  }

  void _drawPufferfish(Canvas c, Fish f, double x, double y) {
    final r = f.radius * (f.inflated ? 1.5 : 1.0);
    c.save();
    c.translate(x, y);
    // spiky body
    c.drawCircle(Offset.zero, r, Paint()..color = f.def.color);
    final spikePaint = Paint()..color = f.def.finColor..strokeWidth = 1.5;
    for (var i = 0; i < 12; i++) {
      final angle = i * pi / 6;
      c.drawLine(
        Offset(cos(angle) * r, sin(angle) * r),
        Offset(cos(angle) * (r + 6), sin(angle) * (r + 6)),
        spikePaint,
      );
    }
    // eye
    final dir = f.vx >= 0 ? 1.0 : -1.0;
    c.drawCircle(Offset(dir * r * 0.4, -r * 0.2), r * 0.25, Paint()..color = Colors.white);
    c.drawCircle(Offset(dir * r * 0.42, -r * 0.2), r * 0.12, Paint()..color = Colors.black87);
    c.restore();
  }

  void _drawShark(Canvas c, Fish f, double x, double y) {
    final r = f.radius;
    final dir = f.vx >= 0 ? 1.0 : -1.0;
    c.save();
    c.translate(x, y);
    c.rotate(sin(f.wobble) * 0.04 * dir);
    final body = Paint()..color = f.def.color;
    // elongated body
    c.drawOval(Rect.fromCenter(center: Offset.zero, width: r * 3.5, height: r * 1.6), body);
    // tail
    final tail = Path()
      ..moveTo(-dir * r * 1.6, 0)
      ..lineTo(-dir * r * 2.4, -r * 1.1)
      ..lineTo(-dir * r * 2.4,  r * 1.1)
      ..close();
    c.drawPath(tail, body);
    // dorsal fin (tall)
    final fin = Path()
      ..moveTo(dir * r * 0.3, -r * 0.7)
      ..lineTo(dir * r * 0.7, -r * 2.2)
      ..lineTo(dir * r * 1.1, -r * 0.7)
      ..close();
    c.drawPath(fin, body);
    // pectoral fin
    final pec = Path()
      ..moveTo(-dir * r * 0.3, r * 0.3)
      ..lineTo(-dir * r * 0.8, r * 1.1)
      ..lineTo( dir * r * 0.3, r * 0.5)
      ..close();
    c.drawPath(pec, Paint()..color = f.def.finColor);
    // eye
    c.drawCircle(Offset(dir * r * 0.9, -r * 0.15), r * 0.2, Paint()..color = Colors.white);
    c.drawCircle(Offset(dir * r * 0.92, -r * 0.15), r * 0.1, Paint()..color = Colors.black87);
    // teeth
    for (var i = 0; i < 4; i++) {
      c.drawLine(
        Offset(dir * (r * 0.5 - i * r * 0.25), r * 0.7),
        Offset(dir * (r * 0.5 - i * r * 0.25), r * 1.0),
        Paint()..color = Colors.white..strokeWidth = 2,
      );
    }
    c.restore();
  }

  void _drawAnglerfish(Canvas c, Fish f, double x, double y) {
    final r = f.radius;
    final dir = f.vx >= 0 ? 1.0 : -1.0;
    c.save();
    c.translate(x, y);
    // dark body
    c.drawOval(Rect.fromCenter(center: Offset.zero, width: r * 2.4, height: r * 2.0),
        Paint()..color = f.def.color);
    // lure (glowing appendage)
    final lureLen = r * 1.5;
    final lureEnd = Offset(dir * r * 0.3, -r * 1.2 - lureLen);
    c.drawLine(Offset(dir * r * 0.3, -r * 1.0), lureEnd,
        Paint()..color = const Color(0xFF9C27B0)..strokeWidth = 2);
    c.drawCircle(lureEnd, r * 0.35,
        Paint()..color = const Color(0xFFCE93D8)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    c.drawCircle(lureEnd, r * 0.2, Paint()..color = Colors.white);
    // big mean eye
    c.drawCircle(Offset(dir * r * 0.6, -r * 0.3), r * 0.35, Paint()..color = const Color(0xFFCE93D8));
    c.drawCircle(Offset(dir * r * 0.62, -r * 0.3), r * 0.18, Paint()..color = Colors.black);
    // teeth
    for (var i = 0; i < 5; i++) {
      c.drawLine(
        Offset(dir * (r * 0.4 - i * r * 0.25), r * 0.9),
        Offset(dir * (r * 0.4 - i * r * 0.25) + dir * r * 0.08, r * 1.3),
        Paint()..color = Colors.white..strokeWidth = 1.5,
      );
    }
    c.restore();
  }

  void _drawLineAndHook(Canvas c, Size s) {
    final active = phase == Phase.descending || phase == Phase.ascending;
    final boatTip = Offset(s.width / 2 + 65, sy(0) - 48);
    final hookScreen = active ? Offset(hookX, sy(hookY)) : Offset(boatTip.dx, sy(0) - 10);

    // fishing line
    c.drawLine(boatTip, hookScreen,
        Paint()..color = Colors.white.withOpacity(0.7)..strokeWidth = 1.5);

    if (active) {
      // hook circle
      c.drawCircle(hookScreen, 9,
          Paint()..color = Colors.redAccent..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
      c.drawCircle(hookScreen, 7, Paint()..color = const Color(0xFFFF5252));
      // hook shine
      c.drawCircle(hookScreen.translate(-2, -2), 2.5, Paint()..color = Colors.white60);
      // hook curve
      c.drawArc(
        Rect.fromCenter(center: hookScreen.translate(0, 9), width: 14, height: 14),
        pi, pi / 2, false,
        Paint()..color = Colors.white60..strokeWidth = 2..style = PaintingStyle.stroke,
      );
    }
  }

  void _drawBoat(Canvas c, Size s) {
    final bx = s.width / 2;
    final by = sy(0);

    // hull shadow
    c.drawOval(
      Rect.fromCenter(center: Offset(bx, by + 8), width: 140, height: 14),
      Paint()..color = Colors.black26,
    );

    // hull
    final hull = Path()
      ..moveTo(bx - 72, by - 20)
      ..lineTo(bx + 72, by - 20)
      ..lineTo(bx + 54, by + 8)
      ..lineTo(bx - 54, by + 8)
      ..close();
    c.drawPath(hull, Paint()..color = const Color(0xFFB71C1C));
    // hull stripe
    c.drawLine(Offset(bx - 72, by - 20), Offset(bx + 72, by - 20),
        Paint()..color = const Color(0xFFEF9A9A)..strokeWidth = 3);

    // cabin
    final cabin = Path()
      ..moveTo(bx - 24, by - 20)
      ..lineTo(bx - 24, by - 52)
      ..lineTo(bx + 20, by - 52)
      ..lineTo(bx + 20, by - 20)
      ..close();
    c.drawPath(cabin, Paint()..color = const Color(0xFFECEFF1));
    // cabin windows
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(bx - 18, by - 48, 12, 10), const Radius.circular(2)),
        Paint()..color = const Color(0xFF64B5F6));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(bx + 2, by - 48, 12, 10), const Radius.circular(2)),
        Paint()..color = const Color(0xFF64B5F6));

    // mast
    c.drawLine(Offset(bx - 2, by - 52), Offset(bx - 2, by - 90),
        Paint()..color = const Color(0xFF795548)..strokeWidth = 3);
    // flag
    final flag = Path()
      ..moveTo(bx - 2, by - 90)
      ..lineTo(bx + 20, by - 82)
      ..lineTo(bx - 2, by - 74)
      ..close();
    c.drawPath(flag, Paint()..color = const Color(0xFFE53935));

    // cannon / fishing rod
    c.drawLine(Offset(bx + 14, by - 36), Offset(bx + 65, by - 50),
        Paint()..color = const Color(0xFF795548)..strokeWidth = 4);
    c.drawCircle(Offset(bx + 65, by - 50), 6, Paint()..color = Colors.black87);
    c.drawCircle(Offset(bx + 65, by - 50), 4, Paint()..color = const Color(0xFF37474F));
  }

  void _drawShots(Canvas c, Size s) {
    for (final shot in shots) {
      final a = (1 - shot.t / 0.15).clamp(0.0, 1.0);
      final color = shot.hit ? Colors.yellow : Colors.orange;
      c.drawLine(
        Offset(shot.from.dx, shot.from.dy - camY),
        Offset(shot.to.dx, sy(shot.to.dy)),
        Paint()
          ..color = color.withOpacity(a)
          ..strokeWidth = shot.hit ? 4 : 2.5
          ..maskFilter = shot.hit ? MaskFilter.blur(BlurStyle.normal, 3 * a) : null,
      );
      if (shot.hit) {
        c.drawCircle(
          Offset(shot.to.dx, sy(shot.to.dy)),
          8 * a,
          Paint()..color = Colors.orange.withOpacity(a * 0.6)..maskFilter = MaskFilter.blur(BlurStyle.normal, 6),
        );
      }
    }
  }

  void _drawParticles(Canvas c) {
    for (final p in particles) {
      final a = (p.life / p.maxLife).clamp(0.0, 1.0);
      c.drawCircle(
        Offset(p.x, sy(p.y)),
        p.size * a,
        Paint()..color = p.color.withOpacity(a),
      );
    }
  }

  void _drawFloatTexts(Canvas c) {
    for (final f in floats) {
      final a = (1 - f.t / 1.2).clamp(0.0, 1.0);
      final tp = TextPainter(
        text: TextSpan(
          text: f.text,
          style: TextStyle(
            color: f.color.withOpacity(a),
            fontSize: 20,
            fontWeight: FontWeight.w900,
            shadows: [Shadow(color: Colors.black.withOpacity(a * 0.8), blurRadius: 4)],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(c, Offset(f.pos.dx - tp.width / 2, sy(f.pos.dy) - f.t * 70));
    }
  }

  @override
  bool shouldRepaint(covariant _GamePainter old) => true;
}
