#require "KeenIO.class.nut:1.0.0"
#require "PrettyPrinter.class.nut:1.0.1"

server.log("[INIT] AGENT RUNNING");

const KEEN_PROJECT_ID = "XXXXXXXXXXXXXX";
const KEEN_WRITE_API_KEY = "ADFASDFASDFASDFASDFASDFFADSF";
const KEEN_READ_API_KEY = "ADSFASDDFASDFSASDFASDFASDFASDF";

keen <- KeenIO(KEEN_PROJECT_ID, KEEN_WRITE_API_KEY);
pp <- PrettyPrinter();

// Send an event asynchronously
function sendPositionRecord(eventData){
    keen.sendEvent("position", eventData, function(response) {
        server.log("[INFO] " + response.statuscode + ": " + response.body);
    });
}

function recordPosition(payload){
    local time = date(time()); // time.month is 0 base
    local timeFormated = time.year + "." + ( time.month + 1) + "." + time.day + " "
                        + time.hour + ":" + time.min + ":" + time.sec;
    prettyPayload <- pp.format(payload);
    local record = "[INFO] Position state recorded: " + prettyPayload + " at " + timeFormated;

    eventData <- {
    "positionData" : payload,
    "timeStamp" : timeFormated
    };

    // Response to device with PositionRecord
    device.send("response", record);
    // Upload payload to KeenI/0
    sendPositionRecord(eventData);
}

device.on("toPosition", recordPosition);
