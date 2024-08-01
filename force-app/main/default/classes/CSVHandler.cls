public with sharing class CSVHandler {
    @TestVisible
    private class SensorInfo {
        public String model;
        public String status;
        public String bsName;

        public SensorInfo(String model, String status, String bsName) {
            this.model = model;
            this.status = status;
            this.bsName = bsName;
        }

        public SensorInfo(String model, String status) {
            this.model = model;
            this.status = status;
            this.bsName = null;
        }
    }

    // Custom Exception class for specific errors
    public class CustomException extends Exception {}

    @AuraEnabled
    public static void parseCSVInsertData(Id contentDocumentId) {
        try {
            String csvBody = getCSVBody(contentDocumentId);
            system.debug('csvBody: '+ csvBody);
            if (csvBody == null) {
                throw new CustomException('ContentVersion not found for ContentDocumentId: ' + contentDocumentId);
            }

            Map<String, List<SensorInfo>> bsNameToSensorsMap = new Map<String, List<SensorInfo>>();
            List<SensorInfo> sensorsWithoutBS = new List<SensorInfo>();

            parseCSV(csvBody, bsNameToSensorsMap, sensorsWithoutBS);
            insertData(bsNameToSensorsMap, sensorsWithoutBS);

        } catch (Exception e) {
            throw new CustomException('Error processing CSV file: ' + e.getMessage());
        }
    }

    @TestVisible
    private static String getCSVBody(Id contentDocumentId) {
        ContentVersion contentVersion = [
            SELECT VersionData
            FROM ContentVersion
            WHERE ContentDocumentID = :contentDocumentId
            LIMIT 1
        ];
        return contentVersion != null ? contentVersion.VersionData.toString() : null;
    }

    @TestVisible
    private static void parseCSV(String csvBody, Map<String, List<SensorInfo>> bsNameToSensorsMap, List<SensorInfo> sensorsWithoutBS) {
        List<String> csvRows = csvBody.split('\n');
        Boolean isFirstRow = true;

        for (String row : csvRows) {
            if (isFirstRow) {
                isFirstRow = false;
                continue;
            }
            String[] fields = row.split(',');
            if (fields.size() == 3) {
                SensorInfo sensorInfo = new SensorInfo(fields[0].trim(), fields[1].trim(), fields[2].trim());
                if (!bsNameToSensorsMap.containsKey(sensorInfo.bsName)) {
                    bsNameToSensorsMap.put(sensorInfo.bsName, new List<SensorInfo>());
                }
                bsNameToSensorsMap.get(sensorInfo.bsName).add(sensorInfo);
            } else if (fields.size() == 2) {
                SensorInfo sensorInfo = new SensorInfo(fields[0].trim(), fields[1].trim());
                sensorsWithoutBS.add(sensorInfo);
            } else {
                throw new CustomException('Unexpected row size in csv row: ' + row);
            }
        }
    }

    @TestVisible
    private static void insertData(Map<String, List<SensorInfo>> bsNameToSensorsMap, List<SensorInfo> sensorsWithoutBS) {
        List<Base_Station__c> newBaseStations = collectNewBaseStations(bsNameToSensorsMap);
        if (!newBaseStations.isEmpty()) {
            upsert newBaseStations;
        }

        Map<String, Id> bsNameToIdMap = collectAllBaseStationIds();
        List<Sensor__c> newSensors = collectNewSensors(bsNameToSensorsMap, sensorsWithoutBS, bsNameToIdMap);

        if (!newSensors.isEmpty()) {
            upsert newSensors;
        }
    }

    @TestVisible
    private static List<Base_Station__c> collectNewBaseStations(Map<String, List<SensorInfo>> bsNameToSensorsMap) {
        List<Base_Station__c> existingBS = [
            SELECT Id, Name
            FROM Base_Station__c
            WHERE Name IN :bsNameToSensorsMap.keySet()
        ];
        Map<String, Base_Station__c> existingBSMap = new Map<String, Base_Station__c>();
        for (Base_Station__c baseStation : existingBS) {
            existingBSMap.put(baseStation.Name, baseStation);
        }

        List<Base_Station__c> newBaseStations = new List<Base_Station__c>();
        for (String bsName : bsNameToSensorsMap.keySet()) {
            if (!existingBSMap.containsKey(bsName)) {
                Base_Station__c newBS = new Base_Station__c();
                newBS.Name = bsName;
                newBS.Status__c = bsNameToSensorsMap.get(bsName)[0].status;
                newBaseStations.add(newBS);
            }
        }
        return newBaseStations;
    }

    @TestVisible
    private static Map<String, Id> collectAllBaseStationIds() {
        List<Base_Station__c> allBaseStations = [
            SELECT Id, Name
            FROM Base_Station__c
        ];
        Map<String, Id> bsNameToIdMap = new Map<String, Id>();
        for (Base_Station__c bs : allBaseStations) {
            bsNameToIdMap.put(bs.Name, bs.Id);
        }
        return bsNameToIdMap;
    }

    @TestVisible
    private static List<Sensor__c> collectNewSensors(Map<String, List<SensorInfo>> bsNameToSensorsMap, List<SensorInfo> sensorsWithoutBS, Map<String, Id> bsNameToIdMap) {
        List<Sensor__c> newSensors = new List<Sensor__c>();

        for (String bsName : bsNameToSensorsMap.keySet()) {
            for (SensorInfo sensorInfo : bsNameToSensorsMap.get(bsName)) {
                Sensor__c newSensor = new Sensor__c();
                newSensor.Base_Station__c = bsNameToIdMap.get(bsName);
                newSensor.Status__c = sensorInfo.status;
                newSensor.Sensor_model__c = sensorInfo.model;
                newSensors.add(newSensor);
            }
        }

        for (SensorInfo sensorInfo : sensorsWithoutBS) {
            Sensor__c newSensor = new Sensor__c();
            newSensor.Status__c = sensorInfo.status;
            newSensor.Sensor_model__c = sensorInfo.model;
            newSensors.add(newSensor);
        }
        return newSensors;
    }

    @AuraEnabled
    public static void generateBaseStationData() {
        List<Base_Station__c> baseStations = new List<Base_Station__c>();
        List<Sensor__c> sensors = new List<Sensor__c>();

        String[] names = new String[]{'Block A', 'Block B', 'Block C', 'Block D', 'Block E'};
        String[] statuses = new String[]{'Active', 'Inactive'};
        
        for (Integer i = 0; i < names.size(); i++) {
            Base_Station__c baseStation = new Base_Station__c(
                Name = names[i],
                Status__c = statuses[Math.Mod(i, statuses.size())]
            );
            baseStations.add(baseStation);
        }

        insert baseStations;

        for (Base_Station__c bs : baseStations) {
            for (Integer j = 1; j <= 10; j++) {
                Sensor__c sensor = new Sensor__c(
                    Sensor_model__c = 'Model ' + j,
                    Base_Station__c = bs.Id,
                    Status__c = bs.Status__c
                );
                sensors.add(sensor);
            }
        }

        insert sensors;
    }

    @AuraEnabled
    public static void deleteAllData() {
        List<Base_Station__c> baseStations = [SELECT Id FROM Base_Station__c];
        List<Sensor__c> sensors = [SELECT Id FROM Sensor__c];

        delete sensors;
        delete baseStations;
    }
}
