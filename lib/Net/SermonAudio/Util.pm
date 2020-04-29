package Net::SermonAudio::Util;
use strict;
use warnings FATAL => 'all';
use parent 'Exporter';
our @EXPORT = qw(await_get);

sub await_get {
    my $promise = shift;
    my (@return, $error) = @_;
    $promise->then(sub { @return = @_ }, sub { $error = shift })->wait;
    die $error if $error;
    return wantarray ? @return : shift @return;
}

1;