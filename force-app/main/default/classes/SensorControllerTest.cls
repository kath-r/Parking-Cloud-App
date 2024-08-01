@isTest
public class SensorControllerTest {
    @testSetup
    static void setup() {
        // Create test data for Base_Station__c
        Base_Station__c baseStation1 = new Base_Station__c(Name = 'Base Station 1');
        insert baseStation1;

        Base_Station__c baseStation2 = new Base_Station__c(Name = 'Base Station 2');
        insert baseStation2;

        // Create test data for Sensor__c
        List<Sensor__c> testSensors = new List<Sensor__c>();
        Sensor__c sensor1 = new Sensor__c(Sensor_Model__c = 'Model 1', Status__c = 'Active', Base_Station__c = baseStation1.Id);
        Sensor__c sensor2 = new Sensor__c(Sensor_Model__c = 'Model 2', Status__c = 'Inactive', Base_Station__c = baseStation2.Id);
        
        Sensor__c sensor3 = new Sensor__c(Sensor_Model__c = 'Model 3', Status__c = 'Active');
        Sensor__c sensor4 = new Sensor__c(Sensor_Model__c = 'Model 4', Status__c = 'Inactive');
        testSensors.add(sensor1);
        testSensors.add(sensor2);
        testSensors.add(sensor3);
        testSensors.add(sensor4);
        insert testSensors;
    }

    @isTest
    static void testGetBaseStationName() {
        // Fetch the Id of the first Base Station
        Id baseStationId = [SELECT Id FROM Base_Station__c LIMIT 1].Id;

        // Call the method and assert the result
        Test.startTest();
        String baseStationName = SensorController.getBaseStationName(baseStationId);
        Test.stopTest();

        System.assertNotEquals(null, baseStationName);
        System.assertEquals('Base Station 1', baseStationName);
    }

    @isTest
    static void testGetSensorData() {
        // Call the method and assert the result
        Test.startTest();
        List<Sensor__c> sensors = SensorController.getSensorData();
        Test.stopTest();

        System.assertEquals(4, sensors.size());
        System.assertEquals('Model 1', sensors[0].Sensor_Model__c);
        System.assertEquals('Active', sensors[0].Status__c);
    }

    @isTest
    static void testGetSensors() {
        // Call the method with limit and offset and assert the result
        Test.startTest();
        List<Sensor__c> sensors = SensorController.getSensors(1, 0);
        Test.stopTest();

        System.assertEquals(1, sensors.size());
        System.assertEquals('Model 1', sensors[0].Sensor_Model__c);
        System.assertEquals('Active', sensors[0].Status__c);
    }

    @isTest
    static void testGetSensorCount() {
        // Call the method and assert the result
        Test.startTest();
        Integer sensorCount = SensorController.getSensorCount();
        Test.stopTest();

        System.assertEquals(4, sensorCount);
    }

    @isTest
    static void testDeleteSensor() {
        // Fetch the Id of the first sensor
        Id sensorId = [SELECT Id FROM Sensor__c LIMIT 1].Id;
        String error;

        // Call the method to delete the sensor
        Test.startTest();
        SensorController.deleteSensor(sensorId);
        Test.stopTest();

        // Assert the sensor is deleted
        try {
            Sensor__c deletedSensor = [SELECT Id FROM Sensor__c WHERE Id = :sensorId LIMIT 1];
        } catch (Exception e) {
            system.debug('deletedSensor' + e);
            error = e.getMessage();
        }

        System.assertEquals('List has no rows for assignment to SObject', error);
    }

    @isTest
    static void testGetDefaultRecordsPerPage() {
        // Call the method and assert the result
        Test.startTest();
        Decimal defaultRecords = SensorController.getDefaultRecordsPerPage();
        Test.stopTest();

        System.assertEquals(11, defaultRecords);
    }
}
