Task name: 
CSV to SF (Parking Cloud App)

Task description:
It is necessary to develop an application that will download, store and display data about the status of parking space occupancy sensors. The application should also determine the current status for the sensors depending on the status of its base station. Sensor data should be downloaded manually in csv format.


Data model:
Create next  “Custom objects”:
1. Sensor__с
fields:
Name(Auto num)
Base Station
Status (Picklist: Active, Inactive), 
Sensor model (text).


2. Base Station__с
fields:
Name
Status (Picklist: Active, Inactive, Broken)

3. You should prepare test data for at least 50 records for Sensors and 5 Base Stations (CSV file).


P.s. Use your creativity and craziest ideas for naming :)



A component that displays the status of the sensors:
1. Develop LWC, where you’ll have button to upload CSV file с ','(comma) as separator. (https://en.wikipedia.org/wiki/Comma-separated_values) or (https://tools.ietf.org/html/rfc4180)
File should contain data about parking sensors.
After file upload, data should be inserted in database and displayed in a table (Columns : Sensor Model, Status, Base Station.Name). 

2. Users should have the ability to delete records from table (and database as well). 

3. Add pagination functionality to the table with ability to switch on first/last pages and go to next/previous page. User should also have the ability to select the number of records per page(10,25,50,100,200). 
Default number of records per page should be stored in Custom Settings or Custom Metadata Types

Automatization:
1. Sensor can be only related to Base Station with Active, Inactive status. 
If Base Station status is set to 
Inactive -> all sensors related to this Station should be set to Inactive
Broken -> sensors should be unassigned and set to Inactive
Sensors without Base Station should be only in Inactive status. If Sensor is assigned to Base Station(Status = Active), Sensor Status should be set to Active (use process builder/flow).


Necessary to use:
1) Custom Object with relationships: Base_Station__c, Sensor__c
2) SOQL queries
3) Unit-test coverage: at least 80%
4) Pagination
5) Custom Settings or Custom Metadata Types