import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:lore_keeper/models/project.dart';

class AboutAuthorForm extends StatefulWidget {
  final Project project;

  const AboutAuthorForm({super.key, required this.project});

  @override
  State<AboutAuthorForm> createState() => _AboutAuthorFormState();
}

class _AboutAuthorFormState extends State<AboutAuthorForm> {
  late TextEditingController _bioController;
  late TextEditingController _emailController;
  late TextEditingController _websiteController;
  late TextEditingController _twitterController;
  late TextEditingController _instagramController;
  late TextEditingController _facebookController;

  @override
  void initState() {
    super.initState();
    _bioController = TextEditingController(text: widget.project.authorBio);
    _emailController = TextEditingController(text: widget.project.authorEmail);
    _websiteController = TextEditingController(
      text: widget.project.authorWebsite,
    );
    _twitterController = TextEditingController(
      text: widget.project.authorTwitter,
    );
    _instagramController = TextEditingController(
      text: widget.project.authorInstagram,
    );
    _facebookController = TextEditingController(
      text: widget.project.authorFacebook,
    );
  }

  @override
  void dispose() {
    _bioController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _twitterController.dispose();
    _instagramController.dispose();
    _facebookController.dispose();
    super.dispose();
  }

  void _save() {
    widget.project.authorBio = _bioController.text;
    widget.project.authorEmail = _emailController.text;
    widget.project.authorWebsite = _websiteController.text;
    widget.project.authorTwitter = _twitterController.text;
    widget.project.authorInstagram = _instagramController.text;
    widget.project.authorFacebook = _facebookController.text;
    widget.project.save();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Author details saved')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'About the Author',
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Provide details that will appear in your manuscript\'s "About the Author" section.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),

              _buildSectionHeader('General Information'),
              _buildTextField(
                controller: _bioController,
                label: 'Biography',
                hint: 'Tell your readers about yourself...',
                maxLines: 6,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _emailController,
                      label: 'Contact Email',
                      hint: 'author@example.com',
                      icon: LucideIcons.mail,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _websiteController,
                      label: 'Website',
                      hint: 'https://yourwebsite.com',
                      icon: LucideIcons.globe,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
              _buildSectionHeader('Social Media'),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _twitterController,
                      label: 'Twitter / X',
                      hint: '@username',
                      icon: LucideIcons.atSign,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _instagramController,
                      label: 'Instagram',
                      hint: 'username',
                      icon: LucideIcons.camera,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _facebookController,
                label: 'Facebook',
                hint: 'facebook.com/username',
                icon: LucideIcons.facebook,
              ),

              const SizedBox(height: 48),
              Center(
                child: FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(LucideIcons.save),
                  label: const Text('Save Author Details'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 64),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    IconData? icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon) : null,
        alignLabelWithHint: maxLines > 1,
      ),
    );
  }
}
