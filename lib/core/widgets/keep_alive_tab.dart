import 'package:material_ui/material_ui.dart';

/// Keeps a tab page alive while another tab is shown, so switching back
/// doesn't rebuild it (no re-sorting, no cover reloads) and its scroll
/// position and state are kept. It still updates when its data changes.
class KeepAliveTab extends StatefulWidget {
  const KeepAliveTab({super.key, required this.child});

  final Widget child;

  @override
  State<KeepAliveTab> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<KeepAliveTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
