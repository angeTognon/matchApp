import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:amical_club/screens/home/home_screen.dart';
import 'package:amical_club/screens/search/search_screen.dart';
import 'package:amical_club/screens/create/create_match_screen.dart';
import 'package:amical_club/screens/chat/conversations_screen.dart';
import 'package:amical_club/screens/profile/profile_screen.dart';
import 'package:amical_club/providers/chat_provider.dart';
import 'package:amical_club/providers/auth_provider.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  bool _hasLoadedConversations = false;
 
  final List<Widget> _screens = [
    const HomeScreen(),
    const SearchScreen(),
    const CreateMatchScreen(),
    const ConversationsScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Charger les conversations après le premier build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadConversationsIfNeeded();
    });
  }

  void _loadConversationsIfNeeded() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    
    if (authProvider.isAuthenticated && authProvider.token != null && !_hasLoadedConversations) {
      _hasLoadedConversations = true;
      chatProvider.loadConversations(authProvider);
      chatProvider.startConversationUpdates(authProvider);
      
      // Initialiser les notifications
      chatProvider.initializeNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Écouter les changements d'authentification
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadConversationsIfNeeded();
    });

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          return BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() => _currentIndex = index);
              // Si on clique sur Messages, s'assurer que les conversations sont chargées
              if (index == 3) { // Index de l'onglet Messages
                _loadConversationsIfNeeded();
              }
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: const Color(0xFF1E1E1E),
            selectedItemColor: const Color(0xFF003366),
            unselectedItemColor: const Color(0xFFCCCCCC),
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Accueil',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.search_outlined),
                activeIcon: Icon(Icons.search),
                label: 'Recherche',
              ),
              const BottomNavigationBarItem(
                icon: CircleAvatar(
                  radius: 16,
                  backgroundColor: Color(0xFF003366),
                  child: Icon(Icons.add, color: Colors.white, size: 20),
                ),
                label: 'Créer',
              ),
              BottomNavigationBarItem(
                icon: _buildMessageIcon(chatProvider.unreadCount, false),
                activeIcon: _buildMessageIcon(chatProvider.unreadCount, true),
                label: 'Messages',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profil',
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMessageIcon(int unreadCount, bool isActive) {
    return Stack(
      children: [
        Icon(
          isActive ? Icons.chat_bubble : Icons.chat_bubble_outline,
          color: isActive ? const Color(0xFF003366) : const Color(0xFFCCCCCC),
        ),
        if (unreadCount > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF1E1E1E), width: 1),
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                unreadCount > 99 ? '99+' : unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}