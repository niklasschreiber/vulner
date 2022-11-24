grails {
    plugin {
        springsecurity {
            rest {
                token {
                    validation {
                        active = true
                        headerName = 'X-Auth-Token'
                        endpointUrl = '/api/validate'
                    }
                }
                oauth {
                    frontendCallbackUrl = { String tokenValue -> "http://localhost:3000/oauthLogin#token=${tokenValue}" }
                    google {
                        client = org.pac4j.oauth.client.Google2Client
                        key = ''
                        secret = ''
                        scope = org.pac4j.oauth.client.Google2Client.Google2Scope.EMAIL_AND_PROFILE
                        defaultRoles = ['ROLE_DRIVER', 'ROLE_GOOGLE']

                    }
                    /** I am not certain facebook works 100% correctly. What it returns from its callback is separated differently  */
//                    facebook {
//                        client = org.pac4j.oauth.client.FacebookClient
//                        key = ''
//                        secret = ''
//                        scope = 'email,user_location'
//                        fields = 'id,name,first_name,middle_name,last_name,username'
//                        defaultRoles = ['ROLE_DRIVER', 'ROLE_FACEBOOK']
//                    }
//                    twitter {
//                        client = org.pac4j.oauth.client.TwitterClient
//                        key = 'xxx'
//                        secret = 'yyy'
//                        defaultRoles = ['ROLE_DRIVER', 'ROLE_TWITTER']
//                    }
                }
            }
        }
    }
}