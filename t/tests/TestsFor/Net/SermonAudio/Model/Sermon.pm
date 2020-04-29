package Sermon;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Mojo::JSON qw(decode_json);

use experimental 'signatures';
no warnings 'experimental';

use parent 'Test::Class';

my $test_json = '{"bibleText":"Mark 2:3; Luke 3:1-4:2","broadcaster":{"aboutUs":"The Russell Reformed Presbyterian Church is a member congregation of the Reformed Presbyterian Church of North America. The Reformed Presbyterian Church is a fellowship of Christians who humbly accept God\'s gracious gift of eternal life through Jesus Christ, His Son.","address":"Ecole St-Joseph\\n1008 North Russell Road\\nRussell, ON\\nK4R 1C8","albumArtURL":"https://vps.sermonaudio.com/resize_image/sources/podcast/{size}/{size}/russellrp.jpg","bibleVersion":null,"broadcasterID":"russellrp","canWebcast":true,"country":"Canada","countryISOCode":"CA","denomination":"RPCNA","displayName":"Russell Reformed Presbyterian Church","facebookUsername":null,"homePageURL":"http://russellrpc.org","idCode":"24966","imageURL":"https://media.sermonaudio.com/gallery/photos/sources/russellrp.jpg","latitude":45.2650059,"listenLineNumber":null,"location":"Russell, Ontario","longitude":-75.3638464,"minister":"Matthew Kingswood","phone":"613-408-7002","serviceTimes":"10 AM Sunday Morning Worship\\n6 PM  Sunday Evening Worship","serviceTimesArePreformatted":false,"shortName":"Russell Reformed Presbyterian","twitterUsername":null,"type":"broadcaster","vacantPulpit":false,"webcastInProgress":false,"welcomeVideoID":null},"displayEventType":"Sunday - AM","displayTitle":"Display Title","documentDownloadCount":0,"downloadCount":0,"eventType":"Sunday - AM","externalLink":null,"fullTitle":"Test Sermon","keywords":null,"languageCode":"en","media":{"audio":[],"text":[],"type":"media_set","video":[]},"moreInfoText":"more info test","pickDate":null,"preachDate":"2020-02-03","publishDate":null,"publishTimestamp":null,"series":{"broadcasterID":"russellrp","count":0,"earliest":null,"latest":null,"seriesID":123027,"title":"Test Series","type":"series","updated":1588185359},"sermonID":"429201849131699","speaker":{"albumArtURL":"https://vps.sermonaudio.com/resize_image/speakers/podcast/{size}/{size}/quigley-01.jpg","bio":"Having served as a minister in Scotland for 24 years, Rev. Quigley is now minister of the Ottawa RP Church in Canada.","displayName":"Andrew Quigley","mostRecentPreachDate":null,"portraitURL":"https://media.sermonaudio.com/gallery/photos/quigley-01.jpg","roundedThumbnailImageURL":"https://media.sermonaudio.com/gallery/photos/thumbnails/quigley-01.PNG","sortName":"Quigley, Andrew","type":"speaker"},"subtitle":"Test Series","type":"sermon","updateDate":1588186153,"videoDownloadCount":0}';
my $test_keywords = '{"bibleText":"Genesis 1:1","broadcaster":{"aboutUs":"The Russell Reformed Presbyterian Church is a member congregation of the Reformed Presbyterian Church of North America. The Reformed Presbyterian Church is a fellowship of Christians who humbly accept God\'s gracious gift of eternal life through Jesus Christ, His Son.","address":"Ecole St-Joseph\\n1008 North Russell Road\\nRussell, ON\\nK4R 1C8","albumArtURL":"https://vps.sermonaudio.com/resize_image/sources/podcast/{size}/{size}/russellrp.jpg","bibleVersion":null,"broadcasterID":"russellrp","canWebcast":true,"country":"Canada","countryISOCode":"CA","denomination":"RPCNA","displayName":"Russell Reformed Presbyterian Church","facebookUsername":null,"homePageURL":"http://russellrpc.org","idCode":"24966","imageURL":"https://media.sermonaudio.com/gallery/photos/sources/russellrp.jpg","latitude":45.2650059,"listenLineNumber":null,"location":"Russell, Ontario","longitude":-75.3638464,"minister":"Matthew Kingswood","phone":"613-408-7002","serviceTimes":"10 AM Sunday Morning Worship\\n6 PM  Sunday Evening Worship","serviceTimesArePreformatted":false,"shortName":"Russell Reformed Presbyterian","twitterUsername":null,"type":"broadcaster","vacantPulpit":false,"webcastInProgress":false,"welcomeVideoID":null},"displayEventType":"Sunday - PM","displayTitle":"Display Title 2","documentDownloadCount":0,"downloadCount":0,"eventType":"Sunday - PM","externalLink":null,"fullTitle":"Test Sermon 2","keywords":"abc 123","languageCode":"fr","media":{"audio":[],"text":[],"type":"media_set","video":[]},"moreInfoText":"more info text 2","pickDate":null,"preachDate":"2019-01-02","publishDate":null,"publishTimestamp":null,"series":{"broadcasterID":"russellrp","count":0,"earliest":null,"latest":null,"seriesID":123039,"title":"Test Series 2","type":"series","updated":1588196948},"sermonID":"429202157166200","speaker":{"albumArtURL":"https://vps.sermonaudio.com/resize_image/speakers/podcast/{size}/{size}/generic.jpg","bio":null,"displayName":"Pastor Matt Kingswood","mostRecentPreachDate":null,"portraitURL":"https://media.sermonaudio.com/gallery/photos/generic.jpg","roundedThumbnailImageURL":"https://media.sermonaudio.com/gallery/photos/thumbnails/generic.PNG","sortName":"Kingswood, Matt","type":"speaker"},"subtitle":"Test Series 2","type":"sermon","updateDate":1588197437,"videoDownloadCount":0}';

sub parse :Tests ($self) {
    my $json = decode_json $test_json;
    my $sermon = Net::SermonAudio::Model::Sermon->parse($json);

    my $create_params = {
        accept_copyright => 1,
        full_title       => 'Test Sermon',
        speaker_name     => 'Andrew Quigley',
        preach_date      => Date::Tiny->new(year => 2020, month => 2, day => 3),
        event_type       => 'Sunday - AM',
        display_title    => 'Display Title',
        subtitle         => 'Test Series',
        bible_text       => 'Mark 2:3; Luke 3:1-4:2',
        more_info_text   => 'more info test',
        language_code    => 'en',
    };

    is $sermon->$_, $create_params->{$_}, $_ for qw(full_title event_type display_title subtitle bible_text more_info_text language_code);
    is $sermon->speaker->display_name, 'Andrew Quigley', 'speaker_name';
    is $sermon->preach_date->ymd, '2020-02-03', 'preach_date';
    is $sermon->series->title, 'Test Series', 'series.title';
    is_deeply $sermon->keywords, [], 'keywords';

    $sermon = Net::SermonAudio::Model::Sermon->parse(decode_json $test_keywords);
    is_deeply $sermon->keywords, ['abc', '123'], 'parse additional keywords';
}

1;
