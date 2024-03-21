import ballerina/http;

service / on new http:Listener(8181) {
    resource function get app_version() returns string|error {
        return "0.0.1";
    }
}