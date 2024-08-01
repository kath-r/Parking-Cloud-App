@IsTest
private class CSVHandlerTest {

    @IsTest
    static void testParseCSVInsertData() {
        // Setup test data
        ContentVersion cv = new ContentVersion(
            Title = 'Test CSV',
            PathOnClient = 'test.csv',
            VersionData = Blob.valueOf('model,status,bsName\nModel1,Active,BS1\nModel2,Inactive,BS2\nModel3,Active,BS3\nModel4,Inactive')
        );
        insert cv;
        ContentDocument ContentDocumentId = [SELECT Id FROM ContentDocument LIMIT 1];

        Test.startTest();
            CSVHandler.parseCSVInsertData(ContentDocumentId.Id);
        Test.stopTest();

        // Assert the results
        List<Base_Station__c> baseStations = [SELECT Id, Name FROM Base_Station__c];
        System.assertEquals(3, baseStations.size(), 'Base stations count mismatch.');

        List<Sensor__c> sensors = [SELECT Id, Sensor_model__c, Status__c, Base_Station__c FROM Sensor__c];
        System.assertEquals(4, sensors.size(), 'Sensors count mismatch.');
    }

    @IsTest
    static void testGetCSVBody() {
        // Setup test data
        ContentVersion cv = new ContentVersion(
            Title = 'Test CSV',
            PathOnClient = 'test.csv',
            VersionData = Blob.valueOf('model,status,bsName\nModel1,Active,BS1')
        );
        insert cv;

        ContentDocument contentDoc = [SELECT Id FROM ContentDocument LIMIT 1];

        // Test the getCSVBody method
        String csvBody = CSVHandler.getCSVBody(contentDoc.Id);
        System.assertNotEquals(null, csvBody, 'CSV body should not be null.');
    }

    @IsTest
    static void testParseCSV() {
        // Test data
        String csvBody = 'model,status,bsName\nModel1,Active,BS1\nModel2,Inactive,BS2\nModel3,Active\nModel4,Inactive,BS4';
        Map<String, List<CSVHandler.SensorInfo>> bsNameToSensorsMap = new Map<String, List<CSVHandler.SensorInfo>>();
        List<CSVHandler.SensorInfo> sensorsWithoutBS = new List<CSVHandler.SensorInfo>();

        // Test the parseCSV method
        CSVHandler.parseCSV(csvBody, bsNameToSensorsMap, sensorsWithoutBS);

        System.assertEquals(3, bsNameToSensorsMap.size(), 'Base stations count mismatch.');
        System.assertEquals(1, sensorsWithoutBS.size(), 'Sensors without BS count mismatch.');
    }

    @IsTest
    static void testInsertData() {
        // Test data
        Map<String, List<CSVHandler.SensorInfo>> bsNameToSensorsMap = new Map<String, List<CSVHandler.SensorInfo>>();
        List<CSVHandler.SensorInfo> sensorsWithoutBS = new List<CSVHandler.SensorInfo>();

        bsNameToSensorsMap.put('BS1', new List<CSVHandler.SensorInfo>{
            new CSVHandler.SensorInfo('Model1', 'Active', 'BS1')
        });

        sensorsWithoutBS.add(new CSVHandler.SensorInfo('Model2', 'Inactive'));

        Test.startTest();
            CSVHandler.insertData(bsNameToSensorsMap, sensorsWithoutBS);
        Test.stopTest();

        // Assert the results
        List<Base_Station__c> baseStations = [SELECT Id, Name FROM Base_Station__c];
        System.assertEquals(1, baseStations.size(), 'Base stations count mismatch.');

        List<Sensor__c> sensors = [SELECT Id, Sensor_model__c, Status__c, Base_Station__c FROM Sensor__c];
        System.assertEquals(2, sensors.size(), 'Sensors count mismatch.');
    }

    @IsTest
    static void testCollectNewBaseStations() {
        // Test data
        Map<String, List<CSVHandler.SensorInfo>> bsNameToSensorsMap = new Map<String, List<CSVHandler.SensorInfo>>();
        bsNameToSensorsMap.put('BS1', new List<CSVHandler.SensorInfo>{
            new CSVHandler.SensorInfo('Model1', 'Active', 'BS1')
        });

        // Test the collectNewBaseStations method
        List<Base_Station__c> newBaseStations = CSVHandler.collectNewBaseStations(bsNameToSensorsMap);

        System.assertEquals(1, newBaseStations.size(), 'New base stations count mismatch.');
    }

    @IsTest
    static void testCollectAllBaseStationIds() {
        // Setup test data
        Base_Station__c bs1 = new Base_Station__c(Name = 'BS1', Status__c = 'Active');
        insert bs1;

        // Test the collectAllBaseStationIds method
        Map<String, Id> bsNameToIdMap = CSVHandler.collectAllBaseStationIds();

        System.assertEquals(1, bsNameToIdMap.size(), 'Base station IDs count mismatch.');
        System.assertEquals(bs1.Id, bsNameToIdMap.get('BS1'), 'Base station ID mismatch.');
    }

    @IsTest
    static void testCollectNewSensors() {
        // Test data
        Map<String, List<CSVHandler.SensorInfo>> bsNameToSensorsMap = new Map<String, List<CSVHandler.SensorInfo>>();
        List<CSVHandler.SensorInfo> sensorsWithoutBS = new List<CSVHandler.SensorInfo>();

        bsNameToSensorsMap.put('BS1', new List<CSVHandler.SensorInfo>{
            new CSVHandler.SensorInfo('Model1', 'Active', 'BS1')
        });

        sensorsWithoutBS.add(new CSVHandler.SensorInfo('Model2', 'Inactive'));

        // Setup base stations
        Base_Station__c bs1 = new Base_Station__c(Name = 'BS1', Status__c = 'Active');
        insert bs1;

        Map<String, Id> bsNameToIdMap = CSVHandler.collectAllBaseStationIds();

        // Test the collectNewSensors method
        List<Sensor__c> newSensors = CSVHandler.collectNewSensors(bsNameToSensorsMap, sensorsWithoutBS, bsNameToIdMap);

        System.assertEquals(2, newSensors.size(), 'New sensors count mismatch.');
        System.assertEquals(bs1.Id, newSensors[0].Base_Station__c, 'Base station ID mismatch for sensor.');
    }

    @IsTest
    static void testParseCSVInsertData_ParsingError() {
        // Setup: Create a ContentVersion with invalid CSV data
        ContentVersion cv = new ContentVersion(
            Title = 'Test CSV',
            PathOnClient = 'test.csv',
            VersionData = Blob.valueOf('model,status,bsName\nModel1,Active,BS1\nInvalidRow\nModel3,Active')
        );
        insert cv;

        ContentDocument newContentDocument = [SELECT Id FROM ContentDocument LIMIT 1];

        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            CSVHandler.parseCSVInsertData(newContentDocument.Id);
        } catch (CSVHandler.CustomException e) {
            exceptionThrown = true;
            System.assert(e.getMessage().contains('Error processing CSV file:'), 'Unexpected exception message: ' + e.getMessage());
        }
        Test.stopTest();

        System.assert(exceptionThrown, 'Exception should have been thrown due to parsing error.');
    }

    @isTest
    static void testGenerateBaseStationData() {
        Test.startTest();
            CSVHandler.generateBaseStationData();
        Test.stopTest();

        List<Base_Station__c> baseStations = [SELECT Id, Name, Status__c FROM Base_Station__c];
        System.assertEquals(5, baseStations.size());
        System.assertEquals('Block A', baseStations[0].Name);
        System.assertEquals('Active', baseStations[0].Status__c);
        System.assertEquals('Block B', baseStations[1].Name);
        System.assertEquals('Inactive', baseStations[1].Status__c);
        System.assertEquals('Block C', baseStations[2].Name);
        System.assertEquals('Active', baseStations[2].Status__c);
        System.assertEquals('Block D', baseStations[3].Name);
        System.assertEquals('Inactive', baseStations[3].Status__c);
        System.assertEquals('Block E', baseStations[4].Name);
        System.assertEquals('Active', baseStations[4].Status__c);

        List<Sensor__c> sensors = [SELECT Id, Sensor_model__c, Base_Station__c FROM Sensor__c];
        System.assertEquals(50, sensors.size());
        for (Integer i = 0; i < sensors.size(); i++) {
            System.assert(sensors[i].Sensor_model__c.startsWith('Model '));
            System.assertNotEquals(null, sensors[i].Base_Station__c);
        }
    }

    @isTest
    static void testDeleteAllData() {
        CSVHandler.generateBaseStationData();

        System.assertEquals(5, [SELECT COUNT() FROM Base_Station__c]);
        System.assertEquals(50, [SELECT COUNT() FROM Sensor__c]);

        Test.startTest();
            CSVHandler.deleteAllData();
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM Base_Station__c]);
        System.assertEquals(0, [SELECT COUNT() FROM Sensor__c]);
    }
}
