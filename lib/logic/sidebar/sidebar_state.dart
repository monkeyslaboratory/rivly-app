import 'package:equatable/equatable.dart';

class SidebarState extends Equatable {
  final bool isCollapsed;

  const SidebarState({this.isCollapsed = false});

  SidebarState copyWith({bool? isCollapsed}) =>
      SidebarState(isCollapsed: isCollapsed ?? this.isCollapsed);

  @override
  List<Object?> get props => [isCollapsed];
}
