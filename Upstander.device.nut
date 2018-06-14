server.log("[INIT] DEVICE RUNNING");

// Alias GPIO pins
magnetSensor <- hardware.pin5;
ledStanding <- hardware.pin9;
ledSitting <- hardware.pin1;
pauseButton <- hardware.pin2;

// Configure default state of LEDs, to enable LED
ledStanding.configure(DIGITAL_OUT, 0);
ledSitting.configure(DIGITAL_OUT, 0);

// Create a global pauseState
_isPaused <- false;

class Position {
    fLastPosition = null;
    fLastChanged = null;
    static SITTING = "sitting";
    static STANDING = "standing";

    constructor(init){
        if(init) {
            if(magnetSensor.read() == 0) {
                this.fLastPosition = STANDING;
                ledStanding.write(1);
                ledSitting.write(0);
            } else {
                this.fLastPosition = SITTING;
                ledStanding.write(0);
                ledSitting.write(1);
            }
            this.fLastChanged = hardware.millis();
        }

        return this;
    }

    function messageBuilder(currentPosition, timeElapsedInPositionState){
        return {
            "positionState" : currentPosition,
            "durationInMinutes" : timeElapsedInPositionState
            };
    }

    function recordMagnetSensorState(){
        server.log("[INFO] Sensor state changed");
        local currentPosition = magnetSensor.read();
        local timeElapsedInSec = (hardware.millis() -
                                position.fLastChanged) / 60000; // Convert millis to min

        if (currentPosition == 0) {
            // The magnetSensor is released
            server.log("[INFO] Desk in Standing Mode");

            // build payload to send to agent
            // Note: we send the prior position state for duration
            // because the durationRecord is from the prior state
            local message = position.messageBuilder(position.SITTING, timeElapsedInSec);

            // record statechange to agent
            agent.send("toPosition", message);
            position.fLastChanged = hardware.millis();
         	ledSitting.write(0);
            ledStanding.write(1);
        } else {
            // The magnetSensor is engaged
            server.log("[INFO] Desk in Sitting Mode");

            // build payload to send to agent
            // Note: we send the prior position state for duration
            // because the durationRecord is from the prior state
            local message = position.messageBuilder(position.STANDING, timeElapsedInSec);

            // record statechange to agent
            agent.send("toPosition", message);
            position.fLastChanged = hardware.millis();
         	ledSitting.write(1);
            ledStanding.write(0);
        }

    }

}

function pauseButtonStateChanged(){
    if(_isPaused){
        // prior state was on paused
        _isPaused = false;
    } else {
        // prior state was not on paused
        _isPaused = true;
        position.recordMagnetSensorState();
    }
}
server.log("[INIT] Pins, state, and init configured");

// Agent callback message handler
function agentCallback(message){
    server.log("Response: " + message);
}

// Construct a Position object
position <- Position(true);

// Configure the sensor to call recordMagnetSensorState() when the pin's state changes
// and the device is not currently in a paused state, (e.g. wehn we walk away from our desk)
if( !_isPaused )
    magnetSensor.configure(DIGITAL_IN_PULLDOWN, position.recordMagnetSensorState);

// When the pause button is pressed we set a global state to ignore
// magnet state changes and position behavior, this allows us to avoid
// recording data for state changes where we are not currently at our desk
pauseButton.configure(DIGITAL_IN_PULLUP, pauseButtonStateChanged);

// Callback from Agent
agent.on("response", agentCallback);
