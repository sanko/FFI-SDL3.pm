package SDL2::AudioDeviceEvent {
    use SDL2::Utils;
    has
        type      => 'uint32',
        timestamp => 'uint32',
        which     => 'uint32',
        iscapture => 'uint8',
        padding1  => 'uint8',
        padding2  => 'uint8',
        padding3  => 'uint8';

=encoding utf-8

=head1 NAME

SDL2::AudioDeviceEvent - Audio device event structure

=head1 SYNOPSIS

    use SDL2 qw[:all];
    # TODO: I need to whip up a quick example

=head1 DESCRIPTION
 

=head1 Fields

=over

=item C<type> - C<SDL_AUDIODEVICEADDED> or C<SDL_AUDIODEVICEREMOVED>

=item C<timestamp> - In milliseconds, populated using L<< C<SDL_GetTicks( )>|SDL2::FFI/C<SDL_GetTicks( )> >>

=item C<which> - The audio device index for the C<ADDED> event (valid until next L<< C<SDL_GetNumAudioDevices( )>|SDL2::FFI/C<SDL_GetNumAudioDevices( )> >> call), C<SDL_AudioDeviceID> for the C<REMOVED> event

=item C<iscapture> - zero if an output device, non-zero if a capture device

=item C<padding1>

=item C<padding2>

=item C<padding3>

=back

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords


=end stopwords

=cut

};
1;