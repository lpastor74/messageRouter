import ballerina/ftp;
import ballerina/http;
import ballerina/io;
import ballerina/log;

final http:Client securedClient = check new (gwConfig.gwURL,
    auth = {
        tokenUrl: gwConfig.tokenUrl,
        clientId: gwConfig.clientId,
        clientSecret: gwConfig.clientSecret,
        scopes: gwConfig.scopes,
        clientConfig: {
            secureSocket: {
                cert: "./resource/public.crt"
            }
        }
    },
    secureSocket = {
        cert: "./resource/public.crt"
    }
);

listener ftp:Listener remoteServer = check new ({
    protocol: ftp:SFTP,
    host: sftpConfig.hostURL,
    auth: {
        credentials: {
            username: sftpConfig.userName,
            password: sftpConfig.password
        }
    },
    port: 22,
    path: "/beauser/in",
    pollingInterval: sftpConfig.pollingInterval,
    fileNamePattern: sftpConfig.fileNamePattern
});

ftp:Client remoteClient = check new ({
    protocol: ftp:SFTP,
    host: "ftp.support.wso2.com",
    auth: {
        credentials: {
            username: sftpConfig.userName,
            password: sftpConfig.password
        }
    },
    port: 22
});

service on remoteServer {

    # Description.
    #
    # + event - parameter description  
    # + caller - parameter description
    # + return - return value description
    isolated remote function onFileChange(ftp:WatchEvent & readonly event, ftp:Caller caller) returns error? {
        foreach ftp:FileInfo newFile in event.addedFiles {
            log:printInfo("there is a file  ....");
            stream<byte[] & readonly, io:Error?> fileStream = check caller->get(newFile.pathDecoded);
            Norad[] values = check readFile(fileStream);
            Norad[] errors = [];
            foreach Norad msg in values {
                //send message over client 
                if (sendMsg2GW) {
                    error? response = securedClient->post("json", postToRouter(msg));
                    if response is error {
                        log:printError("Error occurred while connecting to the server", 'error = response);
                        errors.push(msg);
                    }
                }
                else {
                    log:printInfo(msg.toString());
                }
            }

            if errors.length() > 0 {
                // create a file and flush the messages
                check sendFile(errors);
            }
        }
    }
}

isolated function readFile(stream<byte[] & readonly, io:Error?> fileStream) returns Norad[]|error {
    byte[] bytes = check fileStream.reduce(
        isolated function(byte[] accumulator, byte[] byteArr) returns byte[] => [...accumulator, ...byteArr], []);
    check fileStream.close();
    string jsonString = check string:fromBytes(bytes);
    return jsonString.fromJsonStringWithType();
}

isolated function sendFile(Norad[] list) returns error? {
    //_= check remoteClient->put("/beauser/error/error.json", list.toJsonString()); 
    log:printInfo(list.toJsonString());

}

isolated function postToRouter(Norad norad) returns RoutherMessage => {
    norad_msg: norad,
    topic: kafkaConfig.kafkaTopic,
    priority: kafkaConfig.priorityLevel
};

