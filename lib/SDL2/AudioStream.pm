package SDL2::AudioStream {
    use SDL2::Utils;
    has();

=encoding utf-8

=head1 NAME

SDL2::AudioStream - A new audio conversion interface

=head1 SYNOPSIS

    use SDL2 qw[:all];

=head1 DESCRIPTION

The benefits of L<SDL2::AudioStream> vs L<SDL2::AudioCVT>:

=over

=item - it can handle resampling data in chunks without generating artifacts, when it doesn't have the complete buffer available

=item - it can handle incoming data in any variable size

=item - You push data as you have it, and pull it when you need it

=back

=head1 Fields

=over

=item C<value>

=back


=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords

vs

=end stopwords

=cut

};
1
