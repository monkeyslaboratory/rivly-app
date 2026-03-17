import 'package:flutter_bloc/flutter_bloc.dart';
import 'sidebar_state.dart';

class SidebarCubit extends Cubit<SidebarState> {
  SidebarCubit() : super(const SidebarState());

  void toggleCollapse() {
    emit(state.copyWith(isCollapsed: !state.isCollapsed));
  }

  void setCollapsed(bool collapsed) {
    if (state.isCollapsed != collapsed) {
      emit(state.copyWith(isCollapsed: collapsed));
    }
  }
}
