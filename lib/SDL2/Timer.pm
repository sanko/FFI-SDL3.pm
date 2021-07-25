package SDL2::Timer {
    use Moo;
    use Types::Standard qw[Any Int InstanceOf];
    has id   => ( is => 'rw', isa => Int, requried => 0 );
    has cb   => ( is => 'rw', isa => InstanceOf ['FFI::Platypus::Closure'], required => 0 );
    has args => ( is => 'rw', isa => Any, predicate => 1 );

    sub DEMOLISH {
        my ( $s, $in_global_destruction ) = @_;
        SDL2::FFI::SDL_RemoveTimer( $s->id );
    }
};
1;
