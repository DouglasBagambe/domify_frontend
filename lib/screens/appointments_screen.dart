// 📁 lib/screens/appointments_screen.dart — real appointments management
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/appointments_provider.dart';
import '../widgets/legal_page_widgets.dart';
import 'property_detail_screen.dart';

class AppointmentsScreen extends StatefulWidget {
  final bool showBackButton;

  const AppointmentsScreen({
    super.key,
    this.showBackButton = true,
  });

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = const Color(0xFF178F5B);
    final navy = const Color(0xFF1A3C6E);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B111E) : const Color(0xFFF6F8F7),
      body: Consumer<AppointmentsProvider>(
        builder: (context, aProvider, _) {
          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverAppBar(
                expandedHeight: 170,
                pinned: true,
                forceElevated: innerBoxIsScrolled,
                backgroundColor: isDark ? const Color(0xFF0B111E) : Colors.white,
                automaticallyImplyLeading: widget.showBackButton,
                leading: widget.showBackButton ? const LegalBackButton() : null,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [primary, navy],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 55, 24, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              'Appointments',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                  color: Colors.white, fontWeight: FontWeight.w800),
                            ),
                            Text(
                              '${aProvider.upcoming.length} upcoming · ${aProvider.past.length} past',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withOpacity(0.75)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                bottom: TabBar(
                  controller: _tabCtrl,
                  indicatorColor: Colors.white,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white60,
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14),
                  tabs: const [
                    Tab(text: 'Upcoming'),
                    Tab(text: 'Past'),
                  ],
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabCtrl,
              children: [
                _ApptList(
                  appointments: aProvider.upcoming,
                  emptyTitle: 'No upcoming appointments',
                  emptySubtitle:
                      'Book a property viewing to see appointments here.',
                  isDark: isDark,
                  onCancel: (id) => _confirmCancel(context, aProvider, id),
                  onTap: (appt) => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          PropertyDetailScreen(propertyId: appt.propertyId),
                    ),
                  ),
                ),
                _ApptList(
                  appointments: aProvider.past,
                  emptyTitle: 'No past appointments',
                  emptySubtitle: 'Completed and cancelled appointments will appear here.',
                  isDark: isDark,
                  onDelete: (id) => aProvider.removeAppointment(id),
                  onTap: (appt) => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          PropertyDetailScreen(propertyId: appt.propertyId),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmCancel(
      BuildContext ctx, AppointmentsProvider p, String id) async {
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Cancel Appointment?'),
        content: const Text(
            'Are you sure you want to cancel this appointment? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep it')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Cancel Appointment',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) await p.cancelAppointment(id);
  }
}

// ── Appointment list ─────────────────────────────────────────────────────────

class _ApptList extends StatelessWidget {
  const _ApptList({
    required this.appointments,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.isDark,
    required this.onTap,
    this.onCancel,
    this.onDelete,
  });
  final List<Appointment> appointments;
  final String emptyTitle;
  final String emptySubtitle;
  final bool isDark;
  final void Function(Appointment) onTap;
  final void Function(String)? onCancel;
  final void Function(String)? onDelete;

  @override
  Widget build(BuildContext context) {
    if (appointments.isEmpty) {
      return _EmptyAppt(
          title: emptyTitle, subtitle: emptySubtitle);
    }
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 60),
      itemCount: appointments.length,
      itemBuilder: (context, i) {
        final appt = appointments[i];
        return _AppointmentCard(
          appt: appt,
          isDark: isDark,
          onTap: () => onTap(appt),
          onCancel: onCancel != null ? () => onCancel!(appt.id) : null,
          onDelete: onDelete != null ? () => onDelete!(appt.id) : null,
        );
      },
    );
  }
}

// ── Single appointment card ──────────────────────────────────────────────────

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({
    required this.appt,
    required this.isDark,
    required this.onTap,
    this.onCancel,
    this.onDelete,
  });
  final Appointment appt;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback? onCancel;
  final VoidCallback? onDelete;

  Color _statusColor(AppointmentStatus s) {
    switch (s) {
      case AppointmentStatus.confirmed:
        return const Color(0xFF178F5B);
      case AppointmentStatus.cancelled:
        return const Color(0xFFDC2626);
      case AppointmentStatus.completed:
        return const Color(0xFF1A3C6E);
      case AppointmentStatus.pending:
        return const Color(0xFFA17324);
    }
  }

  String _statusLabel(AppointmentStatus s) {
    switch (s) {
      case AppointmentStatus.confirmed:
        return 'Confirmed';
      case AppointmentStatus.cancelled:
        return 'Cancelled';
      case AppointmentStatus.completed:
        return 'Completed';
      case AppointmentStatus.pending:
        return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = const Color(0xFF178F5B);
    final statusColor = _statusColor(appt.status);
    final dateStr = DateFormat('EEE, d MMM yyyy').format(appt.appointmentTime);
    final timeStr = DateFormat('h:mm a').format(appt.appointmentTime);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF131B2E) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE4E7EC),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.15 : 0.045),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      appt.propertyTitle,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _statusLabel(appt.status),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Row(children: [
                Icon(Icons.location_on_outlined,
                    size: 13,
                    color: theme.colorScheme.onSurface.withOpacity(0.45)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    appt.propertyLocation,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ]),
            ),

            // Date/time strip
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primary.withOpacity(0.12)),
              ),
              child: Row(
                children: [
                  _InfoChip(
                      icon: Icons.calendar_today_rounded,
                      label: dateStr,
                      color: primary),
                  const SizedBox(width: 16),
                  _InfoChip(
                      icon: Icons.access_time_rounded,
                      label: timeStr,
                      color: primary),
                  const Spacer(),
                  _InfoChip(
                      icon: Icons.timelapse_rounded,
                      label: appt.duration,
                      color: primary),
                ],
              ),
            ),

            // Purpose + notes
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Wrap(spacing: 8, children: [
                _Tag(label: appt.purpose),
                if (appt.notes != null && appt.notes!.isNotEmpty)
                  _Tag(label: appt.notes!.length > 30
                      ? '${appt.notes!.substring(0, 30)}…'
                      : appt.notes!),
              ]),
            ),

            // Actions
            if (onCancel != null || onDelete != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onDelete != null)
                      TextButton.icon(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline_rounded,
                            size: 15, color: Colors.red),
                        label: const Text('Remove',
                            style: TextStyle(
                                color: Colors.red, fontSize: 12)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                        ),
                      ),
                    if (onCancel != null)
                      TextButton.icon(
                        onPressed: onCancel,
                        icon: Icon(Icons.cancel_outlined,
                            size: 15,
                            color: Colors.red.shade400),
                        label: Text('Cancel Appt.',
                            style: TextStyle(
                                color: Colors.red.shade400, fontSize: 12)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                        ),
                      ),
                  ],
                ),
              ),
            if (onCancel == null && onDelete == null)
              const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip(
      {required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      );
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.06)
            : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
    );
  }
}

class _EmptyAppt extends StatelessWidget {
  const _EmptyAppt({required this.title, required this.subtitle});
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) {
    final navy = const Color(0xFF1A3C6E);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: navy.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.event_outlined,
                  size: 48, color: navy.withOpacity(0.4)),
            ),
            const SizedBox(height: 20),
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color:
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
