package Net::SermonAudio::Model::Media;
use Moo;
use Mojo::URL;
use Types::Standard qw(Bool Str Maybe Int InstanceOf);
use Net::SermonAudio::Types qw(+MediaType);

use experimental 'signatures';
no warnings 'experimental';

has _obj => (is => 'ro');
has media_type => (is => 'ro', isa => Maybe [ MediaType ]);

has [ qw(
    is_live
    is_adaptive
) ] => (is => 'ro', isa => Bool);

has [ qw(
    stream_url
    download_url
    thumbnail_image_url
    raw_url
) ] => (is => 'ro', isa => Maybe [ InstanceOf [ 'Mojo::URL' ] ]);

has [ qw(bitrate duration) ] => (is => 'ro', isa => Maybe [ Int ]);
has [ qw(audio_codec video_codec) ] => (is => 'ro', isa => Maybe [ Str ]);

sub parse($class, $obj) {
    $class->new(
        _obj => $obj,
        media_type          => (is_MediaType($obj->{mediaType}) ? $obj->{mediaType} : undef),
        is_live             => !!$obj->{live},
        is_adaptive         => !!$obj->{adaptiveBitrate},
        stream_url          => ($obj->{streamURL} ? Mojo::URL->new($obj->{streamURL}) : undef),
        download_url        => ($obj->{downloadURL} ? Mojo::URL->new($obj->{downloadURL}) : undef),
        audio_codec         => $obj->{audioCodec},
        videoCodec          => $obj->{videoCodec},
        thumbnail_image_url => ($obj->{thumbnailImageURL} ? Mojo::URL->new($obj->{thumbnailImageURL}) : undef),
        raw_url             => ($obj->{rawURL} ? Mojo::URL->new($obj->{rawURL}) : undef),
        %$obj{qw(bitrate duration)}
    )
}

1;