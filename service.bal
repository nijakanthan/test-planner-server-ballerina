import ballerina/http;
import ballerina/file;
import ballerina/io;

type CountryData record {
    string code;
    string name;
};

type Country record {
    string code;
    string name;
    string path;
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
        string folderPath = check file:joinPath("holidays");
        string countiesFilePath = check file:joinPath("countries.json");
        boolean countriesDataFileExists = check file:test(countiesFilePath, file:EXISTS);
        boolean countriesDataFileReadable = check file:test(countiesFilePath, file:READABLE);
        if (!(countriesDataFileExists && countriesDataFileReadable)) {
            return error("Data source not found");
        }
        string|io:Error dataContent = io:fileReadString(countiesFilePath);
        CountryData[] coutriesData;
        if (dataContent is string) {
            json dataObject = check dataContent.fromJsonString();
            CountryData[]|error cData = dataObject.cloneWithType();
            if (cData is error) {
                return error("Data source is invalid");
            } else {
                coutriesData = cData;
            }
        } else {
            return error("Data source is invalid");
        }
        boolean holidayFolderExists = check file:test(folderPath, file:EXISTS);
        CountriesResponse response = {
            countries: []
        };
        if (!holidayFolderExists) {
            return response.toJson();
        }
        file:MetaData[] readDirResults = check file:readDir(folderPath);
        foreach file:MetaData metaData in readDirResults {
            string|file:Error basename = file:basename(metaData.absPath);
            file:MetaData[] subDirResults = check file:readDir(metaData.absPath);
            // Get country code
            final string selectedCode;
            if (basename is file:Error) {
                continue;
            } else {
                selectedCode = basename;
            }
            CountryData[] selectedCountries = coutriesData.filter(isolated function(CountryData c) returns boolean {
                return c.code == selectedCode;
            });
            // Get country name
            string selectedName;
            if (selectedCountries.length() == 1) {
                selectedName = selectedCountries[0].name;
            } else {
                selectedName = selectedCode;
            }
            // Get country records
            string[] recordsArray = [];
            foreach file:MetaData recordList in subDirResults {
                if (!recordList.dir) {
                    string|file:Error recordName = file:basename(recordList.absPath);
                    if (recordName is file:Error) {
                        continue;
                    } else {
                        recordsArray.push(recordName);
                    }
                }
            }
            if (metaData.dir) {
                response.countries.push({
                    name: selectedName,
                    code: selectedCode,
                    path: metaData.absPath,
                    records: recordsArray
                });
            }
        }
        return response.toJson();
    }

    resource function get holidays/[string country]/[string year]() returns json|error {
        string filePath = check file:joinPath("holidays", country, year+".json");
        boolean holidayFileExists = check file:test(filePath, file:EXISTS);
        boolean holidayFileReadable = check file:test(filePath, file:READABLE);
        HolidaysResponse response = {
            holidays: []
        };
        if (holidayFileExists && holidayFileReadable) {
            string|io:Error content = io:fileReadString(filePath);
            if (content is string) {
                json contentObject = check content.fromJsonString();
                Holiday[]|error holidays = contentObject.cloneWithType();
                if (holidays is error) {
                    return response.toJson();
                }
                response.holidays = holidays;
            }
        }
        return response.toJson();
    }
}