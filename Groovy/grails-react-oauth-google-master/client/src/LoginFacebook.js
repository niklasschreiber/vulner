import React from 'react';
import {Button} from 'react-bootstrap';

const LoginFacebook = ({userDetails, error, inputChangeHandler, onSubmit,}) => {

    return (
        <Button href={'http://localhost:8080/oauth/authenticate/facebook'} bsStyle="primary" block>
            <i className="fa fa-facebook-official fa-lg"></i> Login with Facebook
        </Button>
    );
};

export default LoginFacebook;