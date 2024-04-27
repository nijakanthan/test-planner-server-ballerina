import ballerina/http;
import ballerina/io;

final string BASE_URL = "https://raw.githubusercontent.com/nijakanthan/data-bank/main/";

isolated function readFileFromWeb(string url) returns json|error {
    http:Client httpEP = check new (url);
    http:Response res = check httpEP->get("");
    json|io:Error dataStream = check res.getJsonPayload();
    if dataStream is error {
        return error("Error while reading data from web source");   
    }
    return dataStream;
}

type CountryData record {
    string code;
    string name;
};

type Country record {
    string code;
    string name;
    string[] records;
};

type CountriesResponse record {
    Country[] countries;
};

type Holiday record {
    string summary;
    anydata catagories;
    string date;
};

type HolidaysResponse record {
    Holiday[] holidays;
};

service / on new http:Listener(8181) {
    resource function get app_version() returns json|error {
        return {
            "version": "BAL 1.0.0"
        };
    }

    isolated resource function get countries() returns json|error {
        json|error dataObject = readFileFromWeb(BASE_URL + "countries.json");
        if dataObject is error {
            return dataObject;
        }
        CountriesResponse response = {
            countries: []
        };
        Country[]|error cData = dataObject.cloneWithType();
        if (cData is error) {
            return error("Data source is invalid");
        } else {
            response.countries = cData;
        }
        return response.toJson();
    }

    resource function get holidays/[string country]/[string year]() returns json|error {
        json|error contentObject = readFileFromWeb(
            BASE_URL 
            + "holidays/"
            + country
            + "/"
            + year
            + ".json"
        );
        if contentObject is error {
            return contentObject;
        }
        HolidaysResponse response = {
            holidays: []
        };
        Holiday[]|error holidays = contentObject.cloneWithType();
        if (holidays is error) {
            return response.toJson();
        }
        response.holidays = holidays;
        return response.toJson();
    }
}