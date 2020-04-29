package Net::SermonAudio::Model::Sermon;
use Date::Tiny;
use DateTime;
use Moo;
use Net::SermonAudio::Model::Broadcaster;
use Net::SermonAudio::Model::Speaker;
use Net::SermonAudio::Model::SermonSeries;
use Net::SermonAudio::Model::MediaSet;
use Net::SermonAudio::Types qw(+SermonEventType);
use Types::Standard qw(InstanceOf Int Str Maybe ArrayRef);

use experimental 'signatures';
no warnings 'experimental';

has _obj => (is => 'ro');
has sermon_id => (is => 'ro', isa => Str);
has broadcaster => (is => 'ro', isa => InstanceOf [ 'Net::SermonAudio::Model::Broadcaster' ]);
has speaker => (is => 'ro', isa => InstanceOf [ 'Net::SermonAudio::Model::Speaker' ]);
has full_title => (is => 'ro', isa => Str);
has display_title => (is => 'ro', isa => Str);
has subtitle => (is => 'ro', isa => Maybe [ Str ]);
has series => (is => 'ro', isa => Maybe [ InstanceOf [ 'Net::SermonAudio::Model::SermonSeries' ] ]);
has preach_date => (is => 'ro', isa => InstanceOf [ 'Date::Tiny' ]);
has staff_pick_date => (is => 'ro', isa => Maybe [ InstanceOf [ 'Date::Tiny' ] ]);
has publish_timestamp => (is => 'ro', isa => Maybe [ InstanceOf [ 'DateTime' ] ]);
has update_date => (is => 'ro', isa => InstanceOf [ 'DateTime' ]);
has language_code => (is => 'ro', isa => Str);
has bible_text => (is => 'ro', isa => Maybe [ Str ]);
has more_info_text => (is => 'ro', isa => Maybe [ Str ]);
has event_type => (is => 'ro', isa => SermonEventType);
has display_event_type => (is => 'ro', isa => Str);
has download_count => (is => 'ro', isa => Int);
has video_download_count => (is => 'ro', isa => Int);
has document_download_count => (is => 'ro', isa => Int);
has external_link => (is => 'ro', isa => Maybe [ InstanceOf [ 'Mojo::URL' ] ]);
has keywords => (is => 'ro', isa => ArrayRef [ Str ]);
has media => (is => 'ro', isa => InstanceOf [ 'Net::SermonAudio::Model::MediaSet' ]);

sub broadcaster_class { 'Net::SermonAudio::Model::Broadcaster' }
sub speaker_class { 'Net::SermonAudio::Model::Speaker' }
sub series_class { 'Net::SermonAudio::Model::SermonSeries' }
sub media_set_class { 'Net::SermonAudio::Model::MediaSet' }

sub to_string($self) {
    "<Sermon @{ [ $self->speaker->display_name ] } - @{ [ $self->display_title ] }>"
}

sub parse($class, $obj) {
    $class->new(
        _obj                    => $obj,
        sermon_id               => $obj->{sermonID},
        broadcaster             => $class->broadcaster_class->parse($obj->{broadcaster}),
        speaker                 => $class->speaker_class->parse($obj->{speaker}),
        full_title              => $obj->{fullTitle},
        display_title           => $obj->{displayTitle},
        subtitle                => $obj->{subtitle},
        series                  => ($obj->{series} ? $class->series_class->parse($obj->{series}) : undef),
        preach_date             => Date::Tiny->from_string($obj->{preachDate}),
        staff_pick_date         => (eval { Date::Tiny->from_string($obj->{pickDate}) } || undef),
        publish_timestamp       => ($obj->{publishTimestamp} ? DateTime->from_epoch(epoch => $obj->{publishTimestamp}) : undef),
        update_date             => DateTime->from_epoch(epoch => $obj->{updateDate}),
        language_code           => $obj->{languageCode},
        bible_text              => $obj->{bibleText},
        more_info_text          => $obj->{moreInfoText},
        event_type              => (is_SermonEventType($obj->{eventType}) ? $obj->{eventType} : undef),
        display_event_type      => $obj->{displayEventType},
        download_count          => $obj->{downloadCount},
        video_download_count    => $obj->{videoDownloadCount},
        document_download_count => $obj->{documentDownloadCount},
        external_link           => (defined $obj->{externalLink} ? Mojo::URL->new($obj->{externalLink}) : undef),
        keywords                => ($obj->{keywords} ? (ref $obj->{keywords} ? $obj->{keywords} : [ split /\s+/, $obj->{keywords} ]) : []),
        media                   => $class->media_set_class->parse($obj->{media}),
    )
}

1;