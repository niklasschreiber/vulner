# Grails, React & Spring Security
Based on the sample project from http://guides.grails.org/react-spring-security/guide/index.html

This sample project demonstrates how to implement Spring Security REST with Grails and React. The project consists of a multi-project build with two subprojects, `client` (React) and `server` (Grails). 

To run the application, run the Grails project:

```
#Unix
./gradlew server:bootRun

#Windows
gradlew server:bootRun
```

The server should start on `http://localhost:8080`. If you access the application, you should get a 401 response.

In another terminal session, start up the React project:

```
#Unix
./gradlew client:start

#Windows
gradlew client:start
```

If you have `npm` or `yarn` installed, you may also run the React project using those tools, from the `client` directory:

```
yarn start
```

The React app should be served at `http://localhost:3000`. You can login to the application using one of the user accounts set up in the Grails `BootStrap.groovy` file. E.g:

```
username: susan
password: password1
```
