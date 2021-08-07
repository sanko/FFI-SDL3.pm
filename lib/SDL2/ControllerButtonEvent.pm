package SDL2::ControllerButtonEvent {
    use SDL2::Utils;
    has
        type      => 'uint32',
        timestamp => 'uint32',
        which     => 'SDL_JoystickID',
        button    => 'uint8',
        state     => 'uint8',
        padding1  => 'uint8',
        padding2  => 'uint8';

=encoding utf-8

=head1 NAME

SDL2::ControllerButtonEvent - Game controller button event structure

=head1 SYNOPSIS

    use SDL2 qw[:all];
    # TODO: I need to whip up a quick example

=head1 DESCRIPTION


=head1 Fields

=over

=item C<type> - C<SDL_CONTROLLERBUTTONDOWN> or C<SDL_CONTROLLERBUTTONUP>

=item C<timestamp> - In milliseconds, populated using L<< C<SDL_GetTicks( )>|SDL2::FFI/C<SDL_GetTicks( )> >>

=item C<which> - The joystick instance id

=item C<button> - The controller button

=item C<state> - C<SDL_PRESSED> or C<SDL_RELEASED>

=item C<padding1>

=item C<padding2>

=back

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords


=end stopwords

=cut

};
1;
