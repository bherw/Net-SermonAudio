package Net::SermonAudio::Util;
use strict;
use warnings FATAL => 'all';
use parent 'Exporter';
our @EXPORT = qw(await_get);

sub await_get {
    my $promise = shift;
    my (@return, $error) = @_;
    $promise = $promise->then(sub { @return = @_ }, sub { $error = shift });
    if ($promise->can('wait')) {
        $promise->wait;
    } else {
        $promise->get;
    }
    die $error if $error;
    return wantarray ? @return : shift @return;
}

1;