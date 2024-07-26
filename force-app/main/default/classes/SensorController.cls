public with sharing class SensorController {
    @AuraEnabled(cacheable=true)
    public static List<Sensor__c> getSensors(Integer limitSize, Integer offset) {
        return [SELECT Id, Base_Station__c, Status__c, Sensor_Model__c FROM Sensor__c LIMIT :limitSize OFFSET :offset];
    }

    @AuraEnabled(cacheable=true)
    public static Integer getSensorCount() {
        return [SELECT COUNT() FROM Sensor__c];
    }

    @AuraEnabled
    public static void deleteSensor(Id sensorId) {
        delete [SELECT Id FROM Sensor__c WHERE Id = :sensorId];
    }

    @AuraEnabled(cacheable=true)
    public static Decimal getDefaultRecordsPerPage() {
        Decimal defaultRecordsPerPage = PaginationSettings__c.getOrgDefaults().Default_Records_Per_Page__c;
        system.debug('defaultRecordsPerPage' + defaultRecordsPerPage);
        return defaultRecordsPerPage;
    }
}