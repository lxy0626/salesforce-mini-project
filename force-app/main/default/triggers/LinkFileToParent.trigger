trigger LinkFileToParent on ContentDocumentLink (after insert) {
    List<ContentDocumentLink> newLinks = new List<ContentDocumentLink>();
    Set<Id> childIds = new Set<Id>();
    
    // 1. Filter for links created on your specific Child Object
    for (ContentDocumentLink cdl : Trigger.new) {
        // This ensures we only run logic for your specific object type
        if (cdl.LinkedEntityId.getSObjectType().getDescribe().getName() == 'Application_Requirement__c') {
            childIds.add(cdl.LinkedEntityId);
        }
    }
    
    if (!childIds.isEmpty()) {
        // 2. Fetch the Parent IDs from the Child Records
        Map<Id, Application_Requirement__c> childMap = new Map<Id, Application_Requirement__c>(
            [SELECT Id, Application__c FROM Application_Requirement__c WHERE Id IN :childIds]
        );
        
        for (ContentDocumentLink cdl : Trigger.new) {
            Application_Requirement__c parentRec = childMap.get(cdl.LinkedEntityId);
            
            // 3. If the child has a parent, create a new link for that parent
            if (parentRec != null && parentRec.Application__c != null) {
                ContentDocumentLink parentLink = new ContentDocumentLink();
                parentLink.ContentDocumentId = cdl.ContentDocumentId;
                parentLink.LinkedEntityId = parentRec.Application__c;
                parentLink.ShareType = 'V'; // V = Viewer access
                parentLink.Visibility = 'AllUsers'; // Ensures visibility across the org
                newLinks.add(parentLink);
            }
        }
    }
    
    // 4. Insert all new parent links at once
    if (!newLinks.isEmpty()) {
        insert newLinks;
    }
}