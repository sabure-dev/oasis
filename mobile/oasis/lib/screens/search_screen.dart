import 'package:flutter/material.dart';
import 'package:oasis/models/track.dart';
import 'package:oasis/providers/player_provider.dart';
import 'package:oasis/services/api_service.dart';
import 'package:oasis/widgets/glass_card.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final ApiService _apiService = ApiService();
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  List<Track> _searchResults = [];
  bool _isLoading = false;
  bool _isPaginating = false;
  bool _hasMore = true;
  int _offset = 0;
  String _currentQuery = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        !_isPaginating &&
        _hasMore) {
      _performSearch(_currentQuery, paginate: true);
    }
  }

  void _performSearch(String query, {bool paginate = false}) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _currentQuery = '';
        _offset = 0;
        _hasMore = true;
      });
      return;
    }

    if (paginate) {
      setState(() {
        _isPaginating = true;
      });
    } else {
      setState(() {
        _isLoading = true;
        _searchResults = [];
        _offset = 0;
        _hasMore = true;
        _currentQuery = query;
      });
    }
    final authProvider = context.read<AuthProvider>();
    try {
      // ОБОРАЧИВАЕМ вызов API
      await authProvider.performSafeCall(() async {
        final results =
            await _apiService.search(_currentQuery, offset: _offset);

        // Логика обновления UI должна быть внутри, чтобы выполниться при успешном запросе
        if (mounted) {
          // Всегда проверяйте mounted в асинхронных методах
          setState(() {
            if (results.isNotEmpty) {
              _searchResults.addAll(results);
              _offset += results.length;
            } else {
              _hasMore = false;
            }
          });
        }
      });
    } catch (e) {
      // Сюда попадут ошибки типа "нет интернета".
      // Ошибка "Session expired" НЕ попадет сюда, её обработает performSafeCall.
      print('Search error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isPaginating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(
            right: 20.0,
            left: 20.0,
            top: 20.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'e x p l o r e',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w400),
              ),
              const SizedBox(height: 20),
              GlassCard(
                child: TextField(
                  controller: _searchController,
                  onSubmitted: _performSearch,
                  decoration: const InputDecoration(
                    hintText: 'Artists or songs',
                    hintStyle: TextStyle(color: Colors.white54),
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.search, color: Colors.white70),
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _searchResults.isNotEmpty
                      ? Expanded(
                          child: ListView.builder(
                            controller: _scrollController,
                            itemCount:
                                _searchResults.length + (_isPaginating ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == _searchResults.length) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              }
                              final track = _searchResults[index];
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6.0),
                                child: GlassCard(
                                  child: ListTile(
                                    onTap: () async {
                                      // Делаем callback асинхронным
                                      final player =
                                          Provider.of<PlayerProvider>(context,
                                              listen: false);
                                      final auth = context.read<AuthProvider>();

                                      // Оборачиваем воспроизведение
                                      await auth.performSafeCall(() async {
                                        await player.play(track);
                                      });
                                    },
                                    leading: ClipRRect(
                                      borderRadius: BorderRadius.circular(8.0),
                                      child: Image.network(track.albumCover,
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover),
                                    ),
                                    title: Text(track.title,
                                        style: const TextStyle(
                                            color: Colors.white)),
                                    subtitle: Text(track.artist,
                                        style: const TextStyle(
                                            color: Colors.white70)),
                                    trailing: Text(track.formattedDuration,
                                        style: const TextStyle(
                                            color: Colors.white70)),
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                      : Expanded(
                          child: _buildBrowseAll(),
                        ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBrowseAll() {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 1200
        ? 5
        : screenWidth > 800
            ? 4
            : screenWidth > 600
                ? 3
                : 2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Browse all',
          style: TextStyle(
              color: Colors.white, fontSize: 22, fontWeight: FontWeight.w300),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: GridView.builder(
            itemCount: 8,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 15.0,
              mainAxisSpacing: 15.0,
            ),
            itemBuilder: (context, index) {
              return GlassCard(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.primaries[index % Colors.primaries.length]
                        .withValues(alpha: 0.5),
                  ),
                  child: const Center(
                    child: Text(
                      'Pop',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
