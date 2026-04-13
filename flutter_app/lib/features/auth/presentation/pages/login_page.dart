// lib/features/auth/presentation/pages/login_page.dart
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:go_router/go_router.dart";
import "../bloc/auth_bloc.dart";
import "../../../../core/theme/app_theme.dart";
import "../../../../core/router/app_router.dart";

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass  = TextEditingController();
  bool _obscure = true;

  @override void dispose() { _email.dispose(); _pass.dispose(); super.dispose(); }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    context.read<AuthBloc>().add(LoginRequested(_email.text.trim(), _pass.text));
  }

  @override
  Widget build(BuildContext context) => BlocListener<AuthBloc, AuthState>(
    listener: (context, state) {
      if (state is AuthError) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.message), backgroundColor: AppColors.rose,
          behavior: SnackBarBehavior.floating));
    },
    child: Scaffold(
      backgroundColor: AppColors.inkDeep,
      body: SafeArea(child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.x4l),
        child: Form(key: _form, child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: AppSpacing.x3l),
          Text("JYOTISH AI", style: AppTextStyles.sectionTag),
          const SizedBox(height: AppSpacing.sm),
          const Text("Welcome back", style: AppTextStyles.displayMd),
          const SizedBox(height: AppSpacing.sm),
          Text("Sign in to your cosmic journey", style: AppTextStyles.bodySm),
          const SizedBox(height: AppSpacing.x3l),
          TextFormField(controller: _email,
            keyboardType: TextInputType.emailAddress,
            style: AppTextStyles.bodyMd,
            decoration: const InputDecoration(labelText: "Email",
              prefixIcon: Icon(Icons.mail_outline, size: 18, color: AppColors.textHint)),
            validator: (v) => v!=null&&v.contains("@")?null:"Enter valid email"),
          const SizedBox(height: AppSpacing.lg),
          TextFormField(controller: _pass, obscureText: _obscure,
            style: AppTextStyles.bodyMd,
            decoration: InputDecoration(labelText: "Password",
              prefixIcon: const Icon(Icons.lock_outline, size: 18, color: AppColors.textHint),
              suffixIcon: IconButton(
                icon: Icon(_obscure?Icons.visibility_off_outlined:Icons.visibility_outlined,
                  size: 18, color: AppColors.textHint),
                onPressed: () => setState(() => _obscure=!_obscure))),
            validator: (v) => v!=null&&v.length>=6?null:"Min 6 characters"),
          const SizedBox(height: AppSpacing.x3l),
          BlocBuilder<AuthBloc,AuthState>(builder: (_,state) => ElevatedButton(
            onPressed: state is AuthLoading ? null : _submit,
            child: state is AuthLoading
              ? const SizedBox(height:20,width:20,
                  child:CircularProgressIndicator(strokeWidth:2,color:AppColors.ink))
              : const Text("Sign In"))),
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton(
            onPressed: () => context.go(AppRoutes.register),
            child: const Text("Create Account")),
        ])))),
    ),
  );
}
