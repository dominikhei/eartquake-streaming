package dominikhei.seismickafkaconsumer.consumer;

import dominikhei.seismickafkaconsumer.consumer.dynamoDb.DbClient;

import org.json.JSONObject;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Component;

@Component
public class KafkaListeners {

    DbClient client = new DbClient();

    @KafkaListener(
        topics="seismic",
        groupId = "groupId"
    )
    void listener(JSONObject data) {
        System.out.println(data.toString());
        client.uploadToTable("eartquakes", data);

    }
}
