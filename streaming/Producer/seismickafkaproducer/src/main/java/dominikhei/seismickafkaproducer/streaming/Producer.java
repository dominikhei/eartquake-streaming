package dominikhei.seismickafkaproducer.streaming;

import org.json.JSONObject;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.kafka.core.KafkaTemplate;

@Service
public class Producer {
    
    @Autowired
    KafkaTemplate<String, JSONObject> kafkaTemplate;

    public void sendMessageToTopic(JSONObject message) {
        kafkaTemplate.send("seismic", message);
    }

}
