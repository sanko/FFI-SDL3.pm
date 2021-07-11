package SDL2::CommonEvent {
    use SDL2::Utils;
    has
        type      => 'uint32',
        timestamp => 'uint32';

=encoding utf-8

=head1 NAME

SDL2::CommonEvent - Structure with fields shared by every event

=head1 SYNOPSIS

    use SDL2 qw[:all];
    # TODO: I need to whip up a quick example

=head1 DESCRIPTION
 

=head1 Fields

=over

=item C<type>

=item C<timestamp> - In milliseconds, populated using L<< C<SDL_GetTicks( )>|SDL2::FFI/C<SDL_GetTicks( )> >>

=back

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords


=end stopwords

=cut

};
1;
