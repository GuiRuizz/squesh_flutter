import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

// Modelo de Dados do Usuário no Ranking
class RankingUser {
  final int rank;
  final String name;
  final int points;
  final String avatarUrl;
  final bool isCurrentUser;
  final int streakDays;

  const RankingUser({
    required this.rank,
    required this.name,
    required this.points,
    required this.avatarUrl,
    this.isCurrentUser = false,
    required this.streakDays,
  });
}

// StateNotifier com dados mockados para o Ranking
final rankingFilterProvider = StateProvider<int>(
  (ref) => 0,
); // 0: Semanal, 1: Mensal, 2: Geral

final rankingListProvider = Provider<List<RankingUser>>((ref) {
  return const [
    RankingUser(
      rank: 1,
      name: 'Lucas "Blade"',
      points: 3450,
      avatarUrl: 'https://i.pravatar.cc/150?img=11',
      streakDays: 14,
    ),
    RankingUser(
      rank: 2,
      name: 'Beatriz Silva',
      points: 3120,
      avatarUrl: 'https://i.pravatar.cc/150?img=5',
      streakDays: 21,
    ),
    RankingUser(
      rank: 3,
      name: 'Guilherme Sassi',
      points: 2980,
      avatarUrl: 'https://i.pravatar.cc/150?img=12',
      streakDays: 9,
    ),
    RankingUser(
      rank: 4,
      name: 'Marcos Vinicius',
      points: 2400,
      avatarUrl: 'https://i.pravatar.cc/150?img=3',
      streakDays: 5,
    ),
    RankingUser(
      rank: 5,
      name: 'Você (Squesher)',
      points: 2150,
      avatarUrl: 'https://i.pravatar.cc/150?img=68',
      isCurrentUser: true,
      streakDays: 7,
    ),
    RankingUser(
      rank: 6,
      name: 'Camila Rocha',
      points: 1980,
      avatarUrl: 'https://i.pravatar.cc/150?img=9',
      streakDays: 4,
    ),
    RankingUser(
      rank: 7,
      name: 'Rafael Costa',
      points: 1750,
      avatarUrl: 'https://i.pravatar.cc/150?img=15',
      streakDays: 2,
    ),
    RankingUser(
      rank: 8,
      name: 'Fernanda Lima',
      points: 1420,
      avatarUrl: 'https://i.pravatar.cc/150?img=20',
      streakDays: 1,
    ),
  ];
});

class RankingScreen extends ConsumerWidget {
  const RankingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(rankingListProvider);
    final selectedFilter = ref.watch(rankingFilterProvider);

    final currentUser = users.firstWhere((u) => u.isCurrentUser);
    final rivalUser = users.firstWhere((u) => u.rank == currentUser.rank - 1);

    final top3 = users.sublist(0, 3);
    final otherUsers = users.sublist(3);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF141414),
        elevation: 0,
        title: const Text(
          'ARENA DE LIGAS',
          style: TextStyle(
            color: Color(0xFFFF1E40),
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
      ),
      body: CustomScrollView(
        slivers: [
          // 1. Selector de Período (Semanal / Mensal / Geral)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: _PeriodSelector(
                selectedIndex: selectedFilter,
                onSelected: (index) {
                  ref.read(rankingFilterProvider.notifier).state = index;
                },
              ),
            ),
          ),

          // 2. Rival Card: Foco na ultrapassagem direta
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _RivalChallengeCard(
                currentUser: currentUser,
                rivalUser: rivalUser,
              ),
            ),
          ),

          // 3. Pódio do TOP 3
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: _Top3Podium(top3: top3),
            ),
          ),

          // 4. Lista do restante da liga com identificador visual de Zona
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final user = otherUsers[index];
              return _RankingListItem(user: user);
            }, childCount: otherUsers.length),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
      ),
    );
  }
}

// Segmented Control de Período
class _PeriodSelector extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _PeriodSelector({
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final options = ['Semanal', 'Mensal', 'Geral'];

    return Container(
      height: 42,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Row(
        children: List.generate(options.length, (index) {
          final isSelected = selectedIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelected(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFFF1E40)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                alignment: Alignment.center,
                child: Text(
                  options[index],
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF888888),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// Card de Batalha Direta com o Rival
class _RivalChallengeCard extends StatelessWidget {
  final RankingUser currentUser;
  final RankingUser rivalUser;

  const _RivalChallengeCard({
    required this.currentUser,
    required this.rivalUser,
  });

  @override
  Widget build(BuildContext context) {
    final pointsDifference = rivalUser.points - currentUser.points;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFF1E40).withValues(alpha: 0.15),
            const Color(0xFF181818),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFF1E40).withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.flash_on_rounded,
            color: Color(0xFFFF1E40),
            size: 30,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ALVO PRÓXIMO',
                  style: TextStyle(
                    color: Color(0xFFFF1E40),
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Faltam $pointsDifference PTS para ultrapassar ${rivalUser.name}!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFF1E40),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '#4 LUGAR',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Widget do Pódio do TOP 3
class _Top3Podium extends StatelessWidget {
  final List<RankingUser> top3;

  const _Top3Podium({required this.top3});

  @override
  Widget build(BuildContext context) {
    final first = top3[0];
    final second = top3[1];
    final third = top3[2];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 2º Lugar
        _PodiumCard(
          user: second,
          badgeColor: const Color(0xFFC0C0C0), // Prata
          height: 130,
          rankLabel: '2º',
        ),
        const SizedBox(width: 12),
        // 1º Lugar (Mais alto)
        _PodiumCard(
          user: first,
          badgeColor: const Color(0xFFFFC107), // Ouro
          height: 160,
          rankLabel: '1º',
          isGold: true,
        ),
        const SizedBox(width: 12),
        // 3º Lugar
        _PodiumCard(
          user: third,
          badgeColor: const Color(0xFFCD7F32), // Bronze
          height: 110,
          rankLabel: '3º',
        ),
      ],
    );
  }
}

class _PodiumCard extends StatelessWidget {
  final RankingUser user;
  final Color badgeColor;
  final double height;
  final String rankLabel;
  final bool isGold;

  const _PodiumCard({
    required this.user,
    required this.badgeColor,
    required this.height,
    required this.rankLabel,
    this.isGold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Avatar com Coroa/Glow
        Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: badgeColor, width: isGold ? 3 : 2),
                boxShadow: isGold
                    ? [
                        BoxShadow(
                          color: badgeColor.withValues(alpha: 0.4),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ]
                    : [],
              ),
              child: CircleAvatar(
                radius: isGold ? 30 : 24,
                backgroundImage: NetworkImage(user.avatarUrl),
              ),
            ),
            Positioned(
              top: -14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  rankLabel,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          user.name.split(' ')[0],
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          '${user.points} pts',
          style: TextStyle(
            color: badgeColor,
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 8),
        // Pilar do Pódio
        Container(
          width: 85,
          height: height - 60,
          decoration: BoxDecoration(
            color: const Color(0xFF161616),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            border: Border.all(color: const Color(0xFF262626)),
          ),
          child: Center(
            child: Icon(
              Icons.emoji_events_rounded,
              color: badgeColor.withValues(alpha: 0.3),
              size: 28,
            ),
          ),
        ),
      ],
    );
  }
}

// Item da Lista de Posições
class _RankingListItem extends StatelessWidget {
  final RankingUser user;

  const _RankingListItem({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: user.isCurrentUser
            ? const Color(0xFFFF1E40).withValues(alpha: 0.12)
            : const Color(0xFF141414),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: user.isCurrentUser
              ? const Color(0xFFFF1E40)
              : const Color(0xFF222222),
          width: user.isCurrentUser ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          // Posição
          SizedBox(
            width: 28,
            child: Text(
              '#${user.rank}',
              style: TextStyle(
                color: user.isCurrentUser
                    ? const Color(0xFFFF1E40)
                    : const Color(0xFF666666),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundImage: NetworkImage(user.avatarUrl),
          ),
          const SizedBox(width: 12),

          // Nome e Ofensiva
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: TextStyle(
                    color: user.isCurrentUser
                        ? Colors.white
                        : const Color(0xFFDDDDDD),
                    fontWeight: user.isCurrentUser
                        ? FontWeight.bold
                        : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.local_fire_department_rounded,
                      color: Color(0xFFFF1E40),
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${user.streakDays} dias de streak',
                      style: const TextStyle(
                        color: Color(0xFF666666),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Pontuação
          Text(
            '${user.points} XP',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
