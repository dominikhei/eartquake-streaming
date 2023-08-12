package dominikhei.seismickafkaproducer.streaming;

import dominikhei.seismickafkaproducer.serealization.JsonParser;
import java.net.http.WebSocket;
import java.util.concurrent.CompletionStage;
import org.springframework.stereotype.Component;
import org.springframework.beans.factory.annotation.Autowired;
import org.json.*;

@Component
public class WebSocketClient implements WebSocket.Listener {
    
    @Autowired
    private Producer producer;

    @Autowired
    private JsonParser parser;

    public WebSocketClient(Producer producer, JsonParser parser) {
        this.producer = producer;
        this.parser = parser;
    }
    
    public void onOpen(WebSocket webSocket) {
            WebSocket.Listener.super.onOpen(webSocket);
    }

    public CompletionStage<?> onText(WebSocket webSocket, CharSequence data, boolean last) {
        
        JSONObject jsonObj = parser.createObject(data.toString());
        producer.sendMessageToTopic(jsonObj);
        
        System.out.println(jsonObj.toString());
        return WebSocket.Listener.super.onText(webSocket, data, last);
    }

    public void onError(WebSocket websocket, Throwable error) {
        System.out.println(error);
        WebSocket.Listener.super.onError(websocket, error);
    }
}