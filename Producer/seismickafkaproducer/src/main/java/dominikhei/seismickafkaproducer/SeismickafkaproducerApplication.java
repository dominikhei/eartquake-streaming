package dominikhei.seismickafkaproducer;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.kafka.annotation.EnableKafka;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import dominikhei.seismickafkaproducer.streaming.WebSocketClient;

import java.net.http.HttpClient;
import java.net.URI;

@SpringBootApplication
@EnableKafka
public class SeismickafkaproducerApplication {

	public static void main(String[] args) {
		SpringApplication.run(SeismickafkaproducerApplication.class, args);
	}

	@Component
		public static class WebSocketRunner implements CommandLineRunner {
			
			@Autowired
			private WebSocketClient client;

			@Override
			public void run(String... args) throws Exception {
				HttpClient
						.newHttpClient()
						.newWebSocketBuilder()
						.buildAsync(URI.create("wss://www.seismicportal.eu/standing_order/websocket"), client)
						.join();
			}
		}

}