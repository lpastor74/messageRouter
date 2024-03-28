import ballerinax/mysql;
import ballerinax/mysql.driver as _;

configurable string kafka_DEFAULT_URL = ?;
configurable boolean persist_msq2db = ?;
configurable boolean persist_log = ?;

type KafkaConfig record {|
    string Default_URL;
    string groupID;
    string topic;
|};

type DataBaseConfig record {|
    string host;
    int port;
    string user;
    string password;
    string database;
|};

configurable DataBaseConfig databaseConfig = ?;
configurable KafkaConfig kafkaConfig = ?;
final mysql:Client spaceDb = check initDbClient();

function initDbClient() returns mysql:Client|error => new (...databaseConfig);
