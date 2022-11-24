import React from 'react';
import {Jumbotron, Row, Col, Form, FormGroup, ControlLabel, FormControl, Button} from 'react-bootstrap';
import LoginGoogle from "./LoginGoogle";
import LoginFacebook from "./LoginFacebook";
import LoginTwitter from "./LoginTwitter";

const Login = ({userDetails, error, inputChangeHandler, onSubmit}) => {

  return (
    <Row>
      <Jumbotron>
        <h1>Welcome to the Garage</h1>
      </Jumbotron>
      <Row>
        {error ? <p className="alert alert-danger">{error} </p> : null}
        <Col sm={4} smOffset={2}>
          <Form onSubmit={onSubmit}>
            <FormGroup>
              <ControlLabel>Login</ControlLabel>
              <FormControl type='text' name='username' placeholder='Username'
                           value={userDetails.username}
                           onChange={inputChangeHandler}/>
              <FormControl type='password' name='password' placeholder='Password'
                           value={userDetails.password}
                           onChange={inputChangeHandler}/>
            </FormGroup>
            <FormGroup>
              <Button bsStyle="success" type="submit">Login</Button>
            </FormGroup>
          </Form>
        </Col>
        <Col sm={4}>
            <div className="well">
                <ControlLabel>Login with Third-party Service</ControlLabel>
                <LoginGoogle/>
                {/* To enable Facebook and Twitter OAuth configure in application.groovy and uncomment below */}
                {/*<LoginFacebook/>*/}
                {/*<LoginTwitter/>*/}
            </div>
        </Col>
      </Row>
    </Row>
  );
};

export default Login;