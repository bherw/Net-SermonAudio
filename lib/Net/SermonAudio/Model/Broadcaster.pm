package Net::SermonAudio::Model::Broadcaster;
use Moo;
use Mojo::URL;
use Types::Standard qw(Maybe Str Bool Num InstanceOf);
use experimental 'signatures';
no warnings 'experimental';

has _obj => (is => 'ro');
has [ qw(
    broadcaster_id
    id_code
    display_name
    short_name
    location
    album_art_url_format
) ] => (is => 'ro', isa => Str);

has [ qw(
    service_times
    denomination
    address
    minister
    phone
    listen_line_number
    bible_version
    facebook_username
    twitter_username
    about_us
    welcome_video_id
) ] => (is => 'ro', isa => Maybe [ Str ]);

has [ qw(
    can_webcast
    webcast_in_progress
    vacant_pulpit
) ] => (is => 'ro', isa => Bool);

has [ qw(
    service_times_are_preformatted
) ] => (is => 'ro', isa => Maybe [ Bool ]);

has [ qw(
    latitude
    longitude
) ] => (is => 'ro', isa => Maybe [ Num ]);

has [ qw(
    image_url
) ] => (is => 'ro', isa => InstanceOf [ 'Mojo::URL' ]);

has [ qw(
    home_page_url
) ] => (is => 'ro', isa => Maybe [ InstanceOf [ 'Mojo::URL' ] ]);

sub to_string($self) {
    "<Broadcaster @{ [ $self->broadcaster_id ] } \"@{ [ $self->display_name ] }\""
}

sub parse($class, $obj) {
    $class->new(
        _obj => $obj,
        broadcaster_id                 => $obj->{broadcasterID},
        id_code                        => $obj->{idCode},
        service_times_are_preformatted => (defined $obj->{serviceTimesArePreformatted} ? !!$obj->{serviceTimesArePreformatted} : undef),
        service_times                  => $obj->{serviceTimes},
        display_name                   => $obj->{displayName},
        short_name                     => $obj->{shortName},
        image_url                      => Mojo::URL->new($obj->{imageURL}),
        album_art_url_format           => $obj->{albumArtURL},
        listen_line_number             => $obj->{listenLineNumber},
        home_page_url                  => ($obj->{homePageURL} ? Mojo::URL->new($obj->{homePageURL}) : undef),
        bible_version                  => $obj->{bibleVersion},
        facebook_username              => $obj->{facebookUsername},
        twitter_username               => $obj->{twitterUsername},
        about_us                       => $obj->{aboutUs},
        can_webcast                    => !!$obj->{canWebcast},
        webcast_in_progress            => !!$obj->{webcastInProgress},
        vacant_pulpit                  => !!$obj->{vacantPulpit},
        welcome_video_id               => $obj->{welcomeVideoId},

        %$obj{qw(denomination address location latitude longitude minister phone)}
    )
}

sub album_art_url($self, $size) {
    Mojo::URL->new($self->album_art_url_format =~ s/\{size\}/$size/gr)
}

1;