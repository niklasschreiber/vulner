import requests
import json

def log_progress(msg):
    print(msg)

def capture_input(msg):
    return input(msg)

def login(url, username, password):
    payload = {"username": username, "password": password}
    headers = {"Accept": "application/json", "Content-Type": "application/json"}
    r = requests.post("{}/api/login".format(url), data=json.dumps(payload), headers=headers)
    if r.status_code == 200:
        return [200, r.json()]
    else:
        return [r.status_code, None]

def refresh_access_token(url, refresh_token):
    payload = {"grant_type": "refresh_token", "refresh_token": refresh_token}
    headers = {"Accept": "application/json", "Content-Type": "application/x-www-form-urlencoded"}
    r = requests.post("{}/oauth/access_token".format(url), data=payload, headers=headers)
    if r.status_code == 200:
        return [200, r.json()]
    else:
        return [r.status_code, None]

def fetch_projects(url, access_token, api_version):
    payload = {}
    headers = {"Accept": "application/json",
               "Accept-Version": api_version,
               "Authorization": "Bearer {}".format(access_token)}
    r = requests.get("{}/api/projects".format(url), data=json.dumps(payload), headers=headers)
    if r.status_code == 200:
        return [200, r.json()]
    else:
        return [r.status_code, None]

def run_fetch_projects(url, access_token, refresh_token, api_version):
    status_and_json = fetch_projects(url, access_token, api_version)
    if status_and_json[0] == 401:
        print('Invalid acess_token')
        if refresh_token:
            status_and_json = refresh_access_token(url, refresh_token)
            if not status_and_json[0] == 200:
                print("Unable to refresh the access token")
            else:
                run_fetch_projects(url, status_and_json[1]['access_token'], None, api_version)
    elif not status_and_json[0] == 200:
        print('Error while fetching projects')
    else:
        display_projects(status_and_json[1])

def display_projects(projects):
    print("Project list:")
    for project in projects:
        print(project)

def run():
    url = capture_input('What is your Grails server URL? ')
    username = capture_input('What is your username? ')
    password = capture_input('What is your password? ')
    api_version = capture_input('What is the Api Version [1.0 or 2.0] ? ')
    status_and_json = login(url, username, password)
    if status_and_json[0] == 401:
        print('Unauthorized credentials')
        return
    elif not status_and_json[0] == 200:
        print('Error while login')
        return
    else:
        access_token = status_and_json[1]['access_token']
        refresh_token = status_and_json[1]['refresh_token']
        run_fetch_projects(url, access_token, refresh_token, api_version)

run()
