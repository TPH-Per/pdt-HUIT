import 'package:flutter_bloc/flutter_bloc.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc() : super(const ProfileInitial()) {
    on<FetchProfileEvent>(_onFetchProfile);
    on<ProfileUpdatedEvent>(_onProfileUpdated);
  }

  Future<void> _onFetchProfile(
      FetchProfileEvent event, Emitter<ProfileState> emit) async {
    emit(const ProfileLoading());
    try {
      final profile = ProfileData(
        studentId: '',
        fullName: '',
        email: '',
        phone: '',
      );
      emit(ProfileLoaded(profile: profile));
    } catch (e) {
      emit(ProfileError(message: e.toString()));
    }
  }

  Future<void> _onProfileUpdated(
      ProfileUpdatedEvent event, Emitter<ProfileState> emit) async {
    try {
      if (state is ProfileLoaded) {
        final current = (state as ProfileLoaded).profile;
        final updated = ProfileData(
          studentId: current.studentId,
          fullName: current.fullName,
          email: event.email,
          phone: event.phone,
          faculty: current.faculty,
          className: current.className,
        );
        emit(ProfileLoaded(profile: updated));
      }
    } catch (e) {
      emit(ProfileError(message: e.toString()));
    }
  }
}
