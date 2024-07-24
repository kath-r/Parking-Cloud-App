public with sharing class CSVHandler {

    private class SensorInfo {
        public String model;
        public String status;
        public String bsName;

        public SensorInfo(String model, String status, String bsName) {
            this.model = model;
            this.status = status;
            this.bsName = bsName;
        }
    }

    @AuraEnabled
    public static void parseCSVInsertData(Id contentDocumentId) {

        //system.debug('recieved docId: ' + contentDocumentId);
        ContentVersion contentVersion = [
            SELECT VersionData
            FROM ContentVersion
            WHERE ContentDocumentID = :contentDocumentId
            LIMIT 1
        ];

        String csvBody = contentVersion.VersionData.toString();

        List<Sensor__c> uploadedSensors = new List<Sensor__c>();
        List<Base_Station__c> uploadedBS = new List<Base_Station__c>();

        List<String> csvRows = csvBody.split('\n');
        Boolean isFirstRow = true;

        // Map to sort sensors via the same bs names
        Map<String, List<SensorInfo>> bsNameToSensorsMap = new Map<String, List<SensorInfo>>();
        for (String row : csvRows) {
            if(isFirstRow) {
                isFirstRow = false;
                continue;
            }
            String[] fields = row.split(',');
            if(fields.size() == 3) {
                SensorInfo sensorInfo = new sensorInfo(fields[0].trim(), fields[1].trim(), fields[2].trim());
                if(!bsNameToSensorsMap.containsKey(sensorInfo.bsName)) {
                    bsNameToSensorsMap.put(sensorInfo.bsName, new List<sensorInfo>());
                }
                bsNameToSensorsMap.get(sensorInfo.bsName).add(sensorInfo);
            }
        }

        // collect all the existing base stations in DB
        List<Base_Station__c> existingBS = [
            SELECT Id, Name
            FROM Base_Station__c
            WHERE Name IN :bsNameToSensorsMap.keySet()
        ];
        Map<String, Base_Station__c> existingBSMap = new Map<String, Base_Station__c>();
        for(Base_Station__c baseStation : existingBS) {
            existingBSMap.put(baseStation.Name, baseStation);
        }

        // collect all non-existing in DN base stations
        List<Base_Station__c> newBaseStations = new List<Base_Station__c>();
        for(String bsName : bsNameToSensorsMap.keySet()){
            if(!existingBSMap.containsKey(bsName)) {
                Base_Station__c newBS = new Base_Station__c();
                newBS.Name = bsName;
                newBS.Status__c = bsNameToSensorsMap.get(bsName)[0].status;
                newBaseStations.add(newBS);
            }
        }

        if(!newBaseStations.isEmpty()){
            upsert newBaseStations;
        }

        //Get all BS Ids and map them to quick access
        List<Base_Station__c> allBaseStations = [
            SELECT Id, Name
            FROM Base_Station__c
        ];

        Map<String, Id> bsNameToIdMap = new Map<String, Id>();
        for(Base_Station__c bs : allBaseStations) {
            bsNameToIdMap.put(bs.Name, bs.Id);
        }

        List<Sensor__c> newSensors = new List<Sensor__c>();
        for(String bsName : bsNameToSensorsMap.keySet()) {
            for(SensorInfo sensorInfo : bsNameToSensorsMap.get(bsName)) {
                Sensor__c newSensor = new Sensor__c();
                newSensor.Base_Station__c = bsNameToIdMap.get(bsName);
                newSensor.Status__c = sensorInfo.status;
                newSensor.Sensor_model__c = sensorInfo.model;
                newSensors.add(newSensor);
            }
        }

        if(!newSensors.isEmpty()) {
            upsert newSensors;
        }
    }
}