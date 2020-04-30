package Net::SermonAudio::Model::SeriesList;
use Moo;
use Net::SermonAudio::Model::SermonSeries;

use experimental 'signatures';
no warnings 'experimental';

extends qw(Net::SermonAudio::Model::NodeList);

sub node_class { shift->series_class }
sub series_class { 'Net::SermonAudio::Model::SermonSeries' }

sub to_string($self) {
    "<SeriesList @{ [ $self->total_count ] } series - next page: @{ [ $self->next ] }>"
}

1;


1;