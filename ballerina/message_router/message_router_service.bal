import ballerina/http;
import ballerina/log;
//import ballerina/regex;
import ballerina/time;
import ballerinax/kafka;

configurable boolean moderate = ?;
configurable boolean enableSlackNotification = ?;
configurable string kafka_DEFAULT_URL = ?;
configurable int messageRouterListenerPort = ?;

listener http:Listener messageRouterListener = new (messageRouterListenerPort);

# Description.
service MessageRouter /router on messageRouterListener {
    private final kafka:Producer messageProducer;

    public function init() returns error? {
        log:printInfo("Message Router service started");
        self.messageProducer = check new (kafka:DEFAULT_URL);
        log:printInfo("Kafka message producer started");
    }

    # Description.
    # Create a message into Kafka topic
    # + newMessage - parameter description
    # + return - return value description
    resource function post message(NewMessage newMessage) returns http:Created|error {
        return http:CREATED;
    }

    resource function post 'json(RoutherMessage singlItem) returns http:Accepted|error {
        check self.messageProducer->send({
            topic: singlItem.topic,
            value: singlItem.norad_msg
        });
        return http:ACCEPTED;
    }

    # Description.
    # + return - return value description
    public function createInterceptors() returns ResponseErrorInterceptor {
        return new ResponseErrorInterceptor();
    }
}

function buildErrorPayload(string msg, string path) returns ErrorDetails => {
    message: msg,
    timeStamp: time:utcNow(),
    details: string `uri=${path}`
};
