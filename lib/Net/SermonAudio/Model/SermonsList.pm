package Net::SermonAudio::Model::SermonsList;
use Moo;
use Net::SermonAudio::Model::Sermon;

use experimental 'signatures';
no warnings 'experimental';

sub node_class { shift->sermon_class }
sub sermon_class { 'Net::SermonAudio::Model::Sermon' }

sub to_string($self) {
    "<SermonList @{ [ $self->total_count ] } sermons - next page: @{ [ $self->next ] }>"
}

1;
