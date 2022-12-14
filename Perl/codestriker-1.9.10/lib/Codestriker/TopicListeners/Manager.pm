###############################################################################
# Codestriker: Copyright (c) 2001, 2002 David Sitsky.  All rights reserved.
# sits@users.sourceforge.net
#
# This program is free software; you can redistribute it and modify it under
# the terms of the GPL.

# Object to create and call all of the lister objects.

use strict;

package Codestriker::TopicListeners::Manager;

use Codestriker::TopicListeners::Email;
use Codestriker::TopicListeners::BugTracking;
use Codestriker::TopicListeners::HistoryRecorder;

my @topic_listeners;

sub topic_pre_create {
    _create_listeners();

    # Call all of the topic listeners that are created. If any of the
    # topic listeners return a non-empty string, it is treated as a
    # request to reject the creation of the new topic.  Display the
    # returned string as the user error message.
    my $returnValue = '';

    foreach my $listener (@topic_listeners) {
        $returnValue .= $listener->topic_pre_create(@_);
        last if length($returnValue);
    }

    return $returnValue;
}

sub topic_create {
    _create_listeners();

    # Call all of the topic listeners that are created. If any of the
    # topic listeners return a non-empty string, it is treated as a
    # request to reject the requested state change, and display the
    # returned string as the user error message.
    my $returnValue = '';

    foreach my $listener (@topic_listeners) {
        $returnValue .= $listener->topic_create(@_);
        last if length($returnValue);
    }

    return $returnValue;
}

sub topic_pre_changed {
    _create_listeners();

    # Call all of the topic listeners that are created. If any of the
    # topic listeners return a non-empty string, it is treated as a
    # request to reject the requested state change, and display the
    # returned string as the user error message.
    my $returnValue = '';

    foreach my $listener (@topic_listeners) {
        $returnValue .= $listener->topic_pre_changed(@_);
        last if length($returnValue);
    }

    return $returnValue;
}

sub topic_changed {
    _create_listeners();

    # Call all of the topic listeners that are created. If any of the
    # topic listeners return a non-empty string, it is treated as a
    # request to reject the requested state change, and display the
    # returned string as the user error message.
    my $returnValue = '';

    foreach my $listener (@topic_listeners) {
        $returnValue .= $listener->topic_changed(@_);
        last if length($returnValue);
    }

    return $returnValue;
}

sub topic_viewed {
    _create_listeners();

    # Call all of the topic listeners that are created. If any of the
    # topic listeners return a non-empty string, it is treated as a
    # request to reject the requested state change, and display the
    # returned string as the user error message.
    my $returnValue = '';

    foreach my $listener (@topic_listeners) {
        $returnValue .= $listener->topic_viewed(@_);
        last if length($returnValue);
    }

    return $returnValue;
}

sub comment_create {
    _create_listeners();

    # Call all of the topic listeners that are created. If any of the
    # topic listeners return a non-empty string, it is treated as a
    # request to reject the requested state change, and display the
    # returned string as the user error message.
    my $returnValue = '';

    foreach my $listener (@topic_listeners) {
        $returnValue .= $listener->comment_create(@_);
        last if length($returnValue);
    }

    return $returnValue;
}

sub comment_state_change {
    _create_listeners();

    # Call all of the topic listeners that are created. If any of the
    # topic listeners return a non-empty string, it is treated as a
    # request to reject the requested state change, and display the
    # returned string as the user error message.
    my $returnValue = '';

    foreach my $listener (@topic_listeners) {
        $returnValue .= $listener->comment_state_change(@_);
        last if length($returnValue);
    }

    return $returnValue;
}

# Private function to create all of the listener objects, and stuff
# them into module variable @topic_listeners.
sub _create_listeners {
    if (scalar(@topic_listeners) == 0) {
        push @topic_listeners,
          Codestriker::TopicListeners::BugTracking->new();

        push @topic_listeners,
          Codestriker::TopicListeners::Email->new();

        push @topic_listeners,
          Codestriker::TopicListeners::HistoryRecorder->new();
    }
}

1;

