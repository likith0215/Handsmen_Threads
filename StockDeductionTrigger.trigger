trigger StockDeductionTrigger on HandsMen_Order__c (after insert, after update) {

    Set<Id> productIds = new Set<Id>();

    // Collect Product IDs from confirmed orders
    for (HandsMen_Order__c order : Trigger.new) {
        if (order.Status__c == 'Confirmed' &&
            order.HandsMen_Product__c != null) {

            productIds.add(order.HandsMen_Product__c);
        }
    }

    if (productIds.isEmpty()) {
        return;
    }

    // Query related Inventory records
    Map<Id, Inventory__c> inventoryMap = new Map<Id, Inventory__c>(
        [
            SELECT Id, Stock_Quantity__c, Product__c
            FROM Inventory__c
            WHERE Product__c IN :productIds
        ]
    );

    List<Inventory__c> inventoriesToUpdate = new List<Inventory__c>();

    // Deduct stock
    for (HandsMen_Order__c order : Trigger.new) {

        if (order.Status__c == 'Confirmed' &&
            order.HandsMen_Product__c != null) {

            for (Inventory__c inv : inventoryMap.values()) {

                if (inv.Product__c == order.HandsMen_Product__c) {

                    // Create a new SObject containing ONLY
                    // the fields that need to be updated.
                    Inventory__c invUpdate = new Inventory__c(
                        Id = inv.Id,
                        Stock_Quantity__c =
                            inv.Stock_Quantity__c - order.Quantity__c
                    );

                    inventoriesToUpdate.add(invUpdate);

                    break;
                }
            }
        }
    }

    // Update Inventory
    if (!inventoriesToUpdate.isEmpty()) {
        update inventoriesToUpdate;
    }
}
