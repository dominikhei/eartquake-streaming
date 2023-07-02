package dominikhei.seismickafkaproducer.streaming;

import java.net.http.WebSocket;
import java.util.concurrent.CompletionStage;
import java.util.concurrent.CountDownLatch;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Component;
import org.springframework.beans.factory.annotation.Autowired;

@Component
public class WebSocketClient implements WebSocket.Listener {
    
    @Autowired
    private Producer producer;

    public WebSocketClient(Producer producer) {
        this.producer = producer;
    }
    
    public void onOpen(WebSocket webSocket) {
            WebSocket.Listener.super.onOpen(webSocket);
    }

    public CompletionStage<?> onText(WebSocket webSocket, CharSequence data, boolean last) {
        producer.sendMessageToTopic(data.toString());
        System.out.println("sent data to kafka");
        return WebSocket.Listener.super.onText(webSocket, data, last);
    }

    public void onError(WebSocket websocket, Throwable error) {
        System.out.println(error);
        WebSocket.Listener.super.onError(websocket, error);
    }
}