package Net::SermonAudio::Model::SermonsList;
use Moo;
use Net::SermonAudio::Model::Sermon;

use experimental 'signatures';
no warnings 'experimental';

has _obj => (is => 'ro');
has results => (is => 'ro');
has total_count => (is => 'ro');
has next => (is => 'ro');

sub sermon_class { 'Net::SermonAudio::Model::Sermon' }

sub to_string($self) {
    "<SermonList @{ [ $self->total_count ] } sermons - next page: @{ [ $self->next ] }>"
}

sub parse($class, $obj) {
    $class->new(
        _obj        => $obj,
        total_count => $obj->{totalCount},
        next        => $obj->{next},
        results     => [ map { $class->sermon_class->parse($_) } $obj->{results}->@* ],
    )
}

1;
