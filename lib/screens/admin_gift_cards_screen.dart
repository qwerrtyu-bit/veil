import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/gift_card_request.dart';
import '../services/gift_card_request_service.dart';
import '../services/admin_service.dart';
import '../l10n/app_localizations.dart';

class AdminGiftCardsScreen extends ConsumerStatefulWidget {
  const AdminGiftCardsScreen({super.key});

  @override
  ConsumerState<AdminGiftCardsScreen> createState() => _AdminGiftCardsScreenState();
}

class _AdminGiftCardsScreenState extends ConsumerState<AdminGiftCardsScreen> {
  final _giftService = GiftCardRequestService();
  List<GiftCardRequest> _requests = [];
  List<GiftCardRequest> _cards = [];
  bool _isLoading = true;
  bool _isAdmin = false;
  String _filter = 'all'; // all, pending, approved, completed

  @override
  void initState() {
    super.initState();
    _checkAdmin();
  }

  Future<void> _checkAdmin() async {
    final adminService = AdminService();
    final isAdmin = await adminService.isAdmin();
    if (!isAdmin) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Доступ запрещён'),
            backgroundColor: Colors.red,
          ),
        );
        context.go('/settings');
      }
      return;
    }
    setState(() => _isAdmin = true);
    await _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _requests = _giftService.getAllRequests();
    _cards = _giftService.getAllCards();
    setState(() => _isLoading = false);
  }

  List<GiftCardRequest> _getFilteredRequests() {
    if (_filter == 'all') return _requests;
    return _requests.where((r) => r.status == _filter).toList();
  }

  Future<void> _updateStatus(GiftCardRequest request, String newStatus) async {
    String? code;
    if (newStatus == 'approved') {
      code = _giftService.generateCode();
    }

    await _giftService.updateRequestStatus(
      request.id,
      newStatus,
      giftCardCode: code,
      comment: 'Обработано администратором',
    );

    await _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Заявка обновлена: $newStatus'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _deleteRequest(GiftCardRequest request) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить заявку?'),
        content: Text('Заявка от ${request.fullName} будет удалена'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _giftService.deleteRequest(request.id);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Заявка удалена'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createGiftCard() async {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    final keyController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Создать подарочную карту'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                hintText: 'Имя получателя',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Сумма (VLC)',
                suffixText: 'VLC',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: keyController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Публичный ключ (опционально)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final amount = double.tryParse(amountController.text.trim());
              if (name.isEmpty || amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Заполните все поля'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final card = await _giftService.createGiftCard(
                recipientName: name,
                recipientKey: keyController.text.trim(),
                amount: amount,
                accountNumber: 'VEIL-${DateTime.now().millisecondsSinceEpoch}',
              );

              Navigator.pop(ctx);
              await _loadData();

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Карта создана! Код: ${card.giftCardCode}'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Создать'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'На проверке';
      case 'approved':
        return 'Одобрена';
      case 'completed':
        return 'Активирована';
      case 'rejected':
        return 'Отклонена';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _getFilteredRequests();

    if (!_isAdmin) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Управление подарочными картами'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/settings'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createGiftCard,
            tooltip: 'Создать карту',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Обновить',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Фильтры
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('Все', 'all'),
                        const SizedBox(width: 8),
                        _buildFilterChip('На проверке', 'pending'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Одобрены', 'approved'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Активированы', 'completed'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Отклонены', 'rejected'),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1),
                // Статистика
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Всего: ${_requests.length} заявок, ${_cards.length} карт',
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      if (_cards.isNotEmpty)
                        Text(
                          'Сумма: ${_cards.fold(0.0, (sum, c) => sum + c.amount).toStringAsFixed(2)} VLC',
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Список
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.card_giftcard,
                                size: 64,
                                color: theme.colorScheme.onSurface.withOpacity(0.2),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Нет заявок',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final request = filtered[index];
                            return _buildRequestCard(request, theme);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filter = value;
        });
      },
      backgroundColor: Theme.of(context).colorScheme.surface,
      selectedColor: const Color(0xFF6C5CE7).withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF6C5CE7) : null,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildRequestCard(GiftCardRequest request, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final statusColor = _getStatusColor(request.status);

    return Card(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getStatusIcon(request.status),
            color: statusColor,
          ),
        ),
        title: Text(
          request.fullName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${request.amount.toStringAsFixed(2)} VLC · ${_getStatusLabel(request.status)}',
              style: TextStyle(
                fontSize: 13,
                color: statusColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              _formatDate(request.createdAt),
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Дата рождения', request.dateOfBirth),
                _buildInfoRow('Публичный ключ', request.publicKey.substring(0, 16) + '...'),
                if (request.giftCardCode != null)
                  _buildInfoRow('Код карты', request.giftCardCode!, isCode: true),
                if (request.comment != null)
                  _buildInfoRow('Комментарий', request.comment!),
                const SizedBox(height: 12),
                if (request.status == 'pending')
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _updateStatus(request, 'approved'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                          ),
                          child: const Text('Одобрить'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _updateStatus(request, 'rejected'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Text('Отклонить'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteRequest(request),
                      ),
                    ],
                  ),
                if (request.status == 'approved')
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _updateStatus(request, 'completed'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          child: const Text('Активировать'),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isCode = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontFamily: isCode ? 'SpaceMono' : null,
                color: isCode ? const Color(0xFF6C5CE7) : null,
                fontWeight: isCode ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'approved':
        return Icons.check_circle_outline;
      case 'completed':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}