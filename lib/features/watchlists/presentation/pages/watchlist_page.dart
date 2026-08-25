import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/watchlist.dart';
import '../cubit/watchlist_cubit.dart';
import '../widgets/watchlist_dialogs.dart';
import 'watchlist_body.dart';

/// Top-level watchlist screen:
/// - Tab bar with one tab per watchlist + a "+" button to create new ones
/// - Long-press on a tab to rename or delete
/// - Body switches to the selected watchlist
class WatchlistPage extends StatelessWidget {
  const WatchlistPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WatchlistCubit, WatchlistState>(
      builder: (context, state) {
        if (state.watchlists.isEmpty) {
          return const _LoadingPlaceholder();
        }

        return DefaultTabController(
          length: state.watchlists.length,
          initialIndex: state.selectedIndex,
          child: _WatchlistTabView(
            watchlists: state.watchlists,
            selectedIndex: state.selectedIndex,
          ),
        );
      },
    );
  }
}

class _WatchlistTabView extends StatefulWidget {
  const _WatchlistTabView({
    required this.watchlists,
    required this.selectedIndex,
  });

  final List<Watchlist> watchlists;
  final int selectedIndex;

  @override
  State<_WatchlistTabView> createState() => _WatchlistTabViewState();
}

class _WatchlistTabViewState extends State<_WatchlistTabView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.watchlists.length,
      vsync: this,
      initialIndex: widget.selectedIndex,
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        context.read<WatchlistCubit>().selectWatchlist(_tabController.index);
      }
    });
  }

  @override
  void didUpdateWidget(covariant _WatchlistTabView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.watchlists.length != widget.watchlists.length) {
      final newController = TabController(
        length: widget.watchlists.length,
        vsync: this,
        initialIndex: widget.selectedIndex.clamp(
          0,
          widget.watchlists.length - 1,
        ),
      );
      newController.addListener(() {
        if (!newController.indexIsChanging) {
          context.read<WatchlistCubit>().selectWatchlist(newController.index);
        }
      });
      _tabController.dispose();
      _tabController = newController;
    } else if (widget.selectedIndex != _tabController.index) {
      _tabController.animateTo(widget.selectedIndex);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<WatchlistCubit>();
    final canDelete = widget.watchlists.length > 1;

    return Column(
      children: [
        // Tab bar + "+" button
        Container(
          color: Theme.of(context).colorScheme.surface,
          child: Row(
            children: [
              Expanded(
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  tabs: widget.watchlists.map((w) {
                    return GestureDetector(
                      onLongPress: () => _showTabOptions(context, w, canDelete),
                      child: Tab(text: w.name),
                    );
                  }).toList(),
                ),
              ),
              // "+" add watchlist button
              IconButton(
                tooltip: 'New Watchlist',
                icon: const Icon(Icons.add),
                onPressed: () async {
                  final name = await showCreateWatchlistDialog(context);
                  if (name != null && context.mounted) {
                    await cubit.createWatchlist(name);
                    // Animate to newly created tab
                    _tabController.animateTo(widget.watchlists.length);
                  }
                },
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Body
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: widget.watchlists
                .map((w) => WatchlistBody(watchlist: w))
                .toList(),
          ),
        ),
      ],
    );
  }

  Future<void> _showTabOptions(
    BuildContext context,
    Watchlist watchlist,
    bool canDelete,
  ) async {
    final cubit = context.read<WatchlistCubit>();
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Rename'),
              onTap: () async {
                Navigator.of(sheetContext).pop();
                final name = await showRenameWatchlistDialog(
                  context,
                  watchlist.name,
                );
                if (name != null && context.mounted) {
                  await cubit.renameWatchlist(watchlist.id, name);
                }
              },
            ),
            if (canDelete)
              ListTile(
                leading: Icon(
                  Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  'Delete',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  final confirmed = await showDeleteWatchlistConfirmation(
                    context,
                    watchlist.name,
                  );
                  if (confirmed && context.mounted) {
                    await cubit.deleteWatchlist(watchlist.id);
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _LoadingPlaceholder extends StatelessWidget {
  const _LoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}
