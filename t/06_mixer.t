use strict;
use warnings;
use Test2::V0;
use Test2::Tools::Class qw[isa_ok can_ok];
use Test2::Tools::Exception qw[try_ok];
use Path::Tiny;
use lib -d '../t' ? './lib' : 't/lib';
use lib '../lib', 'lib';
#
use SDL2::FFI qw[:init :audio SDL_RWFromFile SDL_AddTimer SDL_Delay];
use SDL2::Mixer qw[:all];
#
$|++;
#
my $mp3 = path( ( -d '../t' ? './' : './t/' ) . 'etc/sample.mp3' );
my $wav = path( ( -d '../t' ? './' : './t/' ) . 'etc/sample.wav' );
#
my $compile_version = SDL2::Version->new();
my $link_version    = Mix_Linked_Version();
SDL_MIXER_VERSION($compile_version);
diag sprintf 'compiled with SDL_mixer version: %d.%d.%d', $compile_version->major,
    $compile_version->minor, $compile_version->patch;
diag sprintf 'running with SDL_mixer version: %d.%d.%d', $link_version->major,
    $link_version->minor, $link_version->patch;
is SDL_MIXER_VERSION_ATLEAST( 1, 0, 0 ), 1, 'SDL_MIXER_VERSION_ATLEAST( 1, 0, 0 ) == 1';
is SDL_MIXER_VERSION_ATLEAST( $link_version->major, $link_version->minor, $link_version->patch ), 1,
    sprintf( 'SDL_MIXER_VERSION_ATLEAST( %d, %d, %d ) == 1',
    $link_version->major, $link_version->minor, $link_version->patch );
is SDL_MIXER_VERSION_ATLEAST(
    $link_version->major, $link_version->minor, $link_version->patch + 1
    ),
    !1,
    sprintf( 'SDL_MIXER_VERSION_ATLEAST( %d, %d, %d ) != 1',
    $link_version->major, $link_version->minor, $link_version->patch + 1 );
#
todo 'These are platform specific and might fail depending on how SDL_mixer was built' => sub {
    is Mix_Init(), 0, 'Mix_Init() == 0';
    is Mix_Init(MIX_INIT_MP3),  MIX_INIT_MP3,  'Mix_Init( MIX_INIT_MP3 ) == MIX_INIT_MP3';
    is Mix_Init(MIX_INIT_FLAC), MIX_INIT_FLAC, 'Mix_Init( MIX_INIT_FLAC ) == MIX_INIT_FLAC';
    is Mix_Init( MIX_INIT_MP3 | MIX_INIT_FLAC ), MIX_INIT_MP3 | MIX_INIT_FLAC,
        'Mix_Init( MIX_INIT_MP3|MIX_INIT_FLAC ) == MIX_INIT_MP3|MIX_INIT_FLAC';
    #
    is SDL_Init(SDL_INIT_AUDIO), 0, 'SDL_Init( SDL_INIT_AUDIO ) == 0';
    is Mix_OpenAudio( 44100, MIX_DEFAULT_FORMAT, 2, 1024 ), 0,
        'Mix_OpenAudio( 44100, MIX_DEFAULT_FORMAT, 2, 1024 ) == 0';
    for my $i ( 0 .. SDL_GetNumAudioDevices(0) - 1 ) {
        is Mix_OpenAudioDevice( 44100, MIX_DEFAULT_FORMAT, 2, 1024, SDL_GetAudioDeviceName($i), 0 ),
            0, sprintf 'Mix_OpenAudioDevice( ..., "%s", 0 ) == 0', SDL_GetAudioDeviceName( $i, 0 );
    }

    END {
        diag 'Closing audio sessions...';
        Mix_CloseAudio() for 0 .. Mix_QuerySpec( undef, undef, undef );
    }
    is Mix_AllocateChannels(16), 16, 'Mix_AllocateChannels( 16 ) == 16';
    is Mix_AllocateChannels(-1), 16, 'Mix_AllocateChannels( -1 ) == 16 (no change)';

    # get and print the audio format in use
    #int numtimesopened, frequency, channels;
    #Uint16 format;
    my $numtimesopened = Mix_QuerySpec( \my $frequency, \my $format, \my $channels );

    # XXX: Are we sure we can open *all* audio devices?
    # We called plain ol' Mix_OpenAudio( ... ) first so +1
    is $numtimesopened, SDL_GetNumAudioDevices(0) + 1,
        sprintf 'Mix_QuerySpec( ... ) claims we have %d open audio sessions', $numtimesopened;
    isa_ok Mix_LoadWAV_RW( SDL_RWFromFile( $wav, 'rb' ), 1 ), ['SDL2::Mixer::Chunk'],
        "Mix_LoadWAV_RW( SDL_RWFromFile( '$wav', 'rb' ), 1 ) returns a SDL2::Mixer::Chunk";
    isa_ok Mix_LoadWAV($wav), ['SDL2::Mixer::Chunk'],
        "Mix_LoadWAV( '$wav' ) returns a SDL2::Mixer::Chunk";
    isa_ok Mix_LoadMUS($mp3), ['SDL2::Mixer::Music'],
        "Mix_LoadWAV( '$mp3' ) returns a SDL2::Mixer::Music";
    isa_ok Mix_LoadMUS_RW( SDL_RWFromFile( $mp3, 'rb' ), 1 ), ['SDL2::Mixer::Music'],
        "Mix_LoadMUS_RW(SDL_RWFromFile( '$mp3', 'rb' ), 1) returns a SDL2::Mixer::Music";
    isa_ok Mix_LoadMUSType_RW( SDL_RWFromFile( $mp3, 'rb' ), MUS_MP3, 1 ), ['SDL2::Mixer::Music'],
        "Mix_LoadMUSType_RW(SDL_RWFromFile( '$mp3', 'rb' ), MUS_MP3, 1) returns a SDL2::Mixer::Music";
    isa_ok Mix_LoadMUSType_RW( SDL_RWFromFile( $wav, 'rb' ), MUS_WAV, 1 ), ['SDL2::Mixer::Music'],
        "Mix_LoadMUSType_RW(SDL_RWFromFile( '$wav', 'rb' ), MUS_WAV, 1) returns a SDL2::Mixer::Music";
    is Mix_LoadMUSType_RW( SDL_RWFromFile( $mp3, 'rb' ), MUS_WAV, 1 ), undef,
        "Mix_LoadMUSType_RW(SDL_RWFromFile( '$mp3', 'rb' ), MUS_WAV, 1) returns undef: " .
        Mix_GetError();
    isa_ok Mix_QuickLoad_WAV( $wav->slurp_raw() ), ['SDL2::Mixer::Chunk'],
        'Mix_QuickLoad_WAV( ... ) returns SDL2::Mixer::Chunk';
    isa_ok Mix_QuickLoad_RAW( $wav->slurp_raw(), -s $wav ), ['SDL2::Mixer::Chunk'],
        'Mix_QuickLoad_RAW( ... ) returns SDL2::Mixer::Chunk';
    #
    my $chunk = Mix_QuickLoad_WAV( $wav->slurp_raw() );
    is Mix_FreeChunk($chunk), undef, 'Mix_FreeChunk( ... ) returns void...';
    my $music = Mix_LoadMUS($mp3);
    is Mix_FreeMusic($music), undef, 'Mix_FreeMusic( ... ) returns void...';
    #
    diag sprintf 'There are %d sample chunk decoders available:', Mix_GetNumChunkDecoders();
    for my $index ( 0 .. Mix_GetNumChunkDecoders() - 1 ) {

        # Mix_HasChunkDecoder( ... ) was defined in SDL_mixer 2.0.5
        my $has
            = SDL_MIXER_VERSION_ATLEAST( 2, 0, 5 ) ?
            Mix_HasChunkDecoder($index) ?
            'yes' :
                'no' :
            'unknown';
        diag sprintf '    - %-6s %s', Mix_GetChunkDecoder($index), $has;
    }
    diag sprintf 'There are %d music decoders available:', Mix_GetNumMusicDecoders();
    for my $index ( 0 .. Mix_GetNumMusicDecoders() - 1 ) {

        # Mix_HasMusicDecoder( ... ) was defined in SDL_mixer 2.0.5
        my $has
            = SDL_MIXER_VERSION_ATLEAST( 2, 0, 5 ) ?
            Mix_HasMusicDecoder($index) ?
            'yes' :
                'no' :
            'unknown';
        diag sprintf '    - %-6s %s', Mix_GetMusicDecoder($index), $has;
    }
    is Mix_GetMusicType( Mix_LoadMUS($mp3) ), MUS_MP3,
        'Mix_GetMusicType( Mix_LoadMUS($mp3) ) == MUS_MP3';
    if ( SDL_MIXER_VERSION_ATLEAST( 2, 0, 5 ) ) {
        is Mix_GetMusicTitle($mp3),        'Test', 'Mix_GetMusicTitle( ... )';
        is Mix_GetMusicTitleTag($mp3),     'Test', 'Mix_GetMusicTitleTag( ... )';
        is Mix_GetMusicArtistTag($mp3),    'Test', 'Mix_GetMusicArtistTag( ... )';
        is Mix_GetMusicAlbumTag($mp3),     'Test', 'Mix_GetMusicAlbumTag( ... )';
        is Mix_GetMusicCopyrightTag($mp3), 'Test', 'Mix_GetMusicCopyrightTag( ... )';
    }
    #
    {
        my $done = 0;
        Mix_SetPostMix(
            sub {
                my ( $udata, $stream, $len ) = @_;
                $$stream = [ map { int rand 20 } 0 .. $len ];    # hiss
                pass 'Mix_SetPostMix( ... ) callback';
                is $udata->{test}, 'yep', '   userdata is correct';
                $done++;
            },
            { test => 'yep' }
        );
        Mix_PlayMusic( Mix_LoadMUS($mp3), 1 );    # Only play it once
        SDL_AddTimer( 1000, sub { $done++ if !Mix_PlayingMusic(); return shift; } );  # Just in case
        SDL_Delay(1) while !$done;
    }
    {
        my $done = 0;
        my @ff   = map { int rand(20) } 0 .. 5000;    # Some predefined music
        Mix_HookMusic(
            sub {
                my ( $udata, $stream, $len ) = @_;

                # fill buffer with...uh...music...
                $$stream->[$_] = $ff[ ( $_ + $udata->{pos} ) % ( scalar @ff ) ] // 0 for 0 .. $len;

                # set udata for next time
                if ( $udata->{pos} >= 50000 ) {
                    pass 'Mix_SetPostMix( ... ) callback';
                    ok $udata->{pos}, '   userdata is defined (and sticky)';
                    $done++;
                }
                $udata->{pos} += $len;
            },
            { pos => 0 }
        );

        #Mix_PlayMusic( Mix_LoadMUS($mp3), 1 );    # Only play it once
        SDL_AddTimer( 1000, sub { $done++ if !Mix_PlayingMusic(); return shift; } );  # Just in case
        SDL_Delay(1) while !$done;
        my $data = Mix_GetMusicHookData();
        ok $data->{pos}, 'Mix_GetMusicHookData()';
    }
};
#
can_ok $_ for qw[
    SDL_MIXER_MAJOR_VERSION
    SDL_MIXER_MINOR_VERSION
    SDL_MIXER_PATCHLEVEL
    SDL_MIXER_VERSION
    SDL_MIXER_COMPILEDVERSION
    SDL_MIXER_VERSION_ATLEAST
    MIX_INIT_FLAC
    MIX_INIT_MOD
    MIX_INIT_MP3
    MIX_INIT_OGG
    MIX_INIT_MID
    MIX_INIT_OPUS
    MIX_CHANNELS
    MIX_DEFAULT_FREQUENCY
    MIX_DEFAULT_FORMAT
    MIX_DEFAULT_CHANNELS
    MIX_MAX_VOLUME
    MUS_NONE
    MUS_CMD
    MUS_WAV
    MUS_MOD
    MUS_MID
    MUS_OGG
    MUS_MP3
    MUS_MP3_MAD_UNUSED
    MUS_FLAC
    MUS_MODPLUG_UNUSED
    MUS_OPUS
];
#
done_testing;
