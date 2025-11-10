import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:amical_club/providers/auth_provider.dart';
import 'package:amical_club/services/api_service.dart';
import 'package:amical_club/models/match_request.dart';
import 'package:amical_club/config/app_theme.dart';

class MatchRequestsScreen extends StatefulWidget {
  const MatchRequestsScreen({super.key});

  @override
  State<MatchRequestsScreen> createState() => _MatchRequestsScreenState();
}

class _MatchRequestsScreenState extends State<MatchRequestsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<MatchRequest> _receivedRequests = [];
  List<MatchRequest> _sentRequests = [];
  bool _isLoadingReceived = true;
  bool _isLoadingSent = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRequests() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.token == null) return;

    setState(() {
      _isLoadingReceived = true;
      _isLoadingSent = true;
      _errorMessage = null;
    });

    // Charger les demandes reçues
    try {
      final receivedResponse = await ApiService.getMatchRequests(
        token: authProvider.token!,
        type: 'received',
      );

      if (mounted) {
        if (receivedResponse['success']) {
          final requests = receivedResponse['data']['requests'] as List<dynamic>;
          setState(() {
            _receivedRequests = requests
                .map((json) => MatchRequest.fromJson(json, isReceived: true))
                .toList();
            _isLoadingReceived = false;
          });
        } else {
          setState(() {
            _errorMessage = receivedResponse['message'];
            _isLoadingReceived = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur: $e';
          _isLoadingReceived = false;
        });
      }
    }

    // Charger les demandes envoyées
    try {
      final sentResponse = await ApiService.getMatchRequests(
        token: authProvider.token!,
        type: 'sent',
      );

      if (mounted) {
        if (sentResponse['success']) {
          final requests = sentResponse['data']['requests'] as List<dynamic>;
          setState(() {
            _sentRequests = requests
                .map((json) => MatchRequest.fromJson(json, isReceived: false))
                .toList();
            _isLoadingSent = false;
          });
        } else {
          setState(() {
            _errorMessage = sentResponse['message'];
            _isLoadingSent = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur: $e';
          _isLoadingSent = false;
        });
      }
    }
  }

  Future<void> _respondToRequest(String requestId, String action) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.token == null) return;

    try {
      final response = await ApiService.respondToMatchRequest(
        token: authProvider.token!,
        requestId: requestId,
        action: action,
      );

      if (mounted) {
        if (response['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message']),
              backgroundColor: Colors.green,
            ),
          );
          _loadRequests(); // Recharger les demandes
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message']),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Demandes de match'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Reçues'),
                  if (_receivedRequests.where((r) => r.requestStatus == 'pending').isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_receivedRequests.where((r) => r.requestStatus == 'pending').length}',
                        style: const TextStyle(fontSize: 12, color: Colors.white),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'Envoyées'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Demandes reçues
          _buildRequestsList(_receivedRequests, _isLoadingReceived, isReceived: true),
          // Demandes envoyées
          _buildRequestsList(_sentRequests, _isLoadingSent, isReceived: false),
        ],
      ),
    );
  }

  Widget _buildRequestsList(List<MatchRequest> requests, bool isLoading, {required bool isReceived}) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadRequests,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isReceived ? Icons.inbox : Icons.send,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              isReceived 
                  ? 'Aucune demande reçue'
                  : 'Aucune demande envoyée',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              isReceived
                  ? 'Les demandes pour vos matchs apparaîtront ici'
                  : 'Vos demandes de match apparaîtront ici',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRequests,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          return _buildRequestCard(requests[index], isReceived: isReceived);
        },
      ),
    );
  }

  Widget _buildRequestCard(MatchRequest request, {required bool isReceived}) {
    final isPending = request.requestStatus == 'pending';
    final isAccepted = request.requestStatus == 'accepted';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
            // Header avec statut
                      Row(
              children: [
                Expanded(
                  child: Row(
                        children: [
                          CircleAvatar(
                        radius: 20,
                        backgroundImage: request.teamLogo != null
                            ? NetworkImage(request.teamLogo!)
                            : null,
                        child: request.teamLogo == null
                            ? Text(request.teamName[0].toUpperCase())
                            : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                              request.teamName,
                              style: const TextStyle(
                                    fontSize: 16,
                                fontWeight: FontWeight.bold,
                                  ),
                                ),
                            if (request.clubName != null)
                                Text(
                                request.clubName!,
                                  style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isPending
                        ? Colors.orange.withOpacity(0.1)
                        : isAccepted
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    request.statusDisplay,
                                      style: TextStyle(
                                        fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isPending
                          ? Colors.orange
                          : isAccepted
                              ? Colors.green
                              : Colors.red,
                    ),
                                      ),
                                    ),
                                  ],
            ),

            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),

            // Info du match
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  request.formattedDate,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.access_time, size: 16, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  request.formattedTime,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),

            const SizedBox(height: 8),

            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    request.location,
                    style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),

            const SizedBox(height: 8),

            Row(
              children: [
                if (request.category != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      request.category!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
                if (request.level != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      request.level!,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ],
            ),

            // Message de la demande
            if (request.requestMessage != null && request.requestMessage!.isNotEmpty) ...[
              const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                    const Text(
                      'Message:',
                              style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                            Text(
                      request.requestMessage!,
                      style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
              ),
            ],

            // Actions (pour les demandes reçues en attente)
            if (isReceived && isPending) ...[
              const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                      onPressed: () => _showRejectDialog(request.requestId),
                      icon: const Icon(Icons.close, size: 18),
                              label: const Text('Refuser'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                              ),
                            ),
                          ),
                  const SizedBox(width: 12),
                          Expanded(
                    flex: 2,
                            child: ElevatedButton.icon(
                      onPressed: () => _showAcceptDialog(request.requestId),
                      icon: const Icon(Icons.check, size: 18),
                              label: const Text('Accepter'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

            // Info sur la réponse
            if (request.respondedAt != null) ...[
              const SizedBox(height: 12),
                  Text(
                'Répondu le ${_formatDateTime(request.respondedAt!)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
                ],
              ),
            ),
    );
  }

  void _showAcceptDialog(String requestId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accepter la demande'),
        content: const Text(
          'Voulez-vous accepter cette demande de match ? Le match sera confirmé et les autres demandes seront automatiquement refusées.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _respondToRequest(requestId, 'accept');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Accepter'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(String requestId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Refuser la demande'),
        content: const Text('Voulez-vous vraiment refuser cette demande de match ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _respondToRequest(requestId, 'reject');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Refuser'),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return 'aujourd\'hui à ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'hier à ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
