import 'dart:math';
import 'package:flutter/material.dart';
import 'package:digital_khata/controller/language_controller.dart';
import 'package:digital_khata/helper/helper_function.dart';
import 'package:digital_khata/l10n/app_localizations.dart';
import 'package:digital_khata/screens/content/transaction/add_due_amount_screen.dart';
import 'package:digital_khata/services/services.dart';

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final AuthService _authService = AuthService();
  String searchQuery = '';

  Map<String, double> _cachedTotals = {};
  bool _isLoadingTotals = true;

  @override
  void initState() {
    super.initState();
    _loadTotals();
  }

  Future<void> _loadTotals() async {
    try {
      final totals = await _databaseService.getAllPeopleWithTotals();
      if (mounted) {
        setState(() {
          _cachedTotals = totals;
          _isLoadingTotals = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingTotals = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
        child: Column(
          children: [
            // Top Header Bar with Profile Avatar, Language Switcher & Logout
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).colorScheme.tertiary,
                                Theme.of(context).colorScheme.secondary,
                                Theme.of(context).colorScheme.primary,
                              ],
                              transform: const GradientRotation(pi / 4),
                            ),
                          ),
                        ),
                        const Icon(Icons.person, color: Colors.white),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Welcome,",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                          Text(
                            _authService.currentUser?.email ?? "User",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                // Right Side Actions (Language Popup + Logout)
                Row(
                  children: [
                    PopupMenuButton<Locale>(
                      icon: Icon(
                        Icons.language,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      tooltip: 'Change Language',
                      onSelected: (Locale locale) {
                        LanguageController.changeLanguage(locale);
                      },
                      itemBuilder: (BuildContext context) => <PopupMenuEntry<Locale>>[
                        const PopupMenuItem<Locale>(
                          value: Locale('en'),
                          child: Row(
                            children: [
                              Text('🇬🇧 '),
                              SizedBox(width: 8),
                              Text('English'),
                            ],
                          ),
                        ),
                        const PopupMenuItem<Locale>(
                          value: Locale('ur'),
                          child: Row(
                            children: [
                              Text('🇵🇰 '),
                              SizedBox(width: 8),
                              Text('اردو (Urdu)'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () {
                        logout(context);
                      },
                      icon: const Icon(Icons.logout_outlined),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Main Total Due Card (Restored Original Emerald/Teal Gradient Theme)
            if (searchQuery.isEmpty)
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: _databaseService.peopleStream,
                builder: (context, peopleSnapshot) {
                  if (peopleSnapshot.connectionState == ConnectionState.waiting &&
                      !peopleSnapshot.hasData) {
                    return const SizedBox(
                      height: 180,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final people = peopleSnapshot.data ?? [];

                  double totalDue = 0;
                  double lowestDue = double.infinity;
                  double highestDue = 0;
                  String lowestPerson = '';
                  String highestPerson = '';

                  for (var person in people) {
                    final name = person['name'] ?? '';
                    final personId = person['id']?.toString() ?? '';
                    final personTotal = _cachedTotals[personId] ?? 0.0;

                    totalDue += personTotal;

                    if (personTotal < lowestDue) {
                      lowestDue = personTotal;
                      lowestPerson = name;
                    }

                    if (personTotal > highestDue) {
                      highestDue = personTotal;
                      highestPerson = name;
                    }
                  }

                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.tertiary,
                          Theme.of(context).colorScheme.secondary,
                          Theme.of(context).colorScheme.primary,
                        ],
                        transform: const GradientRotation(pi / 4),
                      ),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade400,
                          blurRadius: 5,
                          offset: const Offset(5, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          l10n.totalBalance,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "Rs. ${totalDue.toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontSize: 36,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Lowest Due",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                Text(
                                  "Rs. ${lowestDue == double.infinity ? 0.0 : lowestDue.toStringAsFixed(2)}",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  lowestPerson,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  "Highest Due",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                Text(
                                  "Rs. ${highestDue.toStringAsFixed(2)}",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  highestPerson,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),

            const SizedBox(height: 20),

            // Quick Actions Horizontal Navigation (Matches your original button theme)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pushNamed(context, '/analytics_screen'),
                    icon: const Icon(Icons.analytics, color: Colors.white),
                    label: Text(
                      l10n.analytics,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pushNamed(context, '/expense_screen'),
                    icon: const Icon(Icons.receipt_long, color: Colors.white),
                    label: Text(
                      l10n.expenses,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      backgroundColor: Theme.of(context).colorScheme.tertiary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pushNamed(context, '/suppliers'),
                    icon: const Icon(Icons.business, color: Colors.white),
                    label: Text(
                      l10n.suppliers,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pushNamed(context, '/accounts'),
                    icon: const Icon(Icons.account_balance, color: Colors.white),
                    label: Text(
                      l10n.accounts,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Header Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.people,
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/list_people_screen'),
                  child: Text(
                    "View All ▼",
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.outline,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Search Bar
            TextField(
              decoration: InputDecoration(
                hintText: l10n.search,
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade200,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
            ),
            const SizedBox(height: 12),

            // People List View
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _databaseService.peopleStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final people = snapshot.data ?? [];

                  final filteredPeople = people.where((person) {
                    final name = person['name']?.toString().toLowerCase() ?? '';
                    final uniqueId =
                        person['unique_id']?.toString().toLowerCase() ?? '';
                    return name.contains(searchQuery) ||
                        uniqueId.contains(searchQuery);
                  }).toList();

                  if (filteredPeople.isEmpty) {
                    return Center(
                      child: Text(l10n.noResults),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredPeople.length,
                    itemBuilder: (context, index) {
                      final data = filteredPeople[index];
                      final personId = data['id']?.toString() ?? '';
                      final name = data['name'] ?? '';
                      final uniqueId = data['unique_id'] ?? '';
                      final totalDue = _cachedTotals[personId] ?? 0.0;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          leading: CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.primaries[
                                (name.isNotEmpty ? name.codeUnitAt(0) : 0) %
                                    Colors.primaries.length],
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ),
                          title: Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            'ID: $uniqueId',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          trailing: Text(
                            'Rs. ${totalDue.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: totalDue > 0 ? Colors.red : Colors.green,
                              fontSize: 16,
                            ),
                          ),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddDueAmountScreen(
                                  personId: personId,
                                  personName: name,
                                ),
                              ),
                            );
                            _loadTotals();
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}