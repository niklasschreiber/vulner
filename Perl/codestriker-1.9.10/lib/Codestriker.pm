###############################################################################
# Codestriker: Copyright (c) 2001, 2002 David Sitsky.  All rights reserved.
# sits@users.sourceforge.net
#
# This program is free software; you can redistribute it and modify it under
# the terms of the GPL.

# Main package which contains a reference to all configuration variables.

package Codestriker;

use strict;
use Encode;
use Config;

use Time::Local;
use IPC::Open3;
use File::Temp qw/ tempdir /;
use File::Path;
use Fatal qw / open close waitpid /;
use MIME::QuotedPrint qw(encode_qp);
use Net::SMTP;
use MIME::Base64;
use Sys::Hostname;
use Encode qw(encode);

# Export codestriker.conf configuration variables.
use vars qw ( $mailhost $mailuser $mailpasswd $mailreplyto $listid
          $use_compression $gzip $cvs $svn $ssh $p4 $vss $bugtracker
          @valid_repositories $default_topic_create_mode $default_tabwidth
          $file_reviewer $db $dbuser $dbpasswd $codestriker_css
          $NORMAL_MODE $COLOURED_MODE $COLOURED_MONO_MODE $topic_states
          $bug_db $bug_db_host $bug_db_name $bug_db_password $bug_db_user
          $lxr_map $email_send_options
          $allow_delete $allow_searchlist $default_file_to_view
          $allow_projects $antispam_email $VERSION $title $BASEDIR
          $metric_config $tmpdir @metric_schema $comment_state_metrics
          $project_states $rss_enabled
          $repository_name_map $repository_url_map
          @valid_repository_names $topic_text_encoding $cgi_style
           );

# Version of Codestriker.
$Codestriker::VERSION = "1.9.10";

# Default title to display on each Codestriker screen.
$Codestriker::title = "Codestriker $Codestriker::VERSION";

# The maximum size of a diff file to accept.  At the moment, this is 20Mb.
$Codestriker::DIFF_SIZE_LIMIT = 20000 * 1024;

# Indicate what base directory Codestriker is running in.  This may be set
# in cgi-bin/codestriker.pl, depending on the environment the script is
# running in.  By default, assume the script is running in the cgi-bin
# directory (this is not the case for Apache2 + mod_perl).
$Codestriker::BASEDIR = "..";

# Error codes.
$Codestriker::OK = 1;
$Codestriker::STALE_VERSION = 2;
$Codestriker::INVALID_TOPIC = 3;
$Codestriker::INVALID_PROJECT = 4;
$Codestriker::DUPLICATE_PROJECT_NAME = 5;
$Codestriker::UNSUPPORTED_OPERATION = 6;
$Codestriker::DIFF_TOO_BIG = 7;
$Codestriker::LISTENER_ABORT = 8;

# Revision number constants used in the filetable with special meanings.
$Codestriker::ADDED_REVISION = "1.0";
$Codestriker::REMOVED_REVISION = "0.0";
$Codestriker::PATCH_REVISION = "0.1";

# Participant type constants.
$Codestriker::PARTICIPANT_REVIEWER = 0;
$Codestriker::PARTICIPANT_CC = 1;

# Default email context to use.
$Codestriker::EMAIL_CONTEXT = 8;

# Valid comment states, the only one that is special is the submitted state.
$Codestriker::COMMENT_SUBMITTED = 0;

# Day strings
@Codestriker::days = ("Sunday", "Monday", "Tuesday", "Wednesday", "Thursday",
              "Friday", "Saturday");

# Month strings
@Codestriker::months = ("January", "February", "March", "April", "May", "June",
            "July", "August", "September", "October", "November",
            "December");

# Short day strings
@Codestriker::short_days = ("Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat");

# Short month strings
@Codestriker::short_months = ("Jan", "Feb", "Mar", "Apr", "May", "Jun",
                  "Jul", "Aug", "Sep", "Oct", "Nov", "Dec");

$metric_config = "";

# name => The short name of the metric. This name will be used in the
# SQL table, in the data download, in the input tables, and perhaps in
# the .conf file.
#
# description => The long description of the item. Displayed as online help (?)
#
# enabled => If 1, the metrics are enabled by default in "basic"
# configs. Otherwise the $metric_config option on the .conf will
# override this.
#
# scope => This will be "topic", "reviewer", "author".  A "topic"
# metric that has a 1 to 1 relationship with the topic itself.  If it
# is not a topic metric, it is a kind of user metric. User metrics have
# a 1-1 relationship with each user in the topic. If the type is
# reviewer, it is only needed by a user that is a reviewer (but not
# author), of the topic. If the type is author, it is only needed by
# the author of the metric, and if it is participants, it is needed by
# all users regardless of the role.
#
# filter => The type of data being stored. "hours" or "count". Data
# will not be stored to the database if it does not pass the format
# expected for the filter type.

my @metrics_schema =
  (
   # planning time
   {
    name=>"entry time",
    description=>"Work hours spent by the inspection leader to check that entry conditions are met, and to work towards meeting them.",
    enabled=>0,
    scope=>"author",
    filter=>"hours"
   },
   {
    name=>"kickoff time",
    description=>"Total work hours used per individual for the kickoff meeting and for planning of the kickoff meeting.",
    scope=>"participant",
    enabled=>1,
    filter=>"hours"
   },
   {
    name=>"planning time",
    description=>"Total work hours used to create the inspection master plan.",
    scope=>"author",
    enabled=>0,
    filter=>"hours"
   },

   # checking time
   {
    name=>"checking time",
    description=>"The total time spent checking the topic.",
    scope=>"participant",
    enabled=>1,
    filter=>"hours"
   },
   {
    name=>"lines studied",
    description=>"The number of lines which have been closly scrutinized at or near optimum checking rate.",
    scope=>"participant",
    enabled=>0,
    filter=>"count"
   },
   {
    name=>"lines scanned",
    description=>"The number of lines which have been looked at higher then the optimum checking rate.",
    scope=>"participant",
    enabled=>0,
    filter=>"count"
   },
   {
    name=>"studied time",
    description=>"The time in hours spent closely scrutinized at or near optimum checking rate.",
    scope=>"participant",
    enabled=>0,
    filter=>"hours"
   },
   {
    name=>"scanned time",
    description=>"The time in hours spent looking at the topic at higher then the optimum checking rate.",
    scope=>"participant",
    enabled=>0,
    filter=>"hours"
   },

   # logging meeting time.
   {
    name=>"logging meeting duration",
    description=>"The wall clock time of the logging meeting.",
    scope=>"topic",
    enabled=>1,
    filter=>"hours"
   },
   {
    name=>"logging meeting logging duration",
    description=>"The wall clock time spent reporting issues and searching for new issues.",
    scope=>"topic",
    enabled=>0,
    filter=>"hours"
   },
   {
    name=>"logging meeting discussion duration",
    description=>"The wall clock time spent not reporting issues and searching for new issues.",
    scope=>"topic",
    enabled=>0,
    filter=>"hours"
   },
   {
    name=>"logging meeting logging time",
    description=>"The total time spent reporting issues and searching for new issues.",
    scope=>"participant",
    enabled=>0,
    filter=>"hours"
   },
   {
    name=>"logging meeting discussion time",
    description=>"The total time spent not reporting issues and searching for new issues.",
    scope=>"participant",
    enabled=>0,
    filter=>"hours"
   },
   ,
   {
    name=>"logging meeting new issues logged",
    description=>"The total number of issues that were not noted before the meeting and found during the meeting.",
    scope=>"topic",
    enabled=>0,
    filter=>"count"
   },

   # editing

   {
    name=>"edit time",
    description=>"The total time spent editing all items.",
    scope=>"author",
    enabled=>0,
    filter=>"hours"
   },
   {
    name=>"follow up time",
    description=>"The total time spent by the leader to check exit criteria and do exit activities.",
    scope=>"author",
    enabled=>0,
    filter=>"hours"
   },

   {
    name=>"exit time",
    description=>"The total time spent by the leader to check exit criteria and do exit activities.",
    scope=>"author",
    enabled=>0,
    filter=>"hours"
   },

   {
    name=>"correct fix rate",
    description=>"The percentage of edit corrections attempts with correct fix a defect and not introduce new defects.",
    scope=>"author",
    enabled=>0,
    filter=>"percent"
   },

  );

# Return the schema for the codestriker metric support. It insures that the
# settings in the conf file are applied to the schema.
sub get_metric_schema {

    # Make each of the metrics schema's are enabled according to the .conf file.
    foreach my $metric (@metrics_schema) {
        if ((! defined $metric_config) || $metric_config eq "" ||
            $metric_config eq "none") {
            $metric->{enabled} = 0;
        } elsif ($metric_config eq "basic") {
            # Leave the default enabled values.
        } elsif ($metric_config eq "all") {
            $metric->{enabled} = 1;
        } else {
            # Make sure it matches the entire thing.
            my $regex = "(^|,)$metric->{name}(,|\$)";

            if ($metric_config =~ /$regex/) {
                $metric->{enabled} = 1;
            } else {
                $metric->{enabled} = 0;
            }
        }

        # This metric is not a "built it" metric. Meaning that it
        # comes out of the db, rather than being generated on the fly
        # from other parts of the db (like the topic history).
        $metric->{builtin} = 0;
    }

    return @metrics_schema;
}

# Initialise codestriker, by loading up the configuration file and exporting
# those values to the rest of the system.
sub initialise($$) {
    my ($type, $basedir) = @_;

    $BASEDIR = $basedir;

    # Load up the configuration file.
    my $config = "$BASEDIR/codestriker.conf";
    if (-f $config) {
        do $config;
    } else {
        die("Couldn't find configuration file: \"$config\".\n<BR>" .
            "Please fix the \$config setting in codestriker.pl.");
    }

    # look for the extra file for the test scripts.
    if ( -f "$BASEDIR/codestriker_test.conf") {
        do "$BASEDIR/codestriker_test.conf";
    }

    # Fill in $repository_name_map for those repository entries which don't have
    # a mapping, with the same value as the repository value itself.
    foreach my $repository (@valid_repositories) {
        if (! exists $repository_name_map->{$repository}) {
            $repository_name_map->{$repository} = $repository;
        }
    }

    # Define the equivalent list of valid repository names.
    @valid_repository_names = ();
    foreach my $repository (@valid_repositories) {
        push @valid_repository_names, $repository_name_map->{$repository};
    }

    # Define the reverse mapping now for convenience.
    foreach my $key (keys %${repository_name_map}) {
        $repository_url_map->{$repository_name_map->{$key}} = $key;
    }
}

# Determine if we are running under Windows.
sub is_windows() {
    my $osname = $Config{'osname'};
    return defined $osname && $osname eq "MSWin32";
}

# Returns the current time in a format suitable for a DBI timestamp value.
sub get_timestamp($$) {
    my ($type, $time) = @_;
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
      localtime($time);
    $year += 1900;

    return sprintf("%04d-%02d-%02d %02d:%02d:%02d", $year, $mon+1, $mday,
                   $hour, $min, $sec);
}

# Given a database formatted timestamp, output it in a human-readable form.
sub format_timestamp($$) {
    my ($type, $timestamp) = @_;

    if ($timestamp =~ /(\d\d\d\d)\-(\d\d)\-(\d\d) (\d\d):(\d\d):(\d\d)/ ||
        $timestamp =~ /(\d\d\d\d)(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)/) {
        my $time_value = Time::Local::timelocal($6, $5, $4, $3, $2-1, $1);
        my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
          localtime($time_value);
        $year += 1900;
        return sprintf("$Codestriker::days[$wday] " .
                       "$Codestriker::months[$mon] $mday, $year %02d:%02d:%02d ",
                       $hour, $min, $sec);
    } else {
        return $timestamp;
    }


# Given a database formatted timestamp, output it in a short,
# human-readable form.
sub format_short_timestamp($$) {
    my ($type, $timestamp) = @_;

    if ($timestamp =~ /(\d\d\d\d)\-(\d\d)\-(\d\d) (\d\d):(\d\d):(\d\d)/ ||
        $timestamp =~ /(\d\d\d\d)(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)/) {
        my $time_value = Time::Local::timelocal($6, $5, $4, $3, $2-1, $1);
        my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
          localtime($time_value);
        $year += 1900;
        return sprintf("%02d:%02d:%02d $Codestriker::short_days[$wday], " .
                       "$mday $Codestriker::short_months[$mon], $year",
                       $hour, $min, $sec);
    } else {
        return $timestamp;
    }
}

# Given a database formatted timestamp, output it in a short,
# human-readable date only form.
sub format_date_timestamp($$) {
    my ($type, $timestamp) = @_;

    if ($timestamp =~ /(\d\d\d\d)\-(\d\d)\-(\d\d) (\d\d):(\d\d):(\d\d)/ ||
        $timestamp =~ /(\d\d\d\d)(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)/) {
        my $time_value = Time::Local::timelocal($6, $5, $4, $3, $2-1, $1);
        my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) =
          localtime($time_value);
        $year += 1900;
        return "$Codestriker::short_days[$wday] $Codestriker::short_months[$mon] $mday, $year";
    } else {
        return $timestamp;
    }
}

# Given a database formatted timestamp, return the time as a time_t. The
# number of seconds since the baseline time of the system.
sub convert_date_timestamp_time($$) {
    my ($type, $timestamp) = @_;

    if ($timestamp =~ /(\d\d\d\d)\-(\d\d)\-(\d\d) (\d\d):(\d\d):(\d\d)/ ||
        $timestamp =~ /(\d\d\d\d)(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)/) {
        return Time::Local::timelocal($6, $5, $4, $3, $2-1, $1);
    } else {
        print STDERR "Unable to convert timestamp \"$timestamp\" to time_t.\n";
        return 0;
    }
}


# Given an email string, replace it in a non-SPAM friendly form.
# sits@users.sf.net -> sits@us...
sub make_antispam_email($$) {
    my ($type, $email) = @_;

    $email =~ s/([0-9A-Za-z\._]+@[0-9A-Za-z\._]{3})[0-9A-Za-z\._]+/$1\.\.\./g;
    return "$email";
}

sub filter_email {
    my ($type, $email) = @_;

    if ($Codestriker::antispam_email) {
        $email = $type->make_antispam_email($email);
    }

    return $email;
}

# Pass in two collections of string, it will return the elements in
# the string that were added and where removed. All 4 params are
# references to lists. Mainly used to compare lists of reviewers and
# cc.
sub set_differences($$$$)
  {
      my ($list1_r, $list2_r, $added, $removed) = @_;

      my @list1 = sort @$list1_r;
      my @list2 = sort @$list2_r;

      my $new_index = 0;
      my $old_index = 0;
      while ($new_index < @list1 || $old_index < @list2) {
          my $r = 0;

          if ($new_index < @list1 && $old_index < @list2) {
              $r = $list1[$new_index] cmp $list2[$old_index];
          } elsif ($new_index < @list1) {
              $r = -1;
          } else {
              $r = 1;
          }

          if ($r == 0) {
              ++$new_index;
              ++$old_index;

          } elsif ($r < 0) {
              push(@$added, $list1[$new_index]);
              ++$new_index;
          } else {
              push(@$removed, $list2[$old_index]);
              ++$old_index;
          }
      }
  }
}

# Return true if project support has been enabled.
sub projects_disabled {
    if (defined @Codestriker::project_states) {
        return $#Codestriker::project_states == -1;
    } elsif (defined $Codestriker::allow_projects) {
        # Support for older codestriker.conf files.
        if ($Codestriker::allow_projects) {
            $Codestriker::project_states = ('Open');
        }
        return $Codestriker::allow_projects == 0;
    } else {
        # Don't support projects if none of the above are defined.
        return 1;
    }
}

# Return true if there is more than one state associated with a project.
sub project_state_change_enabled {
    return $#Codestriker::project_states > 0;
}

# Returns true if the given topic is 'readonly', i.e. if the given topic
# status is in the list of readonly_states in codestriker.conf.
sub topic_readonly {
    my ($topic_state) = @_;
    if (defined @Codestriker::readonly_states) {
        return (grep /^$topic_state$/, @Codestriker::readonly_states);
    } else {
        # Backwards compatibility for older configs.
        return $topic_state eq "Open" ? 0 : 1;
    }
}

# Decode the passed in string into UTF8.
sub decode_topic_text {
    my ($string) = @_;

    # Assume input text is set to UTF8 by default, unless
    # it has been explicitly over-ridden in the codestriker.conf file.
    if ((! defined $Codestriker::topic_text_encoding) ||
        $Codestriker::topic_text_encoding eq '') {
        $Codestriker::topic_text_encoding = 'utf8';
    }

    return decode($Codestriker::topic_text_encoding, $string);
}

# Function for running an external command, and handles the subtle
# issues for different web servers environments.
sub execute_command {
    my $stdout_fh = shift;
    my $stderr_fh = shift;
    my $command = shift;
    my @args = @_;

    # Write error messages to STDERR if the file handle for error messages
    # is not defined.
    $stderr_fh = \*STDERR unless defined $stderr_fh;

    my $command_tmpdir;
    eval {
        if (exists $ENV{'MOD_PERL'} ||
            (defined($ENV{'SERVER_SOFTWARE'}) && $ENV{'SERVER_SOFTWARE'} =~ /IIS/)) {
            # The open3() call doesn't work under mod_perl/apache2,
            # so create a command which stores the stdout and stderr
            # into temporary files.  It also seems flacky under IIS.
            if (defined $Codestriker::tmpdir && $Codestriker::tmpdir ne "") {
                $command_tmpdir = tempdir(DIR => $Codestriker::tmpdir);
            } else {
                $command_tmpdir = tempdir();
            }

            # Build up the command string with naive quoting.
            my $command_line = "\"$command\"";
            foreach my $arg (@args) {
                $command_line .= " \"$arg\"";
            }

            my $stdout_filename = "$command_tmpdir/stdout.txt";
            my $stderr_filename = "$command_tmpdir/stderr.txt";

            # Thankfully this works under Windows.
            my $system_line =
              "$command_line > \"$stdout_filename\" 2> \"$stderr_filename\"";
            system($system_line) == 0 ||
              croak "Failed to execute $system_line: $!\n";

            open(TMP_STDOUT, $stdout_filename);
            binmode TMP_STDOUT;
            while (<TMP_STDOUT>) {
                print $stdout_fh $_;
            }

            open(TMP_STDERR, $stderr_filename);
            binmode TMP_STDERR;
            while (<TMP_STDERR>) {
                print $stderr_fh $_;
            }

            close TMP_STDOUT;
            close TMP_STDERR;
        } else {
            my $write_stdin_fh = new FileHandle;
            my $read_stdout_fh = new FileHandle;
            my $read_stderr_fh = new FileHandle;

            my $pid = open3($write_stdin_fh, $read_stdout_fh, $read_stderr_fh,
                            $command, @args);

            # Ideally, we should use IO::Select, but that is broken on Win32.
            # This is not ideal, but read first from stdout.  If that is empty,
            # then an error has occurred, and that can be read from stderr.
            my $buf = "";
            while (read($read_stdout_fh, $buf, 16384)) {
                print $stdout_fh $buf;
            }
            while (read($read_stderr_fh, $buf, 16384)) {
                print $stderr_fh $buf;
            }

            # Wait for the process to terminate.
            waitpid($pid, 0);
        }
    }
      ;
    my $exception = $@;

    # Make sure the temporary directory is removed if it was created.
    if (defined $command_tmpdir) {
        rmtree($command_tmpdir);
    }

    if ($exception) {
        croak("Command failed: $@\n",
              "$command " . join(' ', @args) . "\n",
              "Check your webserver error log for more information.\n");
    }

    # Flush the output file handles.
    $stdout_fh->flush;
    $stderr_fh->flush;
}

# Replace the passed in string with the correct number of spaces, for
# alignment purposes.
sub tabadjust ($$$) {
    my ($tabwidth, $input, $htmlmode) = @_;

    $_ = $input;
    if ($htmlmode) {
        1 while s/\t+/'&nbsp;' x
          (length($&) * $tabwidth - length($`) % $tabwidth)/eo;
    } else {
        1 while s/\t+/' ' x
          (length($&) * $tabwidth - length($`) % $tabwidth)/eo;
    }
    return $_;
}


# Send an email with the specified data.
sub send_email {
    my ($type, %args) = @_;

    my $smtp = Net::SMTP->new($Codestriker::mailhost);
    defined $smtp || return "Unable to connect to mail server: $!";

    # Perform SMTP authentication if required.
    if (defined $Codestriker::mailuser && $Codestriker::mailuser ne "" &&
        defined $Codestriker::mailpasswd) {
        eval 'use Authen::SASL';
        die "Unable to load Authen::SASL module: $@\n" if $@;
        $smtp->auth($Codestriker::mailuser, $Codestriker::mailpasswd);
    }

    # Use Codestriker::daemon_email_address as the sender if it is
    # defined.
    my $sender = $args{from};
    if (defined $Codestriker::daemon_email_address &&
        $Codestriker::daemon_email_address ne '') {
        $sender = $Codestriker::daemon_email_address;
    }

    $smtp->mail($sender);
    $smtp->ok() || return "Couldn't set sender to \"$sender\" $!, " .
      $smtp->message();

    # $to has to be defined.
    my $recipients = $args{to};
    $recipients .= ", $args{cc}" if $args{cc} ne "";
    $recipients .= ", $args{bcc}" if $args{bcc} ne "";
    my @receiver = split /, /, $recipients;
    for (my $i = 0; $i <= $#receiver; $i++) {
        if ($receiver[$i] ne "") {
            $smtp->recipient($receiver[$i]);
            $smtp->ok() || return "Couldn't send email to \"$receiver[$i]\" $!, " .
              $smtp->message();
        } else {
            # Can't track down why, but sometimes an empty email address
            # pops into here and kills the entire thing. This makes the
            # problem go away.
        }
    }

    $smtp->data();
    $smtp->datasend("From: $args{from}\n");
    $smtp->datasend("To: $args{to}\n");
    $smtp->datasend("Cc: $args{cc}\n") if $args{cc} ne "";

    # If the message is new, create the appropriate message id, otherwise
    # construct a message which refers to the original message.  This will
    # allow for threading, for those email clients which support it.  All
    # emails relating to a specific comment will be in a specific thread.
    if (defined $args{topicid} && defined $args{fileline} &&
        defined $args{filenumber} && defined $args{filenew}) {
        my $message_id =
          "<Codestriker.$args{topicid}.$args{fileline}.$args{filenumber}.$args{filenew}\@" .
            hostname() . '>';

        if (defined $args{new} && $args{new}) {
            $smtp->datasend("Message-Id: $message_id\n");
        } else {
            $smtp->datasend("References: $message_id\n");
            $smtp->datasend("In-Reply-To: $message_id\n");
        }
    }

    # Set the List-Id header if required.
    if (defined $Codestriker::listid && $Codestriker::listid ne '') {
        $smtp->datasend("List-Id: " . $Codestriker::listid . "\n");
    }

    # Set the Reply-To header if required.
    if (defined $Codestriker::mailreplyto && $Codestriker::mailreplyto ne '') {
        $smtp->datasend("Reply-To: " . $Codestriker::mailreplyto . "\n");
    }

    # Make sure the subject is appropriately encoded to handle UTF-8
    # characters.
    my $subject = encode_qp(encode("UTF-8", $args{subject}), "");

    # RFC 2047 fixup that is a documented deviation from quoted-printable
    $subject =~ s/\?/=3F/g;
    $subject =~ s/_/=5F/g;
    $subject =~ s/ /_/g;
    $smtp->datasend("Subject: =?UTF-8?Q?${subject}?=\n");

    # Set the content type to be text/plain with UTF8 encoding, to handle
    # unicode characters.
    $smtp->datasend("Content-Type: text/plain; charset=\"utf-8\"\n");
    $smtp->datasend("Content-Transfer-Encoding: quoted-printable\n");
    $smtp->datasend("MIME-Version: 1.0\n");

    # Insert a blank line for the body.
    $smtp->datasend("\n");

    # Encode the mail body using quoted-printable to handle unicode
    # characters.
    $smtp->datasend(encode_qp(encode("UTF-8", $args{body})));
    $smtp->dataend();
    $smtp->ok() || return "Couldn't send email $!, " . $smtp->message();

    $smtp->quit();
    $smtp->ok() || return "Couldn't send email $!, " . $smtp->message();

    return '';
}

1;

