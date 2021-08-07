package SDL2::Joystick {
    use SDL2::Utils;
    ffi->type( 'sint32' => 'SDL_JoystickID' );
    has();

=encoding utf-8

=head1 NAME

SDL2::JoystickGUID - Structure use to identify an SDL joystick

=head1 SYNOPSIS

    use SDL2 qw[:all];
    # TODO: I need to whip up a quick example

=head1 DESCRIPTION


=head1 Fields

=over

=item C<data>

=back

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords


=end stopwords

=cut

};
1;
