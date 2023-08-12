package dominikhei.seismickafkaproducer.kafkaConfig;

import org.apache.kafka.common.serialization.Serializer;
import org.json.JSONObject;

import java.nio.charset.StandardCharsets;
import java.util.Map;

public class JSONObjectSerializer implements Serializer<JSONObject> {

    @Override
    public void configure(Map<String, ?> configs, boolean isKey) {

    }

    @Override
    public byte[] serialize(String topic, JSONObject data) {
        if (data == null)
            return null;

        return data.toString().getBytes(StandardCharsets.UTF_8);
    }

    @Override
    public void close() {

    }
}
