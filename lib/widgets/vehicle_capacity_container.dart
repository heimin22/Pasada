import 'package:flutter/material.dart';

class VehicleCapacityContainer extends StatelessWidget {
  final int? totalPassengers;
  final int? sittingPassengers;
  final int? standingPassengers;

  const VehicleCapacityContainer({
    super.key,
    this.totalPassengers,
    this.sittingPassengers,
    this.standingPassengers,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vehicle Capacity',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDarkMode
                  ? const Color(0xFFF5F5F5)
                  : const Color(0xFF121212),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildInfoChip(
                context,
                label: 'Total',
                value: totalPassengers,
                color: const Color(0xFF00CC58),
              ),
              const SizedBox(width: 8),
              _buildInfoChip(
                context,
                label: 'Sitting',
                value: sittingPassengers,
                color: Colors.blue,
              ),
              const SizedBox(width: 8),
              _buildInfoChip(
                context,
                label: 'Standing',
                value: standingPassengers,
                color: Colors.orange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context,
      {required String label, required int? value, required Color color}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final display = value == null ? '—' : value.toString();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            '$label: $display',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDarkMode
                  ? const Color(0xFFF5F5F5)
                  : const Color(0xFF121212),
            ),
          ),
        ],
      ),
    );
  }
}
