package Net::SermonAudio::Model::MediaSet;
use Moo;
use Types::Standard qw(InstanceOf ArrayRef);
use Net::SermonAudio::Model::Media;

use experimental 'signatures';
no warnings 'experimental';

has [ qw(audio video text) ] => (is => 'ro', isa => ArrayRef [ InstanceOf [ 'Net::SermonAudio::Model::Media' ] ]);

sub media_class { 'Net::SermonAudio::Model::Media' }

sub _parse_media($class, $set) {
    [ grep { defined $_->{media_type} } map { $class->media_class->parse($_) } @$set ]
}

sub parse($class, $obj) {
    $class->new(
        map { ($_ => $class->_parse_media($obj->{$_})) } qw(audio video text),
    )
}

1;
