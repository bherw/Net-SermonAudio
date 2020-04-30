package Net::SermonAudio::API::Broadcaster;
use Date::Tiny;
use DateTime::Tiny;
use Moo;
use Future::AsyncAwait;
use Net::SermonAudio::Types qw(+MaybeStr +SermonEventType);
use Types::Standard qw(+Bool +Str InstanceOf Maybe ArrayRef);
use Net::SermonAudio::Model::Sermon;
use Net::SermonAudio::Model::Speaker;

use experimental 'signatures';
no warnings 'experimental';

extends qw(Net::SermonAudio::API);

sub sermon_class { 'Net::SermonAudio::Model::Sermon' }
sub speaker_class { 'Net::SermonAudio::Model::Speaker' }

sub parse_sermon($self, $tx) {
    return $self->_parse($self->sermon_class, $tx);
}

async sub get_sermon($self, $sermon_id, %opt) {
    $self->parse_sermon(await $self->get('node/sermons/' . assert_Str($sermon_id), %opt))
}

async sub create_sermon($self, %opt) {
    my $params = $self->_sermon_edit_params(%opt);
    my $tx = await $self->post('node/sermons', form => $params, %opt);
    my $s= $self->parse_sermon($tx);
    $s;
}

async sub update_sermon($self, $sermon, %opt) {
    die "expected sermon" unless ref $sermon && $sermon->isa('Net::SermonAudio::Model::Sermon');

    $opt{$_} //= $sermon->$_ for qw(full_title preach_date publish_timestamp event_type display_title subtitle bible_text more_info_text language_code keywords);
    $opt{speaker_name} //= $sermon->speaker->display_name;
    $opt{broadcaster_id} //= $sermon->broadcaster->broadcaster_id;

    return await $self->update_sermon_by_id($sermon->sermon_id, %opt);
}

async sub update_sermon_by_id($self, $sermon_id, %opt) {
    assert_Str($sermon_id);
    my $params = $self->_sermon_edit_params(%opt);
    $params->{broadcasterID} = assert_Str($opt{broadcaster_id});
    my $tx = await $self->put("node/sermons/$sermon_id", form => $params, %opt);
    return $self->parse_sermon($tx);
}

async sub publish_sermon($self, $sermon, %opt) {
    my $sermon_id = ref $sermon ? $sermon->sermon_id : assert_Str($sermon);
    return await $self->patch("node/sermons/$sermon_id", form => { publishNow => 'True' }, %opt);
}

async sub delete_sermon($self, $sermon, %opt) {
    my $sermon_id = ref $sermon ? $sermon->sermon_id : assert_Str($sermon);
    return await $self->delete("node/sermons/$sermon_id", %opt);
}

async sub duplicate_sermon($self, $sermon, %opt) {
    my $sermon_id = ref $sermon ? $sermon->sermon_id : assert_Str($sermon);
    return $self->parse_sermon(await $self->post("node/sermons/$sermon_id/duplicate", %opt));
}

async sub get_speaker($self, $speaker, %opt) {
    my $speaker_name = ref $speaker ? $speaker->display_name : assert_Str($speaker);
    return $self->parse_speaker(await $self->get("node/speakers/$speaker_name", %opt));
}

async sub upload_audio($self, $sermon, $path) {
    await $self->_upload_media('original-audio', $sermon, $path)
}

async sub upload_video($self, $sermon, $path) {
    await $self->_upload_media('original-video', $sermon, $path)
}

sub parse_speaker($self, $tx) {
    return $self->_parse($self->speaker_class, $tx);
}

sub _parse($self, $class, $tx) {
    return $class->parse($tx->res->json) if $tx->res->code >= 200 && $tx->res->code <= 299;

    require Net::SermonAudio::X::BroadcasterApiException;
    Net::SermonAudio::X::BroadcasterApiException->throw(res => $tx->res, message => $tx->res->json);
}

sub _sermon_edit_params($self, %opt) {
    return {
        %opt{params},
        acceptCopyright  => (assert_Bool($opt{accept_copyright}) ? 'True' : 'False'),
        fullTitle        => assert_Str($opt{full_title}),
        speakerName      => assert_Str($opt{speaker_name}),
        preachDate       => (InstanceOf [ 'Date::Tiny' ])->assert_return($opt{preach_date}),
        publishTimestamp => (Maybe [ InstanceOf [ 'DateTime' ] ])->assert_return($opt{publish_timestamp}),
        eventType        => assert_SermonEventType($opt{event_type}),
        displayTitle     => assert_MaybeStr($opt{display_title}),
        subtitle         => assert_MaybeStr($opt{subtitle}),
        bibleText        => assert_MaybeStr($opt{bible_text}),
        moreInfoText     => assert_MaybeStr($opt{more_info_text}),
        languageCode     => assert_Str($opt{language_code}),
        keywords         => join(' ', @{ (Maybe [ ArrayRef [ Str ] ])->assert_return($opt{keywords}) // [] }),
        newsInFocus      => (assert_Bool($opt{news_in_focus}) ? 'True' : 'False'),
    };
}

async sub _upload_media($self, $upload_type, $sermon, $path, %opt) {
    my $params = $opt{params} // {};
    $params->{uploadType} //= assert_Str($upload_type);
    $params->{sermonID} //= ref $sermon ? $sermon->sermon_id : assert_Str($sermon);

    if (!-f $path) {
        die "Unable to read upload file: $path";
    }

    my $res = (await $self->post('media', form => $params))->res;

    unless ($res->code == 201) { # CREATED
        require Net::SermonAudio::X::BroadcasterApiException;
        Net::SermonAudio::X::BroadcasterApiException->throw(res => $res, message => "Unable to create media upload: " . $res->body);
    }

    my $upload_url = $res->json->{uploadURL};
    my $tx = $self->build_tx(POST => Mojo::URL->new($upload_url));
    $tx->req->content->asset(Mojo::Asset::File->new(path => $path));
    $res = (await $self->start($tx))->res;

    unless ($res->code == 201) {
        require Net::SermonAudio::X::BroadcasterApiException;
        Net::SermonAudio::X::BroadcasterApiException->throw(
            res     => $res,
            message => "Error uploading media to $upload_url: " . $res->body,
        );
    }

    1
}

1;
