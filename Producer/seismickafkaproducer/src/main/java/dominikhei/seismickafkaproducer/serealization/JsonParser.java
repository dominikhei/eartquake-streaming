package dominikhei.seismickafkaproducer.serealization;

import org.json.*;
import org.springframework.stereotype.Service;

@Service
public class JsonParser {


    public JSONObject createObject(String jsonString) {
        JSONObject jsonObj = new JSONObject(jsonString);

        JSONObject dataObject = jsonObj.getJSONObject("data");
        JSONObject propertiesObject = dataObject.getJSONObject("properties");

        Float magnitude = propertiesObject.getFloat("mag");
        Float latitude = propertiesObject.getFloat("lat");
        Float longtitude = propertiesObject.getFloat("lon");
        Integer depth = propertiesObject.getInt("depth");
        String dateTime = propertiesObject.getString("time");
        String[] parts = dateTime.split("T|\\.");
        String date = parts[0];
        String time = parts[1];

        JSONObject finalObj = new JSONObject();
        finalObj.put("time", time);
        finalObj.put("date", date);
        finalObj.put("latitude", latitude);
        finalObj.put("longtitude", longtitude);
        finalObj.put("depth", depth);
        finalObj.put("magnitude", magnitude);

        return finalObj;

    }



    // I only want magnitude, latitude, longtitude, date and time 
    
    // Have a base method to convert it to a JsonObject 



    // Extract only the relevant key value pairs from it via another function 

    // Have a final toParsedJson() method which is a wrapper around all of 
    // these and returns a Json Object 

    // Change kafkaProducerConfig to the Json Serealizer 
    
}
