global class InventoryBatchJob implements Database.Batchable<SObject>, Schedulable {

    global Database.QueryLocator start(Database.BatchableContext BC) {

        return Database.getQueryLocator(
            'SELECT Id, Stock_Quantity__c ' +
            'FROM HandsMen_Product__c ' +
            'WHERE Stock_Quantity__c < 10'
        );
    }

    global void execute(
        Database.BatchableContext BC,
        List<SObject> records
    ) {

        List<HandsMen_Product__c> productsToUpdate =
            new List<HandsMen_Product__c>();

        for (SObject record : records) {

            HandsMen_Product__c product =
                (HandsMen_Product__c) record;

            // Restock by 50
            product.Stock_Quantity__c += 50;

            productsToUpdate.add(product);
        }

        if (!productsToUpdate.isEmpty()) {

            try {
                update productsToUpdate;

            } catch (DmlException e) {

                System.debug(
                    'Error updating inventory: ' +
                    e.getMessage()
                );
            }
        }
    }

    global void finish(Database.BatchableContext BC) {

        System.debug('Inventory Sync Completed');
    }

    // Scheduler Method
    global void execute(SchedulableContext SC) {

        InventoryBatchJob batchJob =
            new InventoryBatchJob();

        Database.executeBatch(batchJob, 200);
    }
}
