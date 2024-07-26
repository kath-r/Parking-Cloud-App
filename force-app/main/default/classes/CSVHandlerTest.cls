@isTest
public with sharing class CSVHandlerTest {
    @testSetup
    static void setup() {
        // create BS records for DB
        List<Base_Station__c> testBaseStations = new List<Base_Station__c>();
        Base_Station__c bs1 = new Base_Station__c(Name='BS1', Status__c='Active');
        Base_Station__c bs2 = new Base_Station__c(Name='BS2', Status__c='Inactive');
        
        Base_Station__c existingBS = new Base_Station__c(Name='ExistingBS',Status__c='Active');
        
        testBaseStations.add(bs1);
        testBaseStations.add(bs2);
        testBaseStations.add(existingBS);
        upsert testBaseStations;

        // create test contentDocument (like csv)
        ContentVersion testContentVersion = new ContentVersion(
            Title = 'Test CSV',
            VersionData = Blob.valueOf('model,status,bsName\nModel1,Active,BS1\nModel2,Inactive,BS2\nModel3,Active,BS3'),
            PathOnClient = 'test.csv'
        );
        insert testContentVersion;
    }

    @isTest
    static void testParseCSVInsertData() {
        ContentDocument testContentDocument = [SELECT ID FROM ContentDocument LIMIT 1];

        Test.startTest();
            CSVHandler.parseCSVInsertData(testContentDocument.Id);
        Test.stopTest();

        List<Base_Station__c> insertedBS = [SELECT Name, Status__c FROM Base_Station__c WHERE Name IN ('BS1', 'BS2', 'BS3')];
        System.assertEquals(3, insertedBS.size());

        Map<String, Base_Station__c> bsMap = new Map<String, Base_Station__c>();
        for(Base_Station__c bs : insertedBS) {
            bsMap.put(bs.Name, bs);
        }

        System.assertEquals('Active', bsMap.get('BS1').Status__c);
        System.assertEquals('Inactive', bsMap.get('BS2').Status__c);
        System.assertEquals('Active', bsMap.get('BS3').Status__c);

        // Verify Sensor__c records related to CSV
        List<Sensor__c> sensors = [SELECT Sensor_model__c, Status__c, Base_Station__r.Name FROM Sensor__c WHERE Base_Station__r.Name IN ('BS1', 'BS2', 'BS3')];
        System.assertEquals(3, sensors.size());
        Map<String, Sensor__c> sensorMap = new Map<String, Sensor__c>();
        for (Sensor__c sensor : sensors) {
            sensorMap.put(sensor.Sensor_model__c + sensor.Base_Station__r.Name, sensor);
        }
        System.assertEquals('Active', sensorMap.get('Model1BS1').Status__c);
        System.assertEquals('Inactive', sensorMap.get('Model2BS2').Status__c);
        System.assertEquals('Active', sensorMap.get('Model3BS3').Status__c);
    }

    /*@isTest
    static void testParseCSVInsertDataNoContentVersion() {
        Test.startTest();
        try {
            CSVHandler.parseCSVInsertData(null);
            System.assert(false, 'Exception should have been thrown for missing ContentVersion');
        } catch (Exception e) {
            system.debug('error' + e);
            System.assert(e.getMessage().contains('System.AuraHandledException: Script-thrown exception'));
            System.assert(e.getMessage().contains('Error parsing CSV and inserting data'));
            System.assert(e.getMessage().contains('ContentVersion not found for ContentDocumentId'), 'Exception message should mention missing ContentVersion');
        }
        Test.stopTest();
    }*/
}