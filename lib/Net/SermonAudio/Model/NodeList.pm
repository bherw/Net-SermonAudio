package Net::SermonAudio::Model::NodeList;
use Moo;
use Net::SermonAudio::Model::Sermon;

use experimental 'signatures';
no warnings 'experimental';

has _obj => (is => 'ro');
has results => (is => 'ro');
has total_count => (is => 'ro');
has next => (is => 'ro');

sub parse($class, $obj) {
    $class->new(
        _obj        => $obj,
        total_count => $obj->{totalCount},
        next        => $obj->{next},
        results     => [ map { $class->node_class->parse($_) } $obj->{results}->@* ],
    )
}

1;