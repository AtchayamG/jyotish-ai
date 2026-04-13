// lib/features/admin/presentation/widgets/admin_notifications_tab.dart
import "package:flutter/material.dart";
import "../../../../core/theme/app_theme.dart";
import "admin_api.dart";

class AdminNotificationsTab extends StatefulWidget {
  const AdminNotificationsTab({super.key});
  @override State<AdminNotificationsTab> createState() => _State();
}
class _State extends State<AdminNotificationsTab> {
  final _titleC = TextEditingController();
  final _bodyC  = TextEditingController();
  String _target = "all";
  bool _sending = false;

  @override void dispose() { _titleC.dispose(); _bodyC.dispose(); super.dispose(); }

  Future<void> _send() async {
    if (_titleC.text.trim().isEmpty || _bodyC.text.trim().isEmpty) {
      _snack("Title and message are required", false); return;
    }
    setState(() => _sending = true);
    try {
      final r = await AdminApi.sendNotification({
        "title": _titleC.text.trim(), "body": _bodyC.text.trim(), "target": _target,
      });
      _snack("✓ Sent to ${r["sent_count"]} users", true);
      _titleC.clear(); _bodyC.clear();
    } catch (e) { _snack("Error: $e", false); }
    finally { if (mounted) setState(() => _sending = false); }
  }

  void _snack(String msg, bool ok) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg), behavior: SnackBarBehavior.floating,
    backgroundColor: ok ? const Color(0xFF2ec4b6) : const Color(0xFFe85d8b)));

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text("SEND PUSH NOTIFICATION", style: AppTextStyles.sectionTag),
      const SizedBox(height: 14),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.borderSubtle)),
        child: Column(children: [
          DropdownButtonFormField<String>(
            value: _target,
            decoration: const InputDecoration(labelText: "Target Audience"),
            dropdownColor: AppColors.surface2,
            items: const [
              DropdownMenuItem(value: "all",     child: Text("All Users")),
              DropdownMenuItem(value: "premium", child: Text("Premium Users Only")),
              DropdownMenuItem(value: "free",    child: Text("Free Users Only")),
            ],
            onChanged: (v) => setState(() => _target = v ?? "all"),
          ),
          const SizedBox(height: 12),
          TextField(controller: _titleC, style: AppTextStyles.bodyMd,
            decoration: const InputDecoration(labelText: "Notification Title *",
              hintText: "Your Daily Horoscope is Ready ✦")),
          const SizedBox(height: 12),
          TextField(controller: _bodyC, style: AppTextStyles.bodyMd, maxLines: 4,
            decoration: const InputDecoration(labelText: "Message Body *", alignLabelWithHint: true)),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: ElevatedButton.icon(
            onPressed: _sending ? null : _send,
            icon: _sending ? const SizedBox(width: 16, height: 16,
              child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send_rounded, size: 16),
            label: Text(_sending ? "Sending…" : "Send Notification"),
          )),
        ]),
      ),
      const SizedBox(height: 20),
      Text("DAILY SCHEDULE", style: AppTextStyles.sectionTag),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.borderSubtle)),
        child: Row(children: [
          const Icon(Icons.alarm, color: AppColors.gold, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("7:00 AM IST — Daily horoscope", style: AppTextStyles.labelMd.copyWith(color: AppColors.gold)),
            const SizedBox(height: 4),
            Text("Auto-scheduled on login via flutter_local_notifications",
              style: AppTextStyles.bodyXs),
          ])),
        ]),
      ),
    ]),
  );
}
