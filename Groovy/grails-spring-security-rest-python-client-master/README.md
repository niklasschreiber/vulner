# Python Client - Spring Security Rest for Grails
 
This repository contains a python scripts which shows how to interact with [Spring Security Rest for Grails](http://alvarosanchez.github.io/grails-spring-security-rest/latest/docs/) plugin.

It uses the [JSON Web Token (JWT)](http://alvarosanchez.github.io/grails-spring-security-rest/latest/docs/#_json_web_token) capabilities offered by plugin. 

## Run 

You need the requests module installed in your system. 

```
    $ pip3 install requests 
```

or in Python 2

```
    $ pip install requests 
```


The you can run: 

```    
    $ python3 fetchprojects.py    
```    

If you are running Grails 3. Your development Grails App Server Url will be: 

http://localhost:8080

If you are running Grails 2:

http://localhost:8080/myapp

This script, after authenticating, calls with a GET request an endpoint named _/api/projects_. It expects a JSON array of projects to be returned. 
