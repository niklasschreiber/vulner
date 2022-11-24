import React from 'react';
import {Button} from 'react-bootstrap';

const LoginTwitter = ({userDetails, error, inputChangeHandler, onSubmit,}) => {

    return (
        <Button href={'http://localhost:8080/oauth/authenticate/twitter'} bsStyle="info" block>
            <i className="fa fa-twitter fa-lg"></i> Login with Twitter
        </Button>
    );
};

export default LoginTwitter;