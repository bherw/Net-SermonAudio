package Net::SermonAudio::Model::Node;
use Moo;
use Types::Standard qw(Str Int ArrayRef HashRef Maybe);

use experimental 'signatures';
no warnings 'experimental';

has _obj => (is => 'ro');
has node_type => (is => 'ro', isa => String);
has node_display_name => (is => 'ro', isa => String);
has results => (is => 'ro', isa => ArrayRef | HashRef);
has total_count => (is => 'ro', isa => Maybe[Int]);
has next => (is => 'ro', isa => Maybe[Str]);

sub parse($class, $obj) {
    $class->new(
        _obj              => $obj,
        node_type         => $obj->{nodeType},
        node_display_name => $obj->{nodeDisplayName},
        results           => $obj->{results},
        total_count       => $obj->{totalCount},
        next              => $obj->{next},
    );
}

1;