import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _cortexModeEnabled = true;
  bool _autoReplyEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      body: SafeArea(
        child: Center(
          child: SizedBox(
            width: 290,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(36),
                  child: Container(
                    width: 290,
                    color: const Color(0xFFF1F1F1),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 8),
                        Container(
                          width: 78,
                          height: 8,
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCDCDC),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.only(top: 20, bottom: 18),
                          decoration: const BoxDecoration(
                            color: Color(0xFF216D66),
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(30),
                              bottomRight: Radius.circular(30),
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 78,
                                height: 78,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF2A61B),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFFF8D177), width: 2.5),
                                ),
                                alignment: Alignment.center,
                                child: const Text(
                                  'A',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 40,
                                    fontWeight: FontWeight.w700,
                                    height: 1,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Arjun Sharma',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 46,
                                  fontWeight: FontWeight.w700,
                                  height: 0.95,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Pro Member',
                                style: TextStyle(
                                  color: Color(0xFFA8C3BF),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  height: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: InkWell(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Add Account / Integration tapped'),
                                  duration: Duration(milliseconds: 1000),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: double.infinity,
                              height: 44,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFD0D0D0)),
                              ),
                              child: const Text(
                                '+ Add Account / Integration',
                                style: TextStyle(
                                  color: Color(0xFFF2A61B),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 22),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Connected',
                              style: TextStyle(
                                color: Color(0xFF7D7D7D),
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _integrationRow(
                          badge: 'W',
                          badgeColor: const Color(0xFFE2EEEC),
                          badgeTextColor: const Color(0xFF216D66),
                          label: 'WhatsApp',
                        ),
                        const SizedBox(height: 8),
                        _integrationRow(
                          badge: 'G',
                          badgeColor: const Color(0xFFF8EEDC),
                          badgeTextColor: const Color(0xFFD8A85A),
                          label: 'Gmail',
                        ),
                        const SizedBox(height: 12),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 22),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Settings',
                              style: TextStyle(
                                color: Color(0xFF7D7D7D),
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _settingToggleRow(
                          label: 'Cortex Mode',
                          value: _cortexModeEnabled,
                          onChanged: (value) {
                            setState(() {
                              _cortexModeEnabled = value;
                            });
                          },
                        ),
                        const SizedBox(height: 6),
                        _settingToggleRow(
                          label: 'Auto-Reply',
                          value: _autoReplyEnabled,
                          onChanged: (value) {
                            setState(() {
                              _autoReplyEnabled = value;
                            });
                          },
                        ),
                        const SizedBox(height: 10),
                        Container(
                          height: 68,
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF8F8F8),
                            border: Border(top: BorderSide(color: Color(0xFFE4E4E4))),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _bottomIcon(const Icon(Icons.crop_square_outlined, color: Color(0xFFBBBBBB), size: 24)),
                              _bottomIcon(const Icon(Icons.crop_square, color: Color(0xFFBBBBBB), size: 22)),
                              Container(
                                width: 54,
                                height: 54,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF2A61B),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: const Text(
                                  '−',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 30,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              _bottomIcon(const Icon(Icons.menu, color: Color(0xFFBBBBBB), size: 28)),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.circle_outlined, color: Color(0xFF216D66), size: 23),
                                  const SizedBox(height: 2),
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFF2A61B),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'PROFILE / SETTINGS',
                  style: TextStyle(
                    color: Color(0xFF808080),
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _integrationRow({
    required String badge,
    required Color badgeColor,
    required Color badgeTextColor,
    required String label,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFFFCFCFC),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: badgeColor,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                badge,
                style: TextStyle(
                  color: badgeTextColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF2D2D2D),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Text(
              'Active',
              style: TextStyle(
                color: Color(0xFF216D66),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingToggleRow({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFFEEEEEE),
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF2D2D2D),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Transform.scale(
              scale: 0.72,
              child: Switch(
                value: value,
                onChanged: onChanged,
                activeColor: Colors.white,
                activeTrackColor: const Color(0xFF216D66),
                inactiveThumbColor: const Color(0xFFF3F3F3),
                inactiveTrackColor: const Color(0xFFD8D8D8),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomIcon(Widget child) {
    return SizedBox(width: 30, height: 30, child: Center(child: child));
  }
}
