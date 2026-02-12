@isTest
private class LinkFileToParentTest {

    @isTest
    static void testFileLinkReplicatedToParent() {
        // 1. Setup Data
        Application_Requirement__c childReq = createTestData(true);
        Id conDocId = createTestFile();

        // 2. Execution
        ContentDocumentLink cdl = new ContentDocumentLink(
            LinkedEntityId = childReq.Id,
            ContentDocumentId = conDocId,
            ShareType = 'V'
        );

        Test.startTest();
        insert cdl;
        Test.stopTest();

        // 3. Verification
        List<ContentDocumentLink> links = [SELECT LinkedEntityId FROM ContentDocumentLink WHERE ContentDocumentId = :conDocId];
        
        // Expect 2: One for Child, one for Parent
        System.assertEquals(2, links.size(), 'There should be exactly two links.');
        
        Boolean parentLinkFound = false;
        for(ContentDocumentLink link : links) {
            if(link.LinkedEntityId == childReq.Application__c) {
                parentLinkFound = true;
            }
        }
        System.assert(parentLinkFound, 'The file was not correctly linked to the Parent Application.');
    }

    @isTest
    static void testFileLinkNotReplicatedWhenParentMissing() {
        Application_Requirement__c childNoParent = createTestData(false);
        Id conDocId = createTestFile();

        ContentDocumentLink cdl = new ContentDocumentLink(
            LinkedEntityId = childNoParent.Id,
            ContentDocumentId = conDocId,
            ShareType = 'V'
        );

        Test.startTest();
        insert cdl;
        Test.stopTest();

        List<ContentDocumentLink> links = [SELECT Id FROM ContentDocumentLink WHERE ContentDocumentId = :conDocId];
        System.assertEquals(1, links.size(), 'Only one link should exist.');
    }

    // --- HELPER METHODS ---

    private static Application_Requirement__c createTestData(Boolean includeParent) {
        Id parentId = null;
        
        if (includeParent) {
            Application__c app = new Application__c();
            insert app;
            parentId = app.Id;
        }

        Application_Requirement__c req = new Application_Requirement__c(
            Name = 'Test Requirement',
            Application__c = parentId
        );
        insert req;
        return req;
    }

    private static Id createTestFile() {
        ContentVersion cv = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'TestDoc.pdf',
            VersionData = Blob.valueOf('Unit Test Content'),
            IsMajorVersion = true
        );
        insert cv;
        
        return [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
    }
}