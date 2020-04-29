package Net::SermonAudio::API::Broadcaster;
use Date::Tiny;
use DateTime::Tiny;
use Moo;
use Future::AsyncAwait;
use Net::SermonAudio::Types qw(+OptionalStr +SermonEventType);
use Types::Standard qw(+Bool +Str InstanceOf Optional ArrayRef);
use Net::SermonAudio::Model::Sermon;

use experimental 'signatures';
no warnings 'experimental';

extends qw(Net::SermonAudio::API);

sub sermon_class { 'Net::SermonAudio::Model::Sermon' }

sub parse_sermon($self, $tx) {
    return $self->sermon_class->parse($tx->res->json) if $tx->res->code >= 200 && $tx->res->code <= 299;

    require Net::SermonAudio::X::BroadcasterApiException;
    Net::SermonAudio::X::BroadcasterApiException->throw(res => $tx->res, message => $tx->res->json);
}

async sub get_sermon($self, $sermon_id, %opt) {
    $self->parse_sermon(await $self->get('node/sermons/' . assert_Str($sermon_id), %opt))
}

1;
