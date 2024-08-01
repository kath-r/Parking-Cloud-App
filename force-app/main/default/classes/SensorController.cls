public with sharing class SensorController {
    @AuraEnabled(cacheable=true)
    public static String getBaseStationName(Id bsId) {
        String result;
        List<Base_Station__c> baseStations = [SELECT Id, Name FROM Base_Station__c];
        Map<Id, String> baseStationMap = new Map<Id, String>();
        for (Base_Station__c bs : baseStations) {
            baseStationMap.put(bs.Id, bs.Name);
        }
        return baseStationMap.get(bsId);
    }


    @AuraEnabled(cacheable=true)
    public static List<Sensor__c> getSensorData() {
        List<Sensor__c> fullSensorList = [SELECT Sensor_model__c, Status__c, Base_Station__r.Name FROM Sensor__c];
        return fullSensorList;
    }

    @AuraEnabled
    public static List<Sensor__c> getSensors(Integer limitSize, Integer offset) {
        List<Sensor__c> sensorsToView = [SELECT Id,  Status__c, Base_Station__c, Base_Station__r.Name, Sensor_Model__c FROM Sensor__c LIMIT :limitSize OFFSET :offset];
        return sensorsToView;
    }

    @AuraEnabled(cacheable=true)
    public static Integer getSensorCount() {
        Integer sensorCount = [SELECT COUNT() FROM Sensor__c];
        return sensorCount;
    }

    @AuraEnabled
    public static void deleteSensor(Id sensorId) {
        delete [SELECT Id FROM Sensor__c WHERE Id = :sensorId];
    }

    @AuraEnabled(cacheable=true)
    public static Decimal getDefaultRecordsPerPage() {
        Decimal defaultRecords = [SELECT Default_Records_Per_Page__c FROM Pagination_Settings__mdt LIMIT 1].Default_Records_Per_Page__c;
        return defaultRecords;
    }
}