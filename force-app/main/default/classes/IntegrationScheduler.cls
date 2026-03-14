public class IntegrationScheduler implements Schedulable {
    public void execute(SchedulableContext ctx) {
        IntegrationRetryBatch batch = new IntegrationRetryBatch();
        Database.executeBatch(batch, 50);
    }
}
