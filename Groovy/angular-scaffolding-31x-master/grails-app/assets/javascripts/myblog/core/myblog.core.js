//= wrapped
//= require /angular/angular
//= require_self
//= require_tree services
//= require_tree controllers
//= require_tree directives
//= require_tree templates

angular.module("myblog.core", [])
    .config(config);

function config($httpProvider) {
    $httpProvider.interceptors.push(httpRequestInterceptor);
}

function isIso8601(value) {
    return angular.isString(value) && /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?Z$/.test(value);
}

function convertToDate(input) {
    if (!angular.isObject(input)) {
        return input;
    }

    angular.forEach(input, function (value, key) {
        if (isIso8601(value)) {
            input[key] = new Date(value);
        } else if (angular.isObject(value)) {
            convertToDate(value);
        }
    });
}

function httpRequestInterceptor() {
    return {
        response: function(response) {
            convertToDate(response.data);
            return response;
        }
    };
}