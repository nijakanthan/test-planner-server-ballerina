import ballerina/http;

service /api on new http:Listener(8181) {
    resource function get version() returns string|error {
        return "0.0.1";
    }
}