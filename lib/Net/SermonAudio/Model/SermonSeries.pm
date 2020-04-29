package Net::SermonAudio::Model::SermonSeries;
use Date::Tiny;
use DateTime;
use Moo;

use experimental 'signatures';
no warnings 'experimental';

has _obj => (is => 'ro');
has [ qw(series_id title broadcaster_id latest earliest updated count) ] => (is => 'ro');

sub to_string($self) {
    "<SermonSeries @{ [ $self->title ] } (@{ [ $self->count ] } sermons)>"
}

sub parse($class, $obj) {
    $class->new(
        _obj => $obj,
        series_id      => $obj->{seriesID},
        broadcaster_id => $obj->{broadcasterID},
        latest         => ($obj->{latest} ? Date::Tiny->from_string($obj->{latest}) : undef),
        earliest       => ($obj->{latest} ? Date::Tiny->from_string($obj->{earliest}) : undef),
        updated        => DateTime->from_epoch(epoch => $obj->{updated}),

        %$obj{qw(title count)},
    )
}

1;
