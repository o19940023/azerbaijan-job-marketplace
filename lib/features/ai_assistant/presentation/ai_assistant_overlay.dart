import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/jobs/data/models/job_model.dart';
import '../../../features/jobs/presentation/pages/job_detail_screen.dart';
import '../data/services/ai_service.dart';
import 'ai_assistant_cubit.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  CONSTANTS
// ─────────────────────────────────────────────────────────────────────────────

const _kAurora1 = Color(0xFF6C63FF);
const _kAurora2 = Color(0xFF0EA5E9);
const _kAurora3 = Color(0xFF10B981);
const _kGlassDark = Color(0xFF0D0D1A);
const _kGlassCard = Color(0xFF161628);
const _kGlassBorder = Color(0xFF2A2A4A);

// ─────────────────────────────────────────────────────────────────────────────
//  TYPEWRITER MESSAGE WIDGET
// ─────────────────────────────────────────────────────────────────────────────

class _TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final bool animate;

  const _TypewriterText({
    required this.text,
    required this.style,
    this.animate = true,
  });

  @override
  State<_TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<_TypewriterText> {
  String _displayed = '';
  int _index = 0;

  @override
  void initState() {
    super.initState();
    if (widget.animate && widget.text.isNotEmpty) {
      _tick();
    } else {
      _displayed = widget.text;
    }
  }

  void _tick() {
    if (!mounted || _index >= widget.text.length) return;
    Future.delayed(const Duration(milliseconds: 18), () {
      if (!mounted) return;
      setState(() {
        _displayed = widget.text.substring(0, _index + 1);
        _index++;
      });
      _tick();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Text(_displayed, style: widget.style);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  AURORA BACKGROUND PAINTER
// ─────────────────────────────────────────────────────────────────────────────

class _AuroraPainter extends CustomPainter {
  final double t;
  const _AuroraPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..blendMode = BlendMode.screen;

    void drawBlob(
      double cx,
      double cy,
      double r,
      Color color,
      double opacity,
    ) {
      paint.shader = RadialGradient(
        colors: [color.withOpacity(opacity), Colors.transparent],
      ).createShader(Rect.fromCircle(
        center: Offset(cx * size.width, cy * size.height),
        radius: r * size.width,
      ));
      canvas.drawCircle(
        Offset(cx * size.width, cy * size.height),
        r * size.width,
        paint,
      );
    }

    final s = math.sin(t * math.pi * 2);
    final c = math.cos(t * math.pi * 2);

    drawBlob(0.15 + s * 0.05, 0.2 + c * 0.04, 0.45, _kAurora1, 0.06);
    drawBlob(0.85 + c * 0.05, 0.15 + s * 0.03, 0.4, _kAurora2, 0.05);
    drawBlob(0.5 + s * 0.08, 0.85 + c * 0.04, 0.5, _kAurora3, 0.04);
  }

  @override
  bool shouldRepaint(_AuroraPainter old) => old.t != t;
}

// ─────────────────────────────────────────────────────────────────────────────
//  NEURAL PULSE AVATAR
// ─────────────────────────────────────────────────────────────────────────────

class _NeuralAvatar extends StatelessWidget {
  final double size;
  final Animation<double> pulse;
  final bool active;

  const _NeuralAvatar({
    required this.size,
    required this.pulse,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (_, __) {
        return SizedBox(
          width: size + 20,
          height: size + 20,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer pulse ring
              if (active)
                Opacity(
                  opacity: (1 - pulse.value) * 0.6,
                  child: Container(
                    width: size + 14 + pulse.value * 10,
                    height: size + 14 + pulse.value * 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _kAurora1.withOpacity(0.5),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              // Inner glow ring
              Container(
                width: size + 6,
                height: size + 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [
                      _kAurora1.withOpacity(active ? 0.8 : 0.3),
                      _kAurora2.withOpacity(active ? 0.6 : 0.2),
                      _kAurora3.withOpacity(active ? 0.4 : 0.1),
                      _kAurora1.withOpacity(active ? 0.8 : 0.3),
                    ],
                    transform: GradientRotation(pulse.value * math.pi * 2),
                  ),
                ),
              ),
              // Avatar
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _kGlassCard,
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/AiLogo.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  MAIN OVERLAY
// ─────────────────────────────────────────────────────────────────────────────

class AiAssistantOverlay extends StatefulWidget {
  const AiAssistantOverlay({super.key});

  @override
  State<AiAssistantOverlay> createState() => _AiAssistantOverlayState();
}

class _AiAssistantOverlayState extends State<AiAssistantOverlay>
    with TickerProviderStateMixin {
  // Controllers
  late final AnimationController _auroraCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _waveCtrl;
  late final AnimationController _slideCtrl;

  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _showSend = false;

  @override
  void initState() {
    super.initState();

    _auroraCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();

    _textCtrl.addListener(() {
      final v = _textCtrl.text.trim().isNotEmpty;
      if (v != _showSend) setState(() => _showSend = v);
    });
  }

  @override
  void dispose() {
    _auroraCtrl.dispose();
    _pulseCtrl.dispose();
    _waveCtrl.dispose();
    _slideCtrl.dispose();
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _send(AiAssistantCubit cubit) {
    final t = _textCtrl.text.trim();
    if (t.isEmpty) return;
    HapticFeedback.lightImpact();
    cubit.sendTextMessage(t);
    _textCtrl.clear();
  }

  // ─────────────────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AiAssistantCubit()..greet(),
      child: BlocConsumer<AiAssistantCubit, AiAssistantState>(
        listener: (_, state) => _scrollToBottom(),
        builder: (context, state) {
          final cubit = context.read<AiAssistantCubit>();
          final isActive =
              state.status != AiAssistantStatus.idle;

          return AnimatedBuilder(
            animation: _slideCtrl,
            builder: (_, child) {
              final slide = CurvedAnimation(
                parent: _slideCtrl,
                curve: Curves.easeOutCubic,
              );
              return Transform.translate(
                offset: Offset(0, (1 - slide.value) * 60),
                child: Opacity(opacity: slide.value, child: child),
              );
            },
            child: Stack(
              children: [
                _buildSheet(context, state, cubit, isActive),
                if (state.showProfileUpdatedNotification)
                  _buildProfileToast(),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  //  SHEET
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildSheet(
    BuildContext context,
    AiAssistantState state,
    AiAssistantCubit cubit,
    bool isActive,
  ) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: const BoxDecoration(
        color: _kGlassDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: Stack(
          children: [
            // Aurora background
            AnimatedBuilder(
              animation: _auroraCtrl,
              builder: (_, __) => CustomPaint(
                painter: _AuroraPainter(_auroraCtrl.value),
                size: Size.infinite,
              ),
            ),

            // Content
            Column(
              children: [
                _buildHandle(),
                _buildHeader(context, cubit, state, isActive),
                Expanded(child: _buildMessages(context, state)),
                _buildInput(context, cubit, state),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Handle ────────────────────────────────────────────────────────────

  Widget _buildHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 4),
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────

  Widget _buildHeader(
    BuildContext context,
    AiAssistantCubit cubit,
    AiAssistantState state,
    bool isActive,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 12, 12),
      child: Row(
        children: [
          _NeuralAvatar(
            size: 44,
            pulse: _pulseCtrl,
            active: isActive,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'İşçi AI',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Role badge
                    if (state.userRole != UserRole.unknown)
                      _RoleBadge(role: state.userRole),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _statusColor(state.status),
                        boxShadow: [
                          BoxShadow(
                            color: _statusColor(state.status).withOpacity(0.6),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        _statusLabel(state.status),
                        key: ValueKey(state.status),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.5),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Reset
          _GlassButton(
            onTap: () {
              HapticFeedback.mediumImpact();
              cubit.resetConversation();
            },
            child: const Icon(
              Icons.refresh_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  // ── Messages ─────────────────────────────────────────────────────────

  Widget _buildMessages(BuildContext context, AiAssistantState state) {
    if (state.messages.isEmpty) {
      return _buildEmptyState();
    }

    final itemCount = state.messages.length +
        (state.status == AiAssistantStatus.thinking ? 1 : 0);

    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      itemCount: itemCount,
      itemBuilder: (context, i) {
        if (i == state.messages.length) {
          return _buildThinkingBubble();
        }
        return _buildMessageItem(state.messages[i], i == state.messages.length - 1);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _NeuralAvatar(size: 72, pulse: _pulseCtrl, active: true),
          const SizedBox(height: 20),
          const Text(
            'İşçi AI',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'İş axtarışı, profil, məsləhət —\nhər şey üçün buradayam.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.45),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 28),
          // Quick action chips
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              '🔍 İş tap',
              '📝 Profil doldur',
              '💡 Məsləhət',
              '💰 Maaş',
            ].map((label) => _QuickChip(label: label)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(AiMessage msg, bool isLatest) {
    // Strip hidden tags
    final tagRx = RegExp(
      r'\[(PROFILE_UPDATE|JOB_SEARCH|ROLE_DETECT)\][\s\S]*?\[\/\1\]',
    );
    final clean = msg.text.replaceAll(tagRx, '').trim();

    if (clean.isEmpty && (msg.jobs == null || msg.jobs!.isEmpty)) {
      return const SizedBox.shrink();
    }

    return _AnimatedMessageWrapper(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(
          crossAxisAlignment:
              msg.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment:
                  msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // AI mini avatar
                if (!msg.isUser) ...[
                  Container(
                    width: 26,
                    height: 26,
                    margin: const EdgeInsets.only(right: 8, bottom: 2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const SweepGradient(
                        colors: [_kAurora1, _kAurora2, _kAurora3, _kAurora1],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(1.5),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/AiLogo.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ],

                // Bubble
                Flexible(
                  child: _buildBubble(msg, clean, isLatest && !msg.isUser),
                ),
              ],
            ),

            // Job cards
            if (msg.jobs != null && msg.jobs!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Padding(
                padding: EdgeInsets.only(left: msg.isUser ? 0 : 34),
                child: Column(
                  children: msg.jobs!.asMap().entries.map((e) {
                    return _AnimatedJobCard(
                      job: e.value,
                      delay: Duration(milliseconds: 120 * e.key),
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => JobDetailScreen(job: e.value),
                          ),
                        );
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBubble(AiMessage msg, String text, bool typewrite) {
    if (msg.isUser) {
      return Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_kAurora1, Color(0xFF9B59B6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(4),
          ),
          boxShadow: [
            BoxShadow(
              color: _kAurora1.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white,
            height: 1.5,
          ),
        ),
      );
    }

    // AI bubble — glass morphism
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.76,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(20),
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: typewrite
          ? _TypewriterText(
              text: text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
                height: 1.6,
              ),
            )
          : Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
                height: 1.6,
              ),
            ),
    );
  }

  // ── Thinking bubble ───────────────────────────────────────────────────

  Widget _buildThinkingBubble() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 26,
            height: 26,
            margin: const EdgeInsets.only(right: 8, bottom: 2),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: [_kAurora1, _kAurora2, _kAurora3, _kAurora1],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(1.5),
              child: ClipOval(
                child: Image.asset('assets/images/AiLogo.png', fit: BoxFit.cover),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: AnimatedBuilder(
              animation: _waveCtrl,
              builder: (_, __) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    final phase = ((_waveCtrl.value + i * 0.28) % 1.0);
                    final h = 5.0 + phase * 11.0;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 50),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: 5,
                      height: h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            _kAurora2.withOpacity(0.5 + phase * 0.5),
                            _kAurora1.withOpacity(0.3 + phase * 0.7),
                          ],
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Input area ────────────────────────────────────────────────────────

  Widget _buildInput(
    BuildContext context,
    AiAssistantCubit cubit,
    AiAssistantState state,
  ) {
    final isListening = state.status == AiAssistantStatus.listening;
    final isThinking = state.status == AiAssistantStatus.thinking;
    final isSpeaking = state.status == AiAssistantStatus.speaking;
    final busy = isThinking;

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: _kGlassDark.withOpacity(0.8),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Text input
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 48, maxHeight: 120),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              child: TextField(
                controller: _textCtrl,
                enabled: !busy && !isListening,
                maxLines: null,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.4,
                ),
                decoration: InputDecoration(
                  hintText: isListening
                      ? '🎙  Dinləyirəm...'
                      : busy
                      ? '⏳  Düşünür...'
                      : 'Bir şey yazın...',
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 13,
                  ),
                ),
                onSubmitted: (_) => _send(cubit),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Send / Mic button
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            switchInCurve: Curves.easeOutBack,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, anim) => ScaleTransition(
              scale: anim,
              child: FadeTransition(opacity: anim, child: child),
            ),
            child: _showSend
                ? _SendButton(
                    key: const ValueKey('send'),
                    onTap: () => _send(cubit),
                  )
                : _MicButton(
                    key: const ValueKey('mic'),
                    pulse: _pulseCtrl,
                    isListening: isListening,
                    isSpeaking: isSpeaking,
                    isThinking: isThinking,
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      if (isListening) {
                        cubit.stopListening();
                      } else if (isSpeaking) {
                        cubit.voiceService.stopSpeaking();
                      } else if (!isThinking) {
                        cubit.startListening();
                      }
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ── Profile toast ─────────────────────────────────────────────────────

  Widget _buildProfileToast() {
    return Positioned(
      top: 64,
      left: 16,
      right: 16,
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
        tween: Tween(begin: 0.0, end: 1.0),
        builder: (_, v, child) {
          return Transform.translate(
            offset: Offset(0, -24 * (1 - v)),
            child: Opacity(opacity: v, child: child),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF059669), Color(0xFF10B981)],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.verified_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Profil Yeniləndi ✓',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 1),
                  Text(
                    'AI tərəfindən uğurla güncəlləndi',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  String _statusLabel(AiAssistantStatus s) {
    switch (s) {
      case AiAssistantStatus.idle: return 'Hazır';
      case AiAssistantStatus.listening: return 'Dinləyir...';
      case AiAssistantStatus.thinking: return 'Düşünür...';
      case AiAssistantStatus.speaking: return 'Danışır...';
    }
  }

  Color _statusColor(AiAssistantStatus s) {
    switch (s) {
      case AiAssistantStatus.idle: return _kAurora3;
      case AiAssistantStatus.listening: return const Color(0xFFEF4444);
      case AiAssistantStatus.thinking: return _kAurora2;
      case AiAssistantStatus.speaking: return _kAurora1;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  SUPPORTING WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

/// Slide-up + fade wrapper for messages
class _AnimatedMessageWrapper extends StatefulWidget {
  final Widget child;
  const _AnimatedMessageWrapper({required this.child});

  @override
  State<_AnimatedMessageWrapper> createState() =>
      _AnimatedMessageWrapperState();
}

class _AnimatedMessageWrapperState extends State<_AnimatedMessageWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  )..forward();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        final v = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
        return Transform.translate(
          offset: Offset(0, 16 * (1 - v.value)),
          child: Opacity(opacity: v.value, child: child),
        );
      },
      child: widget.child,
    );
  }
}

/// Animated job card
class _AnimatedJobCard extends StatefulWidget {
  final JobModel job;
  final Duration delay;
  final VoidCallback onTap;

  const _AnimatedJobCard({
    required this.job,
    required this.delay,
    required this.onTap,
  });

  @override
  State<_AnimatedJobCard> createState() => _AnimatedJobCardState();
}

class _AnimatedJobCardState extends State<_AnimatedJobCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        final v = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
        return Transform.translate(
          offset: Offset(0, 20 * (1 - v.value)),
          child: Opacity(opacity: v.value, child: child),
        );
      },
      child: _JobCardBody(job: widget.job, onTap: widget.onTap),
    );
  }
}

class _JobCardBody extends StatelessWidget {
  final JobModel job;
  final VoidCallback onTap;

  const _JobCardBody({required this.job, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final pct = job.matchPercentage ?? 0;
    final matchColor = pct >= 80
        ? _kAurora3
        : pct >= 60
        ? _kAurora2
        : const Color(0xFFF59E0B);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          splashColor: _kAurora1.withOpacity(0.1),
          highlightColor: Colors.transparent,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Icon box
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _kAurora1.withOpacity(0.3),
                        _kAurora2.withOpacity(0.2),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.work_outline_rounded,
                    color: Colors.white70,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${job.companyName}  ·  ${job.city}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.45),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (job.salaryMin > 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          job.salaryText,
                          style: TextStyle(
                            color: _kAurora3,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // Match badge
                if (pct > 0)
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: matchColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: matchColor.withOpacity(0.4),
                          ),
                        ),
                        child: Text(
                          '%$pct',
                          style: TextStyle(
                            color: matchColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),

                const SizedBox(width: 6),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: Colors.white.withOpacity(0.25),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Glass icon button
class _GlassButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;

  const _GlassButton({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: child,
      ),
    );
  }
}

/// Quick action chip
class _QuickChip extends StatelessWidget {
  final String label;
  const _QuickChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withOpacity(0.6),
          fontSize: 13,
        ),
      ),
    );
  }
}

/// Role badge
class _RoleBadge extends StatelessWidget {
  final UserRole role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final isSeeker = role == UserRole.seeker;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (isSeeker ? _kAurora2 : _kAurora3).withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (isSeeker ? _kAurora2 : _kAurora3).withOpacity(0.4),
        ),
      ),
      child: Text(
        isSeeker ? 'İş arayan' : 'İşveren',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: isSeeker ? _kAurora2 : _kAurora3,
        ),
      ),
    );
  }
}

/// Send button
class _SendButton extends StatelessWidget {
  final VoidCallback onTap;
  const _SendButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_kAurora1, _kAurora2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: _kAurora1.withOpacity(0.4),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
      ),
    );
  }
}

/// Microphone button with neural pulse
class _MicButton extends StatelessWidget {
  final Animation<double> pulse;
  final bool isListening;
  final bool isSpeaking;
  final bool isThinking;
  final VoidCallback onTap;

  const _MicButton({
    super.key,
    required this.pulse,
    required this.isListening,
    required this.isSpeaking,
    required this.isThinking,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: pulse,
        builder: (_, __) {
          final scale = isListening ? 1.0 + pulse.value * 0.12 : 1.0;

          final colors = isListening
              ? [const Color(0xFFFF4757), const Color(0xFFFF6B81)]
              : isSpeaking
              ? [_kAurora3, _kAurora2]
              : isThinking
              ? [_kAurora2, _kAurora1]
              : [_kAurora1, _kAurora2];

          return Transform.scale(
            scale: scale,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer ring (listening)
                if (isListening)
                  Opacity(
                    opacity: (1 - pulse.value) * 0.5,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.red.withOpacity(0.6),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: colors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: colors.first.withOpacity(
                          isListening ? 0.6 : 0.35,
                        ),
                        blurRadius: isListening ? 22 : 12,
                        spreadRadius: isListening ? 2 : 0,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, anim) => ScaleTransition(
                      scale: anim,
                      child: FadeTransition(opacity: anim, child: child),
                    ),
                    child: Icon(
                      isListening
                          ? Icons.stop_rounded
                          : isSpeaking
                          ? Icons.volume_up_rounded
                          : Icons.mic_rounded,
                      key: ValueKey('$isListening$isSpeaking'),
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  FAB
// ─────────────────────────────────────────────────────────────────────────────

class AiAssistantFab extends StatefulWidget {
  const AiAssistantFab({super.key});

  @override
  State<AiAssistantFab> createState() => _AiAssistantFabState();
}

class _AiAssistantFabState extends State<AiAssistantFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glow = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glow,
      builder: (_, __) {
        return Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const SweepGradient(
              colors: [_kAurora1, _kAurora2, _kAurora3, _kAurora1],
            ),
            boxShadow: [
              BoxShadow(
                color: _kAurora1.withOpacity(0.3 + _glow.value * 0.25),
                blurRadius: 14 + _glow.value * 10,
                spreadRadius: _glow.value * 2,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: Material(
              color: _kGlassDark,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () {
                  HapticFeedback.mediumImpact();
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const AiAssistantOverlay(),
                  );
                },
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/AiLogo.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}