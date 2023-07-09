package dominikhei.seismickafkaconsumer.consumer;

import org.json.JSONObject;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Component;

@Component
public class KafkaListeners {

    @KafkaListener(
        topics="seismic",
        groupId = "groupId"
    )
    void listener(JSONObject data) {
        System.out.println(data.toString());
    }
}
