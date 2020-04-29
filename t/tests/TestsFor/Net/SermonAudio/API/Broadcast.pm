package TestsFor::Net::SermonAudio::API::Broadcast;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Net::SermonAudio::API::Broadcaster;
use Future::AsyncAwait;

use experimental 'signatures';
no warnings 'experimental';

use parent qw(Test::Class);

sub get_api($test) {
    unless ($ENV{SERMON_AUDIO_API_KEY}) {
        $test->builder->skip('Unable to test API features without a valid api key. Please set SERMON_AUDIO_API_KEY in your ENV.');
        return;
    }

    Net::SermonAudio::API::Broadcaster->new(api_key => $ENV{SERMON_AUDIO_API_KEY}, preferred_language => 'en_US')
}

sub get_sermon :Tests ($self) {
    my $sa = $self->get_api or return;

    my $s;
    (async sub { $s = await $sa->get_sermon(122201427568190) })->()->wait;

    subtest series => sub {
        my $series = $s->series;
        is $series->earliest->ymd, '2019-10-21', 'series.earliest';
        ok $series->latest->ymd ge '2020-02-26', 'series.latest';
        is $series->series_id, 103307, 'series_id';
        is $series->title, 'Romans', 'series.title';
        is $series->updated->epoch, 1583168529, 'series.updated';
        is $series->broadcaster_id, 'orpc', 'series.broadcaster_id';
        ok $series->count >= 23, 'series.count';
    };

    subtest 'broadcaster' => sub {
        my $b = $s->broadcaster;
        is $b->latitude, '45.3697088', 'latitude';
        is $b->address, "Ottawa Reformed Presbyterian Church\n466 Woodland Ave\nOttawa, Ontario, Canada", 'address';
        is $b->minister, 'Rev. Dr. Andrew Quigley', 'minister';
        ok $b->service_times_are_preformatted, 'service_times_are_preformatted';
        is $b->phone, '613-596-5566', 'phone';
        is $b->longitude, '-75.776312', 'latitude';
        ok $b->can_webcast, 'can_webcast';
        is $b->display_name, 'Ottawa Reformed Presbyterian Church', 'display_name';
        is $b->facebook_username, 'OttawaRPC', 'facebook_username';
        is $b->id_code, '32774', 'id_code';
        ok !$b->vacant_pulpit, 'vacant_pulpit';
        is $b->location, 'Ottawa, Ontario', 'location';
        is $b->image_url, 'https://media.sermonaudio.com/gallery/photos/sources/orpc.jpg', 'image_url';
        is $b->home_page_url, 'http://www.rpcottawa.org', 'home_page_url';
        is $b->denomination, 'RPCNA', 'denomination';
        is $b->album_art_url_format, 'https://vps.sermonaudio.com/resize_image/sources/podcast/{size}/{size}/orpc.jpg', 'album_art_url_format';
        is $b->broadcaster_id, 'orpc', 'broadcaster_id';
        like $b->service_times, qr/Sunday/, 'service_times';
        ok defined $b->about_us && length($b->about_us) > 0, 'about_us';
        is $b->short_name, 'Ottawa Reformed Presbyterian', 'short_name';
    };

    subtest speaker => sub {
        my $sp = $s->speaker;
        is $sp->display_name, 'Andrew Quigley', 'display_name';
        ok defined $sp->bio && length($sp->bio) >= 1, 'bio';
        is $sp->sort_name, 'Quigley, Andrew', 'sort_name';
        is $sp->portrait_url->to_string, 'https://media.sermonaudio.com/gallery/photos/quigley-01.jpg', 'portrait_url';
        is $sp->album_art_url_format, 'https://vps.sermonaudio.com/resize_image/speakers/podcast/{size}/{size}/quigley-01.jpg', 'album_art_url_format';
        is $sp->rounded_thumbnail_image_url->to_string, 'https://media.sermonaudio.com/gallery/photos/thumbnails/quigley-01.PNG', 'rounded_thumbnail_image_url';
    };

    subtest media => sub {
        my $media = $s->media;
        is scalar($media->audio->@*), 2, 'audio media';
        is scalar($media->video->@*), 0, 'video media';
        is scalar($media->text->@*), 0, 'text media';

        my $m16 = (grep { $_->bitrate == 16 } $media->audio->@*)[0];

        isa_ok $m16, 'Net::SermonAudio::Model::Media', '16 kbit version exists';
        ok !$m16->is_adaptive, 'is_adaptive';
        ok !$m16->is_live, 'is_live';
        is $m16->media_type, 'mp3', 'media_type';
        is $m16->stream_url->to_string, 'https://mp3.sermonaudio.com/16kbps/122201427568190/122201427568190.mp3', 'stream_url';
        is $m16->download_url->to_string, 'https://mp3.sermonaudio.com/16kbps/122201427568190/122201427568190.mp3', 'download_url';
        is $m16->duration, 2787, 'duration';

        my $m34 = (grep { $_->bitrate == 34 } $media->audio->@*)[0];
        isa_ok $m34, 'Net::SermonAudio::Model::Media', '34 kbit version exists';
        ok !$m34->is_adaptive, 'is_adaptive';
        ok !$m34->is_live, 'is_live';
        is $m34->media_type, 'mp3', 'media_type';
        is $m34->stream_url->to_string, 'https://mp3.sermonaudio.com/filearea/122201427568190/122201427568190.mp3', 'stream_url';
        is $m34->download_url->to_string, 'https://mp3.sermonaudio.com/filearea/122201427568190/122201427568190.mp3', 'download_url';
        is $m34->duration, 2787, 'duration';
    };

    is $s->subtitle, 'Romans', 'subtitle';
    is $s->language_code, 'en', 'language_code';
    is $s->full_title, 'Obedience To Faith!', 'full_title';
    is $s->display_event_type, 'Sunday - PM', 'display_event_type';
    is $s->video_download_count, 0, 'video_download_count';
    ok defined $s->download_count && $s->download_count >= 250, 'download_count';
    # TODO: external_link undef
    is $s->preach_date, '2020-01-19', 'preach_date';
    ok defined $s->keywords && ref $s->keywords eq 'ARRAY', 'keywords';
    is $s->document_download_count, 0, 'document_download_count';
    is $s->publish_timestamp->epoch, 1579703794, 'publish_timestamp';
    is $s->event_type, 'Sunday - PM', 'event_type';
    is $s->sermon_id, '122201427568190', 'sermon_id';
    is $s->bible_text, 'John 15; Romans 1:1-6', 'bible_text';
    is $s->display_title, 'Obedience To Faith!', 'display_title';
    is $s->update_date->epoch, 1579991075, 'update_date';

    # TODO: test keywords with a sermon that has some
}

1;