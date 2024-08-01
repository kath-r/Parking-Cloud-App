import { LightningElement, wire } from 'lwc';
import getSensorData from '@salesforce/apex/SensorController.getSensorData';
import parseCSVInsertData from '@salesforce/apex/CSVHandler.parseCSVInsertData';
import generateBaseStationData from '@salesforce/apex/CSVHandler.generateBaseStationData';
import deleteAllData from '@salesforce/apex/CSVHandler.deleteAllData';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class DownloadCSVFileComponent extends LightningElement {
    sensorData;

    @wire(getSensorData)
    wiredSensorData({ error, data }) {
        if (data) {
            this.sensorData = data;
        } else if (error) {
            console.error('Error fetching sensor data in download component:', error);
        }
    }

    downloadCSV() {
        if (this.sensorData) {
            let csv = 'Model,Status,Base Station Name\n';
            this.sensorData.forEach(sensor => {
                let bsname = sensor.Base_Station__r ? sensor.Base_Station__r.Name : '';
                try {
                    csv += `${sensor.Sensor_model__c},${sensor.Status__c},${bsname}\n`;
                } catch (error) {
                    console.log('error: ' + error);
                }
            });
            console.log('csv' + csv);
            const hiddenElement = document.createElement('a');
            hiddenElement.href = 'data:text/csv;charset=utf-8,' + encodeURI(csv);
            hiddenElement.target = '_self';
            hiddenElement.download = 'sensor_status.csv';
            document.body.appendChild(hiddenElement);
            hiddenElement.click();
            document.body.removeChild(hiddenElement);
        } else {
            console.error('No sensor data available for download.');
        }
    }

    handleUploadFinished(event) {
        const uploadedFiles = event.detail.files;
        
        if (uploadedFiles.length > 0) {
            const contentDocumentId = uploadedFiles[0].documentId; 
            console.log('Uploaded file document ID:', contentDocumentId); 

            parseCSVInsertData({ contentDocumentId: contentDocumentId })
                .then(result => {
                    window.location.reload();
                })
                .catch(error => {
                    this.showToast('Error', 'Error while parsing data: ' + error.body.message, 'error');
                });
        } else {
            this.showToast('Error', 'Error while uploading file ', 'error');
        }
    }

    deleteData() {
        deleteAllData()
            .then(() => {
                window.location.reload();
            })
            .catch(error => {
                this.showToast('Error', 'Error deleting data: ' + error.body.message, 'error');
            });
    }

    generateData() {
        generateBaseStationData()
            .then(() => {
                window.location.reload();
            })
            .catch(error => {
                this.showToast('Error', 'Error generating data: ' + error.body.message, 'error');
            });
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title,
            message,
            variant,
        });
        this.dispatchEvent(event);
    }
}