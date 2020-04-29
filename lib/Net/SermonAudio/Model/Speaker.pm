package Net::SermonAudio::Model::Speaker;
use Date::Tiny;
use Mojo::URL;
use Moo;
use Types::Standard qw(Maybe Str Int InstanceOf);

use experimental 'signatures';
no warnings 'experimental';

my %GENERIC_SPEAKER_NAMES = ("Various Speakers" => 1, "Unknown Speaker" => 1);

has _obj => (is => 'ro');
has [ qw(
    display_name
    sort_name
    album_art_url_format
) ] => (is => 'ro', isa => Str);

has [ qw(
    bio
) ] => (is => 'ro', isa => Maybe [ Str ]);

has [ qw(
    portrait_url
    rounded_thumbnail_image_url
) ] => (is => 'ro', isa => InstanceOf [ 'Mojo::URL' ]);

has most_recent_preach_date => (is => 'ro', isa => Maybe [ InstanceOf [ 'Date::Tiny' ] ]);
has sermon_count => (is => 'ro', isa => Maybe [ Int ]);

sub album_art_url($self, $size) {
    Mojo::URL->new($self->album_art_url_format =~ s/\{size\}/$size/)
}

sub is_generic($self) {
    exists $GENERIC_SPEAKER_NAMES{$self->display_name}
}

sub parse($class, $obj) {
    $class->new(
        _obj => $obj,
        display_name                => $obj->{displayName},
        sort_name                   => $obj->{sortName},
        bio                         => $obj->{bio},
        portrait_url                => Mojo::URL->new($obj->{portraitURL}),
        rounded_thumbnail_image_url => Mojo::URL->new($obj->{roundedThumbnailImageURL}),
        album_art_url_format        => $obj->{albumArtURL},
        most_recent_preach_date     => ($obj->{mostRecentPreachDate} ? Date::Tiny->from_string($obj->{mostRecentPreachDate}) : undef),
        sermon_count                => $obj->{sermonCount},
    )
}

1;