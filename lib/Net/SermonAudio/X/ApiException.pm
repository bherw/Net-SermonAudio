package Net::SermonAudio::X::ApiException;
use Moo;

with 'Throwable';

has 'message';

1;