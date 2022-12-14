###############################################################################
# Codestriker: Copyright (c) 2001, 2002 David Sitsky.  All rights reserved.
# sits@users.sourceforge.net
#
# This program is free software; you can redistribute it and modify it under
# the terms of the GPL.

# Action object for displaying the new password page.

package Codestriker::Action::NewPassword;

use strict;
use Codestriker::Http::UrlBuilder;

# Create an appropriate form for entering a new password.
sub process {
    my ($type, $http_input, $http_response) = @_;

    my $query = $http_response->get_query();
    my $email = $http_input->get('email');
    my $challenge = $http_input->get('challenge');

    $http_response->generate_header(topic_title=>"New Password",
                                    reload=>0, cache=>1);

    # Target URL to divert the post to.
    my $vars = {};
    my $url_builder = Codestriker::Http::UrlBuilder->new($query);
    $vars->{'action_url'} = $url_builder->update_password_url(email => $email);
    $vars->{'email'} = $email;
    $vars->{'challenge'} = $challenge;

    my $template = Codestriker::Http::Template->new("newpassword");
    $template->process($vars);

    $http_response->generate_footer();
}

1;
