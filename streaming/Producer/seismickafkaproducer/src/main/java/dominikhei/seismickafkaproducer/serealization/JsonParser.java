package dominikhei.seismickafkaproducer.serealization;

import java.util.UUID;
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
        Float longitude = propertiesObject.getFloat("lon");
        Integer depth = propertiesObject.getInt("depth");
        String dateTime = propertiesObject.getString("time");
        String[] parts = dateTime.split("T|\\.");
        String date = parts[0];
        String time = parts[1];

        UUID uuid = UUID.randomUUID();
        String uuidAsString = uuid.toString();

        JSONObject finalObj = new JSONObject();
        finalObj.put("time", time);
        finalObj.put("date", date);
        finalObj.put("latitude", latitude);
        finalObj.put("longitude", longitude);
        finalObj.put("depth", depth);
        finalObj.put("magnitude", magnitude);
        finalObj.put("uuid", uuidAsString);

        return finalObj;

    }
}

