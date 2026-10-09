import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/leaderboard_repository.dart';
import '../../domain/game_config.dart';
import '../../shopwatch_dependencies.dart';
import '../../shopwatch_strings.dart';

class GameArguments {
  const GameArguments({required this.nickname, required this.count, required this.difficulty, required this.owned});
  final String nickname;
  final int count;
  final Difficulty difficulty;
  final bool owned;
}
class GameSetupPage extends StatefulWidget {
  const GameSetupPage({super.key, required this.dependencies, this.nickname = ''});
  final ShopwatchDependencies dependencies;
  final String nickname;
  @override
  State<GameSetupPage> createState() => _GameSetupPageState();
}
class _GameSetupPageState extends State<GameSetupPage> {
  late final _nickname = TextEditingController(text: widget.nickname);
  final _policy = const NicknamePolicy();
  Timer? _debounce;
  int _generation = 0, _count = 1;
  Difficulty _difficulty = Difficulty.easy;
  NicknameStatus _status = NicknameStatus.invalid;
  bool _starting = false;
  late Future<List<LeaderboardEntry>?> _board;
  @override
  void initState() { super.initState(); _loadBoard(); if (widget.nickname.isNotEmpty) _changed(widget.nickname); }
  void _loadBoard() { _board = widget.dependencies.repository.top(_count, _difficulty); }
  void _changed(String value) {
    _debounce?.cancel();
    final generation = ++_generation;
    setState(() => _status = _policy.isValid(value) ? NicknameStatus.checking : NicknameStatus.invalid);
    if (_status == NicknameStatus.invalid) return;
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      NicknameStatus status;
      try { status = await widget.dependencies.repository.check(value).timeout(const Duration(seconds: 6)); }
      catch (_) { status = NicknameStatus.offline; }
      if (mounted && generation == _generation) setState(() => _status = status);
    });
  }
  Future<void> _start() async {
    if (_starting || !_policy.isValid(_nickname.text)) return;
    _debounce?.cancel(); ++_generation;
    final nickname = _nickname.text.trim();
    setState(() => _starting = true);
    NicknameStatus reservation;
    try { reservation = await widget.dependencies.repository.reserve(nickname).timeout(const Duration(seconds: 6)); }
    catch (_) { reservation = NicknameStatus.offline; }
    if (!mounted) return;
    setState(() { _starting = false; _status = reservation; });
    if (reservation != NicknameStatus.available && reservation != NicknameStatus.offline) return;
    await Navigator.pushNamed(context, '/shopwatch/game/play', arguments: GameArguments(
      nickname: nickname, count: _count, difficulty: _difficulty, owned: reservation == NicknameStatus.available));
    if (mounted) setState(_loadBoard);
  }
  @override
  void dispose() { ++_generation; _debounce?.cancel(); _nickname.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Time is money')),
    body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Center(
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 600), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextField(key: ShopwatchKeys.nickname, controller: _nickname, enabled: !_starting,
          onChanged: _changed, decoration: const InputDecoration(labelText: 'Nickname', helperText: '3–16 letters, digits or underscore')),
        Text(switch (_status) {
          NicknameStatus.invalid => 'Enter a valid nickname.', NicknameStatus.checking => 'Checking…',
          NicknameStatus.available => 'Available ✓ (reserved on Start)', NicknameStatus.taken => 'Taken ✗',
          NicknameStatus.offline => ShopwatchStrings.offline,
        }, semanticsLabel: 'Nickname ${_status.name}'),
        const SizedBox(height: 20),
        DropdownButtonFormField<int>(initialValue: _count, decoration: const InputDecoration(labelText: 'Number of items'),
          items: [for (var i = 1; i <= widget.dependencies.config.items.length; i++) DropdownMenuItem(value: i, child: Text('$i'))],
          onChanged: _starting ? null : (value) => setState(() { _count = value!; _loadBoard(); })),
        const SizedBox(height: 16),
        DropdownButtonFormField<Difficulty>(initialValue: _difficulty, decoration: const InputDecoration(labelText: 'Difficulty'),
          items: [for (final d in Difficulty.values) DropdownMenuItem(value: d, child: Text(d.name))],
          onChanged: _starting ? null : (value) => setState(() { _difficulty = value!; _loadBoard(); })),
        const SizedBox(height: 16),
        FilledButton(key: ShopwatchKeys.startGame, onPressed: !_starting && _policy.isValid(_nickname.text) && _status != NicknameStatus.taken ? _start : null,
          child: Text(_starting ? 'Reserving…' : 'Start shopping')),
        const SizedBox(height: 24), const Text('TOP 10 • lower total difference wins'),
        FutureBuilder(future: _board, builder: (_, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const Text('Loading leaderboard…');
          final entries = snapshot.data;
          if (entries == null) return const Text('Leaderboard offline');
          if (entries.isEmpty) return const Text('No scores yet');
          return Column(children: [for (var i = 0; i < entries.length; i++) ListTile(
            title: Text('${i + 1}. ${entries[i].nickname}'), trailing: Text('${entries[i].totalDiffMs} ms'))]);
        }),
      ])),
    ))),
  );
}
