import React from 'react';
import {Button} from 'react-bootstrap';

const LoginGoogle = ({userDetails, error, inputChangeHandler, onSubmit, loginGoogle}) => {

    return (
        <Button href={'http://localhost:8080/oauth/authenticate/google'} bsStyle="danger" block>
            <i className="fa fa-google-plus-circle fa-lg"></i> Login with Google
        </Button>
    );
};

export default LoginGoogle;
