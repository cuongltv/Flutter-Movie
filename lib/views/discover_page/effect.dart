import 'package:fish_redux/fish_redux.dart';
import 'package:flutter/material.dart' hide Action;
import 'package:movie/actions/apihelper.dart';
import 'package:movie/models/videolist.dart';
import 'action.dart';
import 'state.dart';

Effect<DiscoverPageState> buildEffect() {
  return combineEffects(<Object, Effect<DiscoverPageState>>{
    Lifecycle.initState: _onInit,
    Lifecycle.dispose: _onDispose,
    DiscoverPageAction.action: _onAction,
    DiscoverPageAction.videoCellTapped: _onVideoCellTapped,
    DiscoverPageAction.refreshData: _onLoadData,
    DiscoverPageAction.mediaTypeChange: _mediaTypeChange,
    DiscoverPageAction.filterTap: _filterTap,
  });
}

void _onAction(Action action, Context<DiscoverPageState> ctx) {}

Future _onInit(Action action, Context<DiscoverPageState> ctx) async {
  ctx.state.scrollController = ScrollController();
  ctx.state.filterState.keyWordController = TextEditingController();
  ctx.state.scrollController.addListener(() async {
    bool isBottom = ctx.state.scrollController.position.pixels ==
        ctx.state.scrollController.position.maxScrollExtent;
    if (isBottom) {
      await _onLoadMore(action, ctx);
    }
  });
  await _onLoadData(action, ctx);
}

void _onDispose(Action action, Context<DiscoverPageState> ctx) {
  ctx.state.scrollController.dispose();
  ctx.state.filterState.keyWordController.dispose();
  ctx.state.dropdownMenuController.dispose();
}

Future _onLoadData(Action action, Context<DiscoverPageState> ctx) async {
  ctx.dispatch(DiscoverPageActionCreator.onBusyChanged(true));
  final _genres = ctx.state.filterState.currectGenres;
  var genresIds = _genres.where((e) => e.isSelected).map<int>((e) {
    return e.value;
  }).toList();
  VideoListModel r;
  String _sortBy = ctx.state.filterState.selectedSort == null
      ? null
      : '${ctx.state.filterState.selectedSort.value}${ctx.state.filterState.sortDesc ? '.desc' : '.asc'}';
  if (ctx.state.isMovie)
    r = await ApiHelper.getMovieDiscover(
        withKeywords: ctx.state.filterState.keyWordController.text,
        sortBy: _sortBy,
        withGenres: genresIds.length > 0 ? genresIds.join(',') : null);
  else
    r = await ApiHelper.getTVDiscover(
        withKeywords: ctx.state.filterState.keyWordController.text,
        sortBy: _sortBy,
        withGenres: genresIds.length > 0 ? genresIds.join(',') : null);
  if (r != null) ctx.dispatch(DiscoverPageActionCreator.onLoadData(r));

  ctx.dispatch(DiscoverPageActionCreator.onBusyChanged(false));
}

Future _onVideoCellTapped(Action action, Context<DiscoverPageState> ctx) async {
  if (ctx.state.isMovie)
    await Navigator.of(ctx.context).pushNamed('detailpage',
        arguments: {'id': action.payload[0], 'bgpic': action.payload[1]});
  else
    await Navigator.of(ctx.context).pushNamed('tvdetailpage',
        arguments: {'tvid': action.payload[0], 'bgpic': action.payload[1]});
}

Future _onLoadMore(Action action, Context<DiscoverPageState> ctx) async {
  if (ctx.state.isbusy) return;
  ctx.dispatch(DiscoverPageActionCreator.onBusyChanged(true));
  final _genres = ctx.state.filterState.currectGenres;
  var genresIds = _genres.where((e) => e.isSelected).map<int>((e) {
    return e.value;
  }).toList();
  VideoListModel r;
  String _sortBy =
      '${ctx.state.filterState?.selectedSort?.value ?? ''}${ctx.state.filterState.sortDesc ? '.desc' : '.asc'}';
  if (ctx.state.isMovie)
    r = await ApiHelper.getMovieDiscover(
        page: ctx.state.videoListModel.page + 1,
        sortBy: _sortBy,
        withGenres: genresIds.length > 0 ? genresIds.join(',') : null,
        withKeywords: ctx.state.filterState.keywords);
  else
    r = await ApiHelper.getTVDiscover(
        page: ctx.state.videoListModel.page + 1,
        sortBy: _sortBy,
        withGenres: genresIds.length > 0 ? genresIds.join(',') : null,
        withKeywords: ctx.state.filterState.keywords);
  if (r != null) ctx.dispatch(DiscoverPageActionCreator.onLoadMore(r.results));
  ctx.dispatch(DiscoverPageActionCreator.onBusyChanged(false));
}

Future _mediaTypeChange(Action action, Context<DiscoverPageState> ctx) async {
  final bool _isMovie = action.payload ?? true;
  if (ctx.state.isMovie == _isMovie) return;
  ctx.state.isMovie = _isMovie;
  await _onLoadData(action, ctx);
  ctx.state.scrollController.jumpTo(0);
}

void _filterTap(Action action, Context<DiscoverPageState> ctx) async {
  ctx.state.filterState.isMovie = ctx.state.isMovie;
  Navigator.of(ctx.context)
      .push(PageRouteBuilder(pageBuilder: (_, animation, ___) {
    return SlideTransition(
        position: Tween<Offset>(begin: Offset(0, 1), end: Offset.zero)
            .animate(CurvedAnimation(parent: animation, curve: Curves.ease)),
        child: FadeTransition(
            opacity: animation, child: ctx.buildComponent('filter')));
  }));
}
