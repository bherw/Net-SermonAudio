package Net::SermonAudio::X::ApiException;
use Moo;
use overload '""' => sub { shift->to_string };

use experimental 'signatures';
no warnings 'experimental';

with 'Throwable';

has 'message' => (is => 'ro', required => 1);
has res => (is => 'ro', required => 1);

sub code { shift->res->code }

sub to_string($self) {
    "Net::SermonAudio::X::ApiException: " . $self->message . "\nHTTP status: " . $self->code . ' ' . $self->res->message;
}

1;
