package Net::SermonAudio::API;
use Mojo::UserAgent;
use Mojo::URL;
use Moo;
use Scalar::Util qw(blessed);
use Types::Standard qw(InstanceOf Str);

use experimental 'signatures';
no warnings 'experimental';

my $BASE_URL = Mojo::URL->new('https://api.sermonaudio.com/v2/');

has api_key => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has base_url => (
    is      => 'ro',
    isa     => InstanceOf [ 'Mojo::URL' ],
    default => sub { $BASE_URL },
);

has preferred_language => (
    is      => 'ro',
    isa     => Str,
    default => sub {
        require POSIX;
        (split(/\./, POSIX::setlocale(&POSIX::LC_ALL)))[0];
    },
);

has ua => (
    is      => 'ro',
    isa     => InstanceOf [ 'Mojo::UserAgent' ],
    default => sub { Mojo::UserAgent->new },
);

sub build_tx($self, $method, $path, %opts) {
    my $headers = $opts{headers} // {};
    $headers->{'X-API-Key'} //= $opts{api_key} // $self->api_key;
    $headers->{'Accept-Language'} // $opts{preferred_language} // $self->preferred_language;

    if (!defined $opts{show_content_in_any_language} || $opts{show_content_in_any_language}) {
        $headers->{'X-Show-All-Languages'} = 'True';
    }

    my $url;
    if (!ref $path) {
        $url = $self->base_url->clone;
        $url->path->merge($path);
    }
    else {
        $url = $path;
    }

    my $ua = $opts{ua} // $self->ua;
    my %content;
    if ($opts{form}) {
        $content{form} = _stringify_map($opts{form});
    }
    if ($opts{json}) {
        $content{json} = _stringify_map($opts{json});
    }

    return $ua->build_tx($method => $url => $headers, %content);
}

sub _stringify_map {
    my $input = shift;
    my %result;
    for my $key (keys %$input) {
        if (defined $input->{$key} && blessed $input->{$key}) {
            $result{$key} = $input->{$key} . '';
        }
        else {
            $result{$key} = $input->{$key};
        }
    }
    return \%result;
}

sub start($self, $tx, %opts) {
    my $ua = $opts{ua} // $self->ua;
    return $ua->start_p($tx);
}

sub _request($self, $method, $path, %opts) {
    return $self->start($self->build_tx($method, $path, %opts));
}

sub get {
    shift->_request(GET => @_);
}

sub post {
    shift->_request(POST => @_);
}

sub put {
    shift->_request(PUT => @_);
}

sub patch {
    shift->_request(PATCH => @_);
}

sub delete {
    shift->_request(DELETE => @_);
}

1;
