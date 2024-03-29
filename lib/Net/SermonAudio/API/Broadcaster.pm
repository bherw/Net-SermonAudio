package Net::SermonAudio::API::Broadcaster;
use Date::Tiny;
use Moo;
use Future::AsyncAwait;
use Net::SermonAudio::Types qw(+MaybeStr +SermonEventType +SermonSortBy);
use Types::Standard qw(+Bool +Str +Int InstanceOf Maybe ArrayRef);
use Net::SermonAudio::Model::Sermon;
use Net::SermonAudio::Model::SermonSeries;
use Net::SermonAudio::Model::SeriesList;
use Net::SermonAudio::Model::SermonsList;
use Net::SermonAudio::Model::Speaker;

use experimental 'signatures';
no warnings 'experimental';

extends qw(Net::SermonAudio::API);

sub sermon_class { 'Net::SermonAudio::Model::Sermon' }
sub sermons_list_class { 'Net::SermonAudio::Model::SermonsList' }
sub series_class { 'Net::SermonAudio::Model::SermonSeries' }
sub series_list_class { 'Net::SermonAudio::Model::SeriesList' }
sub speaker_class { 'Net::SermonAudio::Model::Speaker' }


sub parse_sermon($self, $tx) {
    return $self->_parse($self->sermon_class, $tx);
}

async sub list_sermons($self, %opt) {
    my %param = %{ $opt{params} // {} };
    $param{book} = assert_Str($opt{book}) if defined $opt{book};
    $param{chapter} = assert_Int($opt{chapter}) if defined $opt{chapter};
    $param{chapterEnd} = assert_Int($opt{chapter_end}) if defined $opt{chapter_end};
    $param{verse} = assert_Int($opt{verse}) if defined $opt{verse};
    $param{verseEnd} = assert_Int($opt{verse_end}) if defined $opt{verse_end};
    $param{eventType} = assert_SermonEventType($opt{event_type}) if defined $opt{event_type};
    $param{languageCode} = assert_Str($opt{language_code}) if defined $opt{language_code};
    $param{requireAudio} = _assert_conv_bool($opt{require_audio}) if defined $opt{require_audio};
    $param{requireVideo} = _assert_conv_bool($opt{require_video}) if defined $opt{require_video};
    $param{includeDrafts} = _assert_conv_bool($opt{include_drafts}) if defined $opt{include_drafts};
    $param{includeScheduled} = _assert_conv_bool($opt{include_scheduled}) if defined $opt{include_scheduled};
    $param{includePublished} = _assert_conv_bool($opt{include_published}) if defined $opt{include_published};

    if (defined $opt{series}) {
        die "broadcasterID must also be specified" unless defined $opt{broadcaster_id};
        $param{series} = assert_Str($opt{series});
    }

    $param{broadcasterID} = assert_Str($opt{broadcaster_id}) if defined $opt{broadcaster_id};
    $param{speakerName} = assert_Str($opt{speaker_name}) if defined $opt{speaker_name};
    $param{staffPick} = _assert_conv_bool($opt{staff_pick}) if defined $opt{staff_pick};
    $param{year} = assert_Int($opt{year}) if defined $opt{year};
    $param{sortBy} = assert_SermonSortBy($opt{sort_by}) if defined $opt{sort_by};
    $param{page} = assert_Int($opt{page}) if defined $opt{page};
    $param{searchKeyword} = assert_Str($opt{search_keyword}) if defined $opt{search_keyword};

    my $url = $self->base_url->clone;
    if ($opt{next} && (my $next = assert_Str($opt{next}))) {
        $url->path_query($next);
    }
    else {
        $url->path->merge('node/sermons');
        $url->query(\%param);
    }
    return $self->_parse($self->sermons_list_class, await $self->get($url, %opt));
}

# Experimental code warning!
async sub list_sermons_between($self, $from_date, $to_date, %opt) {
    die "cannot use year, sort_by, page options" if $opt{year} || $opt{page} || $opt{sort_by};
    die "expected from_date and to_date to be datelike" unless defined $from_date && defined $to_date && $from_date->can('ymd') && $to_date->can('ymd');
    die "from_date must be less than or equal to to_date" unless $from_date <= $to_date;

    # Keep requesting from intervening years starting from the newest sermons
    # until we run out of pages to query or the earliest date we have is less
    # than the from_date, so we're guaranteed to have everything.
    my @results;
    for my $year ($from_date->year .. $to_date->year) {
        my $next;
        do {
            my $list = await $self->list_sermons(year => $year, sort_by => 'newest', ($next ? (next => $next) : ()), %opt);
            $next = $list->next;
            push @results, @{ $list->results };
        } until (!$next || (map { $_->preach_date } @results)[-1]->ymd lt $from_date->ymd);
    }

    $from_date = $from_date->ymd;
    $to_date = $to_date->ymd;
    @results = grep { $from_date le $_->preach_date->ymd && $_->preach_date->ymd le $to_date } @results;
    return Net::SermonAudio::Model::SermonsList->new(
        total_count => scalar @results,
        results     => \@results,
    );
}

async sub get_sermon($self, $sermon, %opt) {
    my $sermon_id = ref $sermon ? $sermon->sermon_id : assert_Str($sermon);
    $self->parse_sermon(await $self->get("node/sermons/$sermon_id", %opt));
}

async sub create_sermon($self, %opt) {
    my $params = $self->_sermon_edit_params(%opt);
    my $tx = await $self->post('node/sermons', json => $params, %opt);
    my $s = $self->parse_sermon($tx);
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
    my $tx = await $self->put("node/sermons/$sermon_id", json => $params, %opt);
    return $self->parse_sermon($tx);
}

async sub publish_sermon($self, $sermon, %opt) {
    my $sermon_id = ref $sermon ? $sermon->sermon_id : assert_Str($sermon);
    return $self->_assert_success(await $self->patch("node/sermons/$sermon_id", json => { publishNow => 'True' }, %opt));
}

async sub delete_sermon($self, $sermon, %opt) {
    my $sermon_id = ref $sermon ? $sermon->sermon_id : assert_Str($sermon);
    return $self->_assert_success(await $self->delete("node/sermons/$sermon_id", %opt));
}

async sub duplicate_sermon($self, $sermon, %opt) {
    my $sermon_id = ref $sermon ? $sermon->sermon_id : assert_Str($sermon);
    return $self->parse_sermon(await $self->post("node/sermons/$sermon_id/duplicate", %opt));
}

async sub get_speaker($self, $speaker, %opt) {
    my $speaker_name = ref $speaker ? $speaker->display_name : assert_Str($speaker);
    return $self->parse_speaker(await $self->get("node/speakers/$speaker_name", %opt));
}

async sub speaker_exists($self, $speaker, %opt) {
    my $speaker_name = ref $speaker ? $speaker->display_name : assert_Str($speaker);
    return (await $self->get("node/speakers/$speaker_name", %opt))->res->code == 200;
}

async sub upload_audio($self, $sermon, $path) {
    await $self->_upload_media('original-audio', $sermon, $path);
}

async sub upload_video($self, $sermon, $path) {
    await $self->_upload_media('original-video', $sermon, $path);
}

async sub list_series($self, $broadcaster_id, %opt) {
    assert_Str($broadcaster_id);
    return $self->_parse($self->series_list_class, await $self->get("node/broadcasters/$broadcaster_id/series", %opt));
}

async sub get_series($self, $broadcaster_id, $series, %opt) {
    assert_Str($broadcaster_id);
    my $id_or_title = ref $series ? $series->series_id : assert_Str($series);
    return $self->parse_series(await $self->get("node/broadcasters/$broadcaster_id/series/$id_or_title", %opt));
}

async sub series_exists($self, $broadcaster_id, $series, %opt) {
    assert_Str($broadcaster_id);
    my $id_or_title = ref $series ? $series->series_id : assert_Str($series);
    return (await $self->get("node/broadcasters/$broadcaster_id/series/$id_or_title", %opt))->res->code == 200;
}

async sub create_series($self, $broadcaster_id, $title, %opt) {
    assert_Str($broadcaster_id);
    assert_Str($title);
    my $path = "node/broadcasters/$broadcaster_id/series";
    return $self->parse_series(await $self->post($path, form => { series_name => $title }, %opt));
}

async sub rename_series($self, $broadcaster_id, $series, $new_title, %opt) {
    assert_Str($broadcaster_id);
    my $id_or_title = ref $series ? $series->series_id : assert_Str($series);
    my $path = "node/broadcasters/$broadcaster_id/series/$id_or_title";
    return $self->_assert_success(await $self->patch($path, form => { new_series_name => $new_title }, %opt));
}

async sub delete_series($self, $broadcaster_id, $series, %opt) {
    assert_Str($broadcaster_id);
    my $id_or_title = ref $series ? $series->series_id : assert_Str($series);
    my $path = "node/broadcasters/$broadcaster_id/series/$id_or_title";
    return $self->_assert_success(await $self->delete($path, %opt));
}

async sub move_sermon_to_series($self, $sermon, $series, %opt) {
    my $sermon_id = ref $sermon ? $sermon->sermon_id : assert_Str($sermon);
    my $series_id = ref $series ? $series->series_id : assert_Str($series);
    my $path = "node/sermons/$sermon_id";
    return $self->_assert_success(await $self->patch($path, form => { series_id => $series_id }, %opt));
}

sub parse_series($self, $tx) {
    return $self->_parse($self->series_class, $tx);
}

sub parse_speaker($self, $tx) {
    return $self->_parse($self->speaker_class, $tx);
}

sub _assert_success($self, $tx) {
    return 1 if $tx->res->code == 200 || $tx->res->code == 204;

    require Net::SermonAudio::X::BroadcasterApiException;
    Net::SermonAudio::X::BroadcasterApiException->throw(res => $tx->res, message => $tx->res->json);
}

sub _parse($self, $class, $tx) {
    if (!($tx->res->code >= 200 && $tx->res->code <= 299)) {
        require Net::SermonAudio::X::BroadcasterApiException;
        Net::SermonAudio::X::BroadcasterApiException->throw(res => $tx->res, message => $tx->res->json);
    }

    my $parse_result;
    eval {
        $parse_result = $class->parse($tx->res->json);
    } or do {
        require Net::SermonAudio::X::BroadcasterApiException;
        Net::SermonAudio::X::BroadcasterApiException->throw(res => $tx->res, message => $tx->res->content . "\n" . $@);
    };

    return $parse_result;
}

sub _sermon_edit_params($self, %opt) {
    my $publish_timestamp = (Maybe [ InstanceOf [ 'DateTime' ] ])->assert_return($opt{publish_timestamp});
    return {
        %{ $opt{params} // {} },
        acceptCopyright  => _assert_conv_bool($opt{accept_copyright}),
        fullTitle        => assert_Str($opt{full_title}),
        speakerName      => assert_Str($opt{speaker_name}),
        preachDate       => (InstanceOf [ 'Date::Tiny' ])->assert_return($opt{preach_date}),
        publishTimestamp => ($publish_timestamp ? $publish_timestamp->epoch : undef),
        eventType        => assert_SermonEventType($opt{event_type}),
        displayTitle     => assert_MaybeStr($opt{display_title}),
        subtitle         => assert_MaybeStr($opt{subtitle}),
        bibleText        => assert_MaybeStr($opt{bible_text}),
        moreInfoText     => assert_MaybeStr($opt{more_info_text}),
        languageCode     => assert_Str($opt{language_code}),
        keywords         => join(' ', @{ (Maybe [ ArrayRef [ Str ] ])->assert_return($opt{keywords}) // [] }),
        newsInFocus      => _assert_conv_bool($opt{news_in_focus}),
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

    unless ($res->code == 201) {
        # CREATED
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

    1;
}


sub _assert_conv_bool {
    assert_Bool($_[0]) ? 'true' : 'false';
}

1;
