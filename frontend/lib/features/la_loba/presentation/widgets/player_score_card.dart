import 'package:flutter/material.dart';

class PlayerScoreCard extends StatefulWidget {
  final String participantId;
  final int currentScore;
  final ValueChanged<int> onScoreChanged;

  const PlayerScoreCard({
    super.key,
    required this.participantId,
    required this.currentScore,
    required this.onScoreChanged,
  });

  @override
  State<PlayerScoreCard> createState() => _PlayerScoreCardState();
}

class _PlayerScoreCardState extends State<PlayerScoreCard> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.currentScore.toString(),
    );
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant PlayerScoreCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextText = widget.currentScore.toString();
    final changedExternally =
        oldWidget.currentScore != widget.currentScore;

    if (changedExternally &&
        !_focusNode.hasFocus &&
        _controller.text != nextText) {
      _controller.text = nextText;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                widget.participantId,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () =>
                  widget.onScoreChanged(widget.currentScore - 1),
            ),
            SizedBox(
              width: 60,
              child: TextField(
                key: ValueKey('score_${widget.participantId}'),
                focusNode: _focusNode,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                controller: _controller,
                onChanged: (value) {
                  final parsed = int.tryParse(value);
                  if (parsed != null) {
                    widget.onScoreChanged(parsed);
                  }
                },
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () =>
                  widget.onScoreChanged(widget.currentScore + 1),
            ),
          ],
        ),
      ),
    );
  }
}
