
import ballerina/jms;
import ballerina/log;
import ballerina/io;
import ballerina/http;



// Declaring a type of record
type BookingRecord record {
    string bookingID;
    string bookingNo;
    string bookingDate;
    string receiver;
    string loadDate;
    string unloadDate;
    string shipName;
    string portOfLoad;
    string portOfUnload;
    string dBInsertTime;
    string dBUpdateTime;
    string dBDeleted;
    string container;
    string temperature;
    string otherDetails;

};

json globalVarJson;

// Global index Var
int tempIndex = 0;
BookingRecord[] totalDBElements = [];

json[] mainJsonArray;
int jsonIndexElement = 0;

// import ballerina/jsonutils;

// Initialize a JMS connection with the provider.
jms:Connection conn = new({
        initialContextFactory: "com.tibco.tibjms.naming.TibjmsInitialContextFactory",
        providerUrl: "tibjmsnaming://localhost:7222"
    });

// Initialize a JMS session on top of the created connection.
jms:Session jmsSession = new(conn, {
        // An optional property that defaults to `AUTO_ACKNOWLEDGE`.
        acknowledgementMode: "AUTO_ACKNOWLEDGE"
    });

// Initialize a queue receiver using the created session.
endpoint jms:QueueReceiver consumerEP {
    session: jmsSession,
    queueName: "BKNG-PROCESS.BOOKING.GOODSANDCO.V1.Q"
};

// GET MESSAGE FROM THE QUEUE
// Bind the created consumer to the listener service.
service<jms:Consumer> jmsListener bind consumerEP {
    // The `OnMessage` resource gets invoked when a message is received.
    onMessage(endpoint consumer, jms:Message message) {
        // Retrieve the text message.
        match (message.getTextMessageContent()) {
            string messageText => {
                // io:println(proccessStringMessage(messageText));

                // takes XML input and proceed editing it
                convertXMLtoJSON(proccessStringMessage(messageText));
            }
            error e => log:printError("Error occurred while reading message", err = e);
        }
    }
}

// Clean and modify the string message and returns a pure XML
function proccessStringMessage(string message) returns xml {
    io:StringReader reader = new(message,encoding="UTF-8");
    var result = message;
    result = result.replace("xmlns:ns0=\"http://www.tibco.com/schemas/BW-BKNG-PROCESS/SHARED_RESOURCES/Schema.xsd\">", ">");
    result = result.replace("<?xml version=\"1.0\" encoding=\"UTF-8\"?>", "");
    result = result.replace("</ns0:", "</");
    result = result.replace("<ns0:", "<");

    xml convertedStringToXML = stringToXml(result);
    match convertedStringToXML {
        xml payload =>return payload;
    }

}

// XML to JSON

function convertXMLtoJSON(xml payload) {
    BookingRecord dbElements;

    // io:println(totalDBElements);

    // select all XML records
    xml payloadElements = payload.select("record");

    foreach item in payloadElements {
        // Booking elements
        xml booking = item.selectDescendants("booking");

        xml bookingID = booking.selectDescendants("BookingID");
        xml bookingNo = booking.selectDescendants("BookingNo");
        xml bookingDate = booking.selectDescendants("BookingDate");
        xml receiver = booking.selectDescendants("Receiver");
        xml loadDate = booking.selectDescendants("LoadDate");
        xml unloadDate = booking.selectDescendants("UnloadDate");
        xml shipName = booking.selectDescendants("ShipName");
        xml portOfLoad = booking.selectDescendants("PortOfLoad");
        xml portOfUnload = booking.selectDescendants("PortOfUnload");
        xml dBInsertTime = booking.selectDescendants("DBInsertTime");
        xml dBUpdateTime = booking.selectDescendants("DBUpdateTime");
        xml dBDeleted = booking.selectDescendants("DBDeleted");

        dbElements.bookingID = bookingID.getTextValue();
        dbElements.bookingNo = bookingNo.getTextValue();
        dbElements.bookingDate = bookingDate.getTextValue();
        dbElements.receiver = receiver.getTextValue();
        dbElements.loadDate = loadDate.getTextValue();
        dbElements.unloadDate = unloadDate.getTextValue();
        dbElements.shipName = shipName.getTextValue();
        dbElements.portOfLoad = portOfLoad.getTextValue();
        dbElements.portOfUnload = portOfUnload.getTextValue();
        dbElements.dBInsertTime = dBInsertTime.getTextValue();
        dbElements.dBUpdateTime = dBUpdateTime.getTextValue();
        dbElements.dBDeleted = dBDeleted.getTextValue();

        // Bookingcontainers elements
        xml bookingcontainers = item.selectDescendants("bookingcontainers");

        xml container = bookingcontainers.selectDescendants("Container");
        xml temperature = bookingcontainers.selectDescendants("Temperature");
        xml otherDetails = bookingcontainers.selectDescendants("OtherDetails");

        dbElements.container = container.getTextValue();
        dbElements.temperature = temperature.getTextValue();
        dbElements.otherDetails = otherDetails.getTextValue();

        // Direct convert to JSON

        // convertTypeRecordToJson(dbElements);

        // Add elements to the main array
        totalDBElements[tempIndex] = dbElements;
        tempIndex += 1;
    }
// Proceed with Json converting of the new type array for each element
}

function convertTypeRecordToJson(BookingRecord bookingElements) returns json {

    boolean tempBoolean;
    if (bookingElements.dBDeleted == "false") {
        tempBoolean = false;
    } else {
        tempBoolean = true;
    }

    json records = {
        "databasebooking": {
            "booking": {
                "BookingID": bookingElements.bookingID,
                "BookingNo": bookingElements.bookingNo,
                "BookingDate": bookingElements.bookingDate,
                "Receiver": bookingElements.receiver,
                "LoadDate": bookingElements.loadDate,
                "UnloadDate": bookingElements.unloadDate,
                "ShipName": bookingElements.shipName,
                "PortOfLoad": bookingElements.portOfLoad,
                "PortOfUnload": bookingElements.portOfUnload,
                "DBInsertTime": bookingElements.dBInsertTime,
                "DBUpdateTime": bookingElements.dBUpdateTime,
                "DBDeleted": tempBoolean
        },
            "bookingcontainers": {
                "Container": bookingElements.container,
                "Temperature": bookingElements.temperature,
                "OtherDetails": tempBoolean
        }
    }
    };

    // Keep the jeson records for later use if they are needed

    // globalVarJson = records;
    // mainJsonArray[jsonIndexElement] = records;

    // io:println(mainJsonArray[jsonIndexElement]);
    // jsonIndexElement += 1;

    return records;
}

// String to XML
public function stringToXml(string input) returns xml {
    io:StringReader reader = new(input,encoding="UTF-8");
    var result = reader.readXml();
    match result {
        xml payload =>return payload;
        error e =>return xml`<dummy/>`;
        () =>return xml`<dummy/>`;
    }
}


// Attributes associated with the `Listener` endpoint are defined here.
endpoint http:Listener helloWorldEP {
    port: 9105
};

@http:ServiceConfig {
    basePath: "/bookings"
}

// By default, Ballerina assumes that the service is to be exposed via HTTP/1.1.

service helloWorld bind helloWorldEP {

        // All resources are invoked with arguments of server connector and request.
        @http:ResourceConfig {
        methods: ["GET"],
        path: "/{name}"
    }
    sayHello(endpoint caller, http:Request req, string name, string message) {
        http:Response res = new;
        // A util method that can be used to set string payload.
        string idNeeded = untaint name;
        // io:StringReader reader = new io:StringReader(temp);
        // Convert
        // int |error? myTempInt = <int> temp;

        // Find and get the current json record
        json tempJson = getCurrentElementOfID(idNeeded);
        json tmpNull;
        io:print(tempJson);
        io:println(tmpNull);

        // string toPrintJson = tempJson.toString();
        if (tempJson == null) {
            res.setPayload("Record with ID: " + untaint name + " NOT FOUND!!!");
        }
        else {
            res.setPayload( "Record with ID : "+untaint name + " FOUND!!! \n" + tempJson.toString());
        }
        caller->respond(res) but {
            error e =>
            log:printError("Error sending response", err = e)
        };
    }
}

// NOT USED

public function stringToJson(string input) returns json {
    io:StringReader reader = new(input,encoding="UTF-8");
    var result = reader.readJson();
    match result {
        json payload =>return payload;
        error e =>return {};
    }
}

public function getCurrentElementOfID(string indexToFind) returns json {

    json tempJson = null;

    foreach item in totalDBElements {
        if (item.bookingID == indexToFind) {
            tempJson = convertTypeRecordToJson(item);
        }
    }
    return tempJson;
}

// public function main(string... args) {
//     io:println("TESTTTTT");
// }


// function simpleFxConverter(string xmlTemp) {
//     // CONVERT STRING TO XML

//     // io:println("STRING PART");
//     // io:println(xmlTemp);

//     io:StringReader reader = new io:StringReader(xmlTemp);
//     // Check XML
//     // io:println("XML PART");
//     xml |error? myXML = reader.readXml();
//     io:println(myXML);
// // io:println(" ------------ ",  );
// }
