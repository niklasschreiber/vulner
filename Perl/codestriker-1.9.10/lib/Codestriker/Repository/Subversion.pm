###############################################################################
# Codestriker: Copyright (c) 2001,2002,2003 David Sitsky.  All rights reserved.
# sits@users.sourceforge.net
#
# This program is free software; you can redistribute it and modify it under
# the terms of the GPL.

# Subversion repository access package.

package Codestriker::Repository::Subversion;
use IPC::Open3;

use strict;
use Fatal qw / open close /;

use Codestriker::Repository;
@Codestriker::Repository::Subversion::ISA = ("Codestriker::Repository");

# Constructor, which takes as a parameter the repository url.
sub new {
    my ($type, $repository_url, $user, $password) = @_;

    # Sanitise the repository URL.
    $repository_url = sanitise_url_component($repository_url);

    # Set the repository string.
    my $repository_string = $repository_url;
    $repository_string .= ";$user" if defined $user;
    $repository_string .= ";$password" if defined $password;
    if ($repository_string !~ /^svn:/) {
        $repository_string = "svn:" . $repository_string;
    }
    my $self = Codestriker::Repository->new($repository_string);
    $self->{repository_url} = $repository_url;

    # Determine if there are additional parameters required for user
    # authentication.
    my @userCmdLine = ();
    if (defined($user) && defined($password)) {
        push @userCmdLine, '--username';
        push @userCmdLine, $user;
        push @userCmdLine, '--password';
        push @userCmdLine, $password;
    }
    $self->{userCmdLine} = \@userCmdLine;

    bless $self, $type;
}

# Sanitise a Subversion URL component, by replacing spaces with %20 and @
# symbols with %40, so that there is no confused with pegged revisions.  Also
# remove any leading and trailing slashes.
sub sanitise_url_component {
    my $url = shift;
    $url =~ s/\/$//;
    $url =~ s/^\///;
    $url =~ s/ /%20/g;
    $url =~ s/\@/%40/g;
    return $url;
}

# Retrieve the data corresponding to $filename and $revision.  Store each line
# into $content_array_ref.
sub retrieve ($$$\$) {
    my ($self, $filename, $revision, $content_array_ref) = @_;

    # Sanitise the filename.
    $filename = sanitise_url_component($filename);

    my $read_data = '';
    my $read_stdout_fh = new FileHandle;
    open($read_stdout_fh, '>', \$read_data);
    my @args = ();
    push @args, 'cat';
    push @args, '--non-interactive';
    push @args, '--no-auth-cache';
    push @args, @{ $self->{userCmdLine} };
    push @args, $self->{repository_url} . '/' . $filename . '@' . $revision;
    Codestriker::execute_command($read_stdout_fh, undef,
                                 $Codestriker::svn, @args);

    # Process the data for the topic.
    open($read_stdout_fh, '<', \$read_data);
    for (my $i = 1; <$read_stdout_fh>; $i++) {
        $_ = Codestriker::decode_topic_text($_);
        chop;
        $$content_array_ref[$i] = $_;
    }
}

# Retrieve the "root" of this repository.
sub getRoot ($) {
    my ($self) = @_;
    return $self->{repository_url};
}

# Given a Subversion URL, determine if it refers to a directory or a file.
sub is_file_url {
    my ($self, $url, $revision) = @_;
    my $file_url;

    eval {
        my @args = ();
        push @args, 'info';
        push @args, '--non-interactive';
        push @args, '--no-auth-cache';
        push @args, @{ $self->{userCmdLine} };
        push @args, '--xml';
        push @args, $self->{repository_url} . '/' . $url . '@' . $revision;
        my $read_data = '';
        my $read_stdout_fh = new FileHandle;
        open($read_stdout_fh, '>', \$read_data);

        Codestriker::execute_command($read_stdout_fh, undef,
                                     $Codestriker::svn, @args);
        open($read_stdout_fh, '<', \$read_data);
        while (<$read_stdout_fh>) {
            if (/kind\s*\=\s*\"(\w+)\"/) {
                $file_url = $1 =~ /^File$/io;
                last;
            }
        }
    };
    if ($@ || !(defined $file_url)) {
        # The above command failed, try using the older method which only works
        # in an English locale.  This supports Subversion 1.2 or earlier
        # releases, which don't support the --xml flag for the info command.
        my @args = ();
        push @args, 'cat';
        push @args, '--non-interactive';
        push @args, '--no-auth-cache';
        push @args, @{ $self->{userCmdLine} };
        push @args, $self->{repository_url} . '/' . $url . '@' . $revision;

        my $read_stdout_data = '';
        my $read_stdout_fh = new FileHandle;
        open($read_stdout_fh, '>', \$read_stdout_data);

        my $read_stderr_data = '';
        my $read_stderr_fh = new FileHandle;
        open($read_stderr_fh, '>', \$read_stderr_data);

        Codestriker::execute_command($read_stdout_fh, $read_stderr_fh,
                                     $Codestriker::svn, @args);
        $file_url = 1;
        open($read_stderr_fh, '<', \$read_stderr_data);
        while (<$read_stderr_fh>) {
            if (/^svn:.* refers to a directory/) {
                $file_url = 0;
                last;
            }
        }
    }

    return $file_url;
}

# The getDiff operation, pull out a change set based on the start and end
# revision number, confined to the specified moduled_name.
sub getDiff {
    my ($self, $start_tag, $end_tag, $module_name, $stdout_fh, $stderr_fh) = @_;

    my $revision;
    my $removed_file = 0;
    if ($start_tag eq "" && $end_tag ne "") {
        $revision = $end_tag;
    } elsif ($start_tag ne "") {
	if ($end_tag eq "") {
	    $revision = $start_tag;
	} elsif ($end_tag eq $Codestriker::REMOVED_REVISION) {
	    # Indicates a removed file.
	    $revision = $start_tag;
	    $removed_file = 1;
	}
    }

    # Sanitise the URL, and determine if it refers to a directory or filename.
    $module_name = sanitise_url_component($module_name);
    my $directory;

    if ($self->is_file_url($module_name, defined $revision ? $revision : $start_tag)) {
        $module_name =~ /(.*)\/[^\/]+/;
        $directory = $1;
    } else {
        $directory = $module_name;
    }

    # Execute the diff command.
    my $read_stdout_data = '';
    my $read_stdout_fh = new FileHandle;
    open($read_stdout_fh, '>', \$read_stdout_data);

    my @args = ();

    my $last_line;
    if (defined $revision) {
        # Just pull out the actual contents of the file.
        push @args, 'cat';
        push @args, '--non-interactive';
        push @args, '--no-auth-cache';
        push @args, @{ $self->{userCmdLine} };
        push @args, $self->{repository_url} . '/' . $module_name . '@' . $revision;
        Codestriker::execute_command($read_stdout_fh, $stderr_fh,
                                     $Codestriker::svn, @args);

	# First determine the line count.
        open($read_stdout_fh, '<', \$read_stdout_data);
        my $number_lines = 0;
        while (<$read_stdout_fh>) {
            $number_lines++;
        }

        # Fake the diff header.
        print $stdout_fh "Index: $module_name\n";
        print $stdout_fh "===================================================================\n";
	my $prefix;
	if ($removed_file) {
	    print $stdout_fh "--- $module_name\t(revision $revision)\n";
	    print $stdout_fh "+++ /dev/null\n";
	    print $stdout_fh "@@ -1,$number_lines +0,0 @@\n";
	    $prefix = '-';
	} else {
	    print $stdout_fh "--- /dev/null\n";
	    print $stdout_fh "+++ $module_name\t(revision $revision)\n";
	    print $stdout_fh "@@ -0,0 +1,$number_lines @@\n";
	    $prefix = '+';
	}

        # Now write out the content.
        open($read_stdout_fh, '<', \$read_stdout_data);
        while (<$read_stdout_fh>) {
	    $last_line ="$prefix $_";
            print $stdout_fh $last_line;
        }
    } else {
        push @args, 'diff';
        push @args, '--non-interactive';
        push @args, '--no-auth-cache';
        push @args, @{ $self->{userCmdLine} };
        push @args, '-r';
        push @args, $start_tag . ':' . $end_tag;
        push @args, '--old';
        push @args, $self->{repository_url};
        push @args, $module_name;
        Codestriker::execute_command($read_stdout_fh, $stderr_fh,
                                     $Codestriker::svn, @args);

        open($read_stdout_fh, '<', \$read_stdout_data);
        while (<$read_stdout_fh>) {
            my $line = $_;

            # If the user specifies a path (a branch in Subversion), the
            # diff file does not come back with a path rooted from the
            # repository base making it impossible to pull the entire file
            # back out. This code attempts to change the diff file on the
            # fly to ensure that the full path is present. This is a bug
            # against Subversion, so eventually it will be fixed, so this
            # code can't break when the diff command starts returning the
            # full path.
            if ($line =~ /^--- / || $line =~ /^\+\+\+ / ||
                $line =~ /^Index: /) {
                # Check if the bug has been fixed.
                if ($line =~ /^\+\+\+ $module_name/ == 0 &&
                    $line =~ /^--- $module_name/ == 0 &&
                    $line =~ /^Index: $module_name/ == 0) {
                    $line =~ s/^--- /--- $directory\// or
                      $line =~ s/^Index: /Index: $directory\// or
                        $line =~ s/^\+\+\+ /\+\+\+ $directory\//;
                }
            }

            print $stdout_fh $line;
	    $last_line = $line;
        }
    }

    # Make sure the last line has a new-line, so when creating text for
    # ScmBug they are all appended correctly.
    if (defined $last_line && substr($last_line, length($last_line)-1, 1) ne "\n") {
	print $stdout_fh "\n";
    }

    return $Codestriker::OK;
}

1;
