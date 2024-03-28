import ballerinax/kafka;
import ballerina/log;





listener kafka:Listener orderListener = new (kafka_DEFAULT_URL, {
    groupId: kafkaConfig.groupID,
    topics: kafkaConfig.topic
});

service on orderListener {

    remote function onConsumerRecord(NORAD[] data) returns error? {
        // The set of orders received by the service are processed one by one.
        from NORAD msg in data           
            do {
                if(persist_log){log:printInfo(string `Consumed msg for ${msg.NORAD_CAT_ID ?: "null"}`);}
                if (persist_msq2db)
                {
                _ = check spaceDb->execute(`INSERT INTO NORAD
                (CCSDS_OMM_VERS , COMMENT , CREATION_DATE , ORIGINATOR , OBJECT_NAME , OBJECT_ID , CENTER_NAME ,REF_FRAME , TIME_SYSTEM ,
                 MEAN_ELEMENT_THEORY , EPOCH , MEAN_MOTION , ECCENTRICITY , INCLINATION ,
                 RA_OF_ASC_NODE , ARG_OF_PERICENTER , MEAN_ANOMALY , EPHEMERIS_TYPE , CLASSIFICATION_TYPE ,
                 NORAD_CAT_ID , ELEMENT_SET_NO , REV_AT_EPOCH , BSTAR , MEAN_MOTION_DOT , MEAN_MOTION_DDOT ,
                 SEMIMAJOR_AXIS , PERIOD , APOAPSIS , PERIAPSIS , OBJECT_TYPE , RCS_SIZE , COUNTRY_CODE , LAUNCH_DATE ,
                 SITE , DECAY_DATE , FILE , GP_ID , TLE_LINE0 , TLE_LINE1 , TLE_LINE2)
                VALUES
                (${msg.CCSDS_OMM_VERS},${msg.COMMENT},${msg.CREATION_DATE},${msg.ORIGINATOR},${msg.OBJECT_NAME},
                ${msg.OBJECT_ID},${msg.CENTER_NAME},${msg.REF_FRAME},${msg.TIME_SYSTEM},${msg.MEAN_ELEMENT_THEORY},
                ${msg.EPOCH},${msg.MEAN_MOTION},${msg.ECCENTRICITY},${msg.INCLINATION},${msg.RA_OF_ASC_NODE},
                ${msg.ARG_OF_PERICENTER},${msg. MEAN_ANOMALY},${msg.EPHEMERIS_TYPE},${msg.CLASSIFICATION_TYPE},
                ${msg.NORAD_CAT_ID},${msg.ELEMENT_SET_NO},${msg.REV_AT_EPOCH},${msg.BSTAR},${msg.MEAN_MOTION_DOT},
                ${msg.MEAN_MOTION_DDOT},${msg.SEMIMAJOR_AXIS},${msg.PERIOD},${msg.APOAPSIS},${msg.PERIAPSIS},
                ${msg.OBJECT_TYPE},${msg.RCS_SIZE},${msg.COUNTRY_CODE},${msg.LAUNCH_DATE},${msg.SITE},
                ${msg.DECAY_DATE},${msg.FILE},${msg.GP_ID},${msg.TLE_LINE0},${msg.TLE_LINE1},${msg.TLE_LINE2});`);
                }
            };
    }
}
