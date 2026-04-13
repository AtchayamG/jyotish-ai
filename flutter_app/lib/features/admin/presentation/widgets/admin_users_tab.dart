// lib/features/admin/presentation/widgets/admin_users_tab.dart
import "package:flutter/material.dart";
import "../../../../core/theme/app_theme.dart";
import "admin_api.dart";

class AdminUsersTab extends StatefulWidget {
  const AdminUsersTab({super.key});
  @override
  State<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<AdminUsersTab> {
  List _users = [], _filtered = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final u = await AdminApi.getUsers();
      setState(() {
        _users = u;
        _filtered = u;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) _snack("Error loading users");
    }
  }

  void _filter(String q) {
    final ql = q.toLowerCase();
    setState(() {
      _filtered = _users
          .where((u) =>
              (u["email"] ?? "").toLowerCase().contains(ql) ||
              (u["full_name"] ?? "").toLowerCase().contains(ql))
          .toList();
    });
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));

  @override
  Widget build(BuildContext context) {
    if (_loading)
      return const Center(
          child: CircularProgressIndicator(color: AppColors.gold));
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Row(children: [
          Expanded(
              child: TextField(
            onChanged: _filter,
            style: AppTextStyles.bodyMd,
            decoration: InputDecoration(
              hintText: "Search users…",
              hintStyle:
                  AppTextStyles.bodySm.copyWith(color: AppColors.textHint),
              prefixIcon:
                  const Icon(Icons.search, size: 18, color: AppColors.textHint),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          )),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.person_add, color: AppColors.gold),
            onPressed: _showAddDialog,
            tooltip: "Add User",
          ),
        ]),
      ),
      Expanded(
          child: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.gold,
        child: _filtered.isEmpty
            // FIX: removed "const" — AppTextStyles.bodySm is not a compile-time constant
            ? Center(child: Text("No users found", style: AppTextStyles.bodySm))
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _filtered.length,
                itemBuilder: (_, i) => _userCard(_filtered[i]),
              ),
      )),
    ]);
  }

  Widget _userCard(Map u) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Row(children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.goldDim,
            child: Text(
              ((u["full_name"] as String?) ?? "?").isNotEmpty
                  ? ((u["full_name"] as String)[0]).toUpperCase()
                  : "?",
              style: AppTextStyles.labelMd.copyWith(color: AppColors.gold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(u["full_name"] ?? "—", style: AppTextStyles.labelMd),
                Text(u["email"] ?? "", style: AppTextStyles.bodyXs),
                const SizedBox(height: 4),
                Row(children: [
                  _chip(
                    u["is_admin"] == true
                        ? "Admin"
                        : u["is_premium"] == true
                            ? "Premium"
                            : "Free",
                    u["is_admin"] == true
                        ? AppColors.teal
                        : u["is_premium"] == true
                            ? AppColors.violet
                            : AppColors.textHint,
                  ),
                  const SizedBox(width: 6),
                  _chip(u["is_active"] == true ? "Active" : "Inactive",
                      u["is_active"] == true ? AppColors.teal : AppColors.rose),
                ]),
              ])),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert,
                color: AppColors.textHint, size: 20),
            color: AppColors.surface2,
            itemBuilder: (_) => const [
              PopupMenuItem(value: "edit", child: Text("Edit Access")),
              PopupMenuItem(value: "toggle", child: Text("Toggle Active")),
              PopupMenuItem(
                  value: "delete",
                  child: Text("Delete",
                      style: TextStyle(color: Color(0xFFe85d8b)))),
            ],
            onSelected: (v) {
              if (v == "edit") _showEditDialog(u);
              if (v == "toggle") _toggle(u);
              if (v == "delete") _delete(u);
            },
          ),
        ]),
      );

  Widget _chip(String t, Color c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: c.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.withOpacity(0.3)),
        ),
        child: Text(t,
            style:
                TextStyle(fontSize: 9, color: c, fontWeight: FontWeight.w600)),
      );

  Future<void> _toggle(Map u) async {
    try {
      await AdminApi.updateUser(
          u["id"] as String, {"is_active": !(u["is_active"] == true)});
      _load();
      _snack("Status updated");
    } catch (e) {
      _snack("Error: $e");
    }
  }

  Future<void> _delete(Map u) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text("Delete User"),
        content: Text("Delete ${u["email"]}?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel")),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Delete",
                  style: TextStyle(color: Color(0xFFe85d8b)))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await AdminApi.deleteUser(u["id"] as String);
      _load();
      _snack("Deleted");
    } catch (e) {
      _snack("Error: $e");
    }
  }

  void _showAddDialog() {
    final nameC = TextEditingController(),
        emailC = TextEditingController(),
        passC = TextEditingController();
    String access = "free";
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: StatefulBuilder(
            builder: (ctx, ss) =>
                Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text("Add New User", style: AppTextStyles.displayXs),
                  const SizedBox(height: 16),
                  TextField(
                      controller: nameC,
                      style: AppTextStyles.bodyMd,
                      decoration:
                          const InputDecoration(labelText: "Full Name")),
                  const SizedBox(height: 10),
                  TextField(
                      controller: emailC,
                      keyboardType: TextInputType.emailAddress,
                      style: AppTextStyles.bodyMd,
                      decoration: const InputDecoration(labelText: "Email")),
                  const SizedBox(height: 10),
                  TextField(
                      controller: passC,
                      obscureText: true,
                      style: AppTextStyles.bodyMd,
                      decoration: const InputDecoration(labelText: "Password")),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: access,
                    decoration:
                        const InputDecoration(labelText: "Access Level"),
                    dropdownColor: AppColors.surface2,
                    items: const [
                      DropdownMenuItem(value: "free", child: Text("Free")),
                      DropdownMenuItem(
                          value: "premium", child: Text("Premium")),
                      DropdownMenuItem(value: "admin", child: Text("Admin")),
                    ],
                    onChanged: (v) => ss(() => access = v ?? "free"),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          try {
                            await AdminApi.createUser({
                              "full_name": nameC.text,
                              "email": emailC.text,
                              "password": passC.text,
                              "is_premium": access != "free",
                              "is_admin": access == "admin",
                              "is_active": true,
                            });
                            _load();
                            _snack("Created: ${emailC.text}");
                          } catch (e) {
                            _snack("Error: $e");
                          }
                        },
                        child: const Text("Create User"),
                      )),
                ])),
      ),
    );
  }

  void _showEditDialog(Map u) {
    String access = u["is_admin"] == true
        ? "admin"
        : u["is_premium"] == true
            ? "premium"
            : "free";
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: StatefulBuilder(
            builder: (ctx, ss) =>
                Column(mainAxisSize: MainAxisSize.min, children: [
                  Text("Edit: ${u["email"]}", style: AppTextStyles.displayXs),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: access,
                    decoration:
                        const InputDecoration(labelText: "Access Level"),
                    dropdownColor: AppColors.surface2,
                    items: const [
                      DropdownMenuItem(value: "free", child: Text("Free")),
                      DropdownMenuItem(
                          value: "premium", child: Text("Premium")),
                      DropdownMenuItem(value: "admin", child: Text("Admin")),
                    ],
                    onChanged: (v) => ss(() => access = v ?? "free"),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          try {
                            await AdminApi.updateUser(u["id"] as String, {
                              "is_premium": access != "free",
                              "is_admin": access == "admin",
                            });
                            _load();
                            _snack("Access updated");
                          } catch (e) {
                            _snack("Error: $e");
                          }
                        },
                        child: const Text("Save Changes"),
                      )),
                ])),
      ),
    );
  }
}
