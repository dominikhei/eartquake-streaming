package dominikhei.seismickafkaconsumer.consumer.kafkaConfig;

import java.nio.charset.StandardCharsets;
import java.util.Map;
import org.apache.kafka.common.serialization.Deserializer;
import org.json.JSONObject;

public class JSONObjectDeserializer implements Deserializer<JSONObject> {

    @Override
    public void configure(Map<String, ?> configs, boolean isKey) {
        
    }

    @Override
    public JSONObject deserialize(String topic, byte[] data) {
        if (data == null)
            return null;

        String jsonString = new String(data, StandardCharsets.UTF_8);
        return new JSONObject(jsonString);
    }

    @Override
    public void close() {
        
    }
}

