import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';

import '../../utils/app_colors.dart';

@RoutePage()
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  int _selectedTimeIndex = 0;
  int _selectedTabIndex = 0;
  final List<String> _timePeriods = ['30 days', '6 Months', '1 Year', 'Lifetime'];
  final List<String> _tabs = ['Tracks', 'Artists', 'Albums'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.transparent,
        elevation: 0,
        title: const Text(
          'Your Listening Stats',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.text),
          onPressed: () => context.router.maybePop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTabs(),
            const SizedBox(height: 20),
            Expanded(
              child: _buildTrackList(),
            ),
            _buildTimePeriodSelector(),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          _tabs.length,
          (index) => GestureDetector(
            onTap: () {
              setState(() {
                _selectedTabIndex = index;
              });
            },
            child: Column(
              children: [
                Text(
                  _tabs[index],
                  style: TextStyle(
                    color: _selectedTabIndex == index 
                        ? Colors.red 
                        : Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                if (_selectedTabIndex == index)
                  Container(
                    height: 3,
                    width: 80,
                    color: Colors.red,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrackList() {
    // Sample track data
    final List<Map<String, dynamic>> tracks = [
      {
        'rank': 1,
        'image': 'assets/images/chase_atlantic.jpg',
        'title': 'Swim',
        'artist': 'Chase Atlantic',
      },
      {
        'rank': 2,
        'image': 'assets/images/nf.jpg',
        'title': 'Time',
        'artist': 'NF',
      },
      {
        'rank': 3,
        'image': 'assets/images/conan_gray.jpg',
        'title': 'Movies',
        'artist': 'Conan Gray',
      },
      {
        'rank': 4,
        'image': 'assets/images/niki.jpg',
        'title': 'lowkey',
        'artist': 'NIKI',
      },
      {
        'rank': 5,
        'image': 'assets/images/newjeans.jpg',
        'title': 'Hurt',
        'artist': 'NewJeans',
      },
      {
        'rank': 6,
        'image': 'assets/images/aespa.jpg',
        'title': 'ILLUSION',
        'artist': 'aespa',
      },
      {
        'rank': 7,
        'image': 'assets/images/blackpink.jpg',
        'title': 'Pink Venom',
        'artist': 'BLACKPINK',
      },
      {
        'rank': 8,
        'image': 'assets/images/moods.jpg',
        'title': 'moods',
        'artist': 'Moods',
      },
    ];

    return ListView.builder(
      itemCount: tracks.length,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemBuilder: (context, index) {
        final track = tracks[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Text(
                '#${track['rank']}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  track['image'],
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[800],
                    alignment: Alignment.center,
                    child: const Icon(Icons.music_note, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track['title'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      track['artist'],
                      style: TextStyle(
                        color: const Color.fromRGBO(255, 255, 255, 0.6),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimePeriodSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.black,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          _timePeriods.length,
          (index) => GestureDetector(
            onTap: () {
              setState(() {
                _selectedTimeIndex = index;
              });
            },
            child: Column(
              children: [
                Text(
                  _timePeriods[index],
                  style: TextStyle(
                    color: _selectedTimeIndex == index 
                        ? Colors.red 
                        : Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                if (_selectedTimeIndex == index)
                  Container(
                    height: 2,
                    width: 60,
                    color: Colors.red,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


