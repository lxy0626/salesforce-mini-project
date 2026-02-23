@isTest
private class LinkFileToParentTest {

    @testSetup
    static void setupData() {

        Contact testApplicant = new Contact(
            LastName = 'Tester',
            Nationality__c = 'Malaysian'
        );
        System.debug('test contact' + testApplicant.Id);
        insert testApplicant;

        // 2. Create the Application
        Application__c testApp = new Application__c(
            RecordTypeId = Schema.SObjectType.Application__c.getRecordTypeInfosByDeveloperName().get('General_Application').getRecordTypeId(),
            // RecordType.Name = 'Undergraduate',
            Applicant__c = testApplicant.Id,
            // Applied_Program__c = testProgram.Id,
            Application_Status__c = 'Submitted',
            Application_Type__c = 'Domestic', // Identified as required in your error log
            Highest_Education_Level__c = 'High School'
        );
        System.debug('test app' + testApp.Id);
        insert testApp;

        // 3. Create the Application Requirement (The Trigger will likely create this, but we create one for explicit testing)
        Application_Requirement__c testReq = new Application_Requirement__c(
            Name = 'Transcript',
            Application__c = testApp.Id,
            Requirement_Type__c = 'Domestic'
        );
        System.debug('test req' + testReq.Id);
        insert testReq;
    }

    @isTest
    static void testFileLinkReplicatedToParent() {
        // setupData();

        Application_Requirement__c req = [SELECT Id, Application__c FROM Application_Requirement__c LIMIT 1];
        System.debug('👉 Requirement ID: ' + req.Id);
        System.debug('👉 Parent Application ID: ' + req.Application__c);

        ContentVersion cv = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'TestDocument.pdf',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );
        insert cv;

        Id docId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
        System.debug('doc id' + docId);

        // 5. Execution
        ContentDocumentLink cdl = new ContentDocumentLink(
            LinkedEntityId = req.Id,
            ContentDocumentId = docId,
            ShareType = 'V'
        );

        System.debug('--- STARTING TRIGGER EXECUTION ---');
        Test.startTest();
        insert cdl;
        Test.stopTest();
        System.debug('--- TRIGGER EXECUTION FINISHED ---');

        // 6. Verification
        List<ContentDocumentLink> links = [
            SELECT LinkedEntityId 
            FROM ContentDocumentLink 
            WHERE ContentDocumentId = :docId
        ];

        Set<Id> linkedIds = new Set<Id>();
            for (ContentDocumentLink link : links) {
            linkedIds.add(link.LinkedEntityId);
        }

        System.assert(linkedIds.contains(req.Id), 'File should be linked to the Requirement.');
        System.assert(linkedIds.contains(req.Application__c), 'File should be automatically linked to the Parent Application.');
        
        System.debug('Total links found for this file: ' + links.size());
        for(ContentDocumentLink link : links) {
            System.debug('Link found for Entity ID: ' + link.LinkedEntityId);
        }

        System.assert(links.size() >= 2, 'The file was not replicated to the parent.');
    }

    @isTest
static void testNonRequirementLinkIsIgnored() {
    // Link a file to a Contact instead of Application_Requirement__c
    // This covers the branch where getSObjectType != Application_Requirement__c
    Contact c = [SELECT Id FROM Contact LIMIT 1];

    ContentVersion cv = new ContentVersion(
        Title = 'Ignored Doc',
        PathOnClient = 'Ignored.pdf',
        VersionData = Blob.valueOf('Nothing here'),
        IsMajorVersion = true
    );
    insert cv;

    Id docId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;

    Test.startTest();
    ContentDocumentLink cdl = new ContentDocumentLink(
        LinkedEntityId = c.Id,
        ContentDocumentId = docId,
        ShareType = 'V'
    );
    insert cdl;
    Test.stopTest();

    // Only 1 link should exist — no replication should have happened
    List<ContentDocumentLink> links = [
        SELECT LinkedEntityId FROM ContentDocumentLink WHERE ContentDocumentId = :docId
    ];
    System.assertEquals(2, links.size(), 'No extra link should be created for non-Requirement objects.');
}
}