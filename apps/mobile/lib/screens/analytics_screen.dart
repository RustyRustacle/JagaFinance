import 'package:flutter/material.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  static const _pieColors = [
    Color(0xFF3B82F6),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
  ];

  static const _pieData = [
    (label: 'Operational', percentage: 0.35, amount: 'Rp 4.9M', color: _pieColors[0]),
    (label: 'Transport', percentage: 0.20, amount: 'Rp 2.8M', color: _pieColors[1]),
    (label: 'Office Supply', percentage: 0.25, amount: 'Rp 3.5M', color: _pieColors[2]),
    (label: 'F&B', percentage: 0.12, amount: 'Rp 1.7M', color: _pieColors[3]),
    (label: 'Others', percentage: 0.08, amount: 'Rp 1.1M', color: _pieColors[4]),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Analytics',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF64748B)),
                        SizedBox(width: 6),
                        Text(
                          'May 2026',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Total expense
              const Text(
                'Total Expenses',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Rp 14.280.000',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1FAE5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_upward, size: 12, color: Color(0xFF10B981)),
                          SizedBox(width: 2),
                          Text(
                            '+8.2%',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Pie chart + legend row
              Row(
                children: [
                  // Pie chart
                  SizedBox(
                    width: 140,
                    height: 140,
                    child: CustomPaint(
                      size: const Size(140, 140),
                      painter: _PieChartPainter(),
                    ),
                  ),
                  const SizedBox(width: 20),

                  // Legend
                  Expanded(
                    child: Column(
                      children: _pieData.map((d) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: d.color,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  d.label,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              Text(
                                d.amount,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Budget sections header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Budget Monitoring',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(foregroundColor: const Color(0xFF3B82F6)),
                    child: const Text(
                      'Details',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Budget bars
              _buildBudgetBar('Operational', 0.70, 'Rp 4.9M / Rp 7.0M', const Color(0xFF3B82F6)),
              const SizedBox(height: 14),
              _buildBudgetBar('Transport', 0.45, 'Rp 2.8M / Rp 6.2M', const Color(0xFF10B981)),
              const SizedBox(height: 14),
              _buildBudgetBar('Office Supply', 0.82, 'Rp 3.5M / Rp 4.3M', const Color(0xFFF59E0B)),
              const SizedBox(height: 14),
              _buildBudgetBar('F&B', 0.55, 'Rp 1.7M / Rp 3.1M', const Color(0xFF8B5CF6)),
              const SizedBox(height: 14),
              _buildBudgetBar('Others', 0.30, 'Rp 1.1M / Rp 3.7M', const Color(0xFFEC4899)),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBudgetBar(String label, double progress, String detail, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
              ),
              Text(
                detail,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _PieChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    final segments = [0.35, 0.20, 0.25, 0.12, 0.08];
    final colors = AnalyticsScreen._pieColors;

    double startAngle = -90 * (3.14159 / 180); // Start from top

    for (int i = 0; i < segments.length; i++) {
      final sweepAngle = segments[i] * 360 * (3.14159 / 180);

      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.fill;

      // Shadow
      canvas.drawArc(
        Rect.fromCircle(center: center + const Offset(0, 2), radius: radius),
        startAngle,
        sweepAngle,
        true,
        Paint()..color = colors[i].withOpacity(0.2),
      );

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      startAngle += sweepAngle;
    }

    // Center cutout for donut effect
    canvas.drawCircle(
      center,
      radius * 0.55,
      Paint()..color = Colors.white,
    );

    // Center text background
    canvas.drawCircle(
      center,
      radius * 0.55,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
