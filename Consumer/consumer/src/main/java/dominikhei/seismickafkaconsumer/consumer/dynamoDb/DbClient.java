package dominikhei.seismickafkaconsumer.consumer.dynamoDb;

import org.json.JSONObject;
import com.amazonaws.services.dynamodbv2.document.DynamoDB;
import com.amazonaws.auth.AWSStaticCredentialsProvider;
import com.amazonaws.auth.BasicAWSCredentials;
import com.amazonaws.regions.Regions;
import com.amazonaws.services.dynamodbv2.AmazonDynamoDB;
import com.amazonaws.services.dynamodbv2.AmazonDynamoDBClientBuilder;
import com.amazonaws.services.dynamodbv2.document.Item;
import com.amazonaws.services.dynamodbv2.document.Table;

public class DbClient {

    public DynamoDB clientBuilder() {
        AmazonDynamoDB client = AmazonDynamoDBClientBuilder.standard()
            .withRegion(Regions.EU_CENTRAL_1)
            .build();
        DynamoDB dynamoDB = new DynamoDB(client);
        return dynamoDB;
    }

    public void uploadToTable(String tableName, JSONObject json) {
        DynamoDB dynamoDb = clientBuilder();
        Table table = dynamoDb.getTable(tableName);
        String id = json.get("uuid").toString();
        String jsonString = json.toString();
        Item item = new Item().withPrimaryKey("id", id).withJSON("data", jsonString);
        table.putItem(item);
    } 
}
