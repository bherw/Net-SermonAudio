package Net::SermonAudio::Types;
use strict;
use warnings;
use Type::Library -base;
use Types::Standard qw(Enum Maybe Str);

__PACKAGE__->add_type(
    name   => 'MediaClass',
    parent => Enum[qw(audio video text all)],
);

__PACKAGE__->add_type(
    name   => 'MediaType',
    parent => Enum[qw(mp3 aac mp4 pdf doc transcript jpg orig-audio orig-video)],
);

__PACKAGE__->add_type
    (
        name   => 'SermonEventType',
        parent => Enum [
            "Audio Book",
            "Bible Study",
            "Camp Meeting",
            "Chapel Service",
            "Children",
            "Classic Audio",
            "Conference",
            "Current Events",
            "Debate",
            "Devotional",
            "Funeral Service",
            "Midweek Service",
            "Podcast",
            "Prayer Meeting",
            "Question & Answer",
            "Radio Broadcast",
            "Sermon Clip",
            "Special Meeting",
            "Sunday Afternoon",
            "Sunday - AM",
            "Sunday - PM",
            "Sunday School",
            "Sunday Service",
            "Teaching",
            "Testimony",
            "TV Broadcast",
            "Video DVD",
            "Wedding",
            "Youth",
        ]);

__PACKAGE__->add_type(
    name   => 'SermonSortBy',
    parent => Enum [ qw(downloads event language lastplayed newest oldest pickdate series speaker updated random added title) ],
);

__PACKAGE__->add_type(name => 'MaybeStr', parent => Maybe [ Str ]);

1;