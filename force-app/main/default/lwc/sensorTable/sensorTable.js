import { LightningElement, track, wire, api } from 'lwc';
import getSensors from '@salesforce/apex/SensorController.getSensors';
import getBaseStationName from '@salesforce/apex/SensorController.getBaseStationName';
import getSensorCount from '@salesforce/apex/SensorController.getSensorCount';
import deleteSensor from '@salesforce/apex/SensorController.deleteSensor';
import getDefaultRecordsPerPage from '@salesforce/apex/SensorController.getDefaultRecordsPerPage';


const actions = [
    { label: 'Delete', name: 'delete' },
];

const columns = [
    { label: 'Model', fieldName: 'Sensor_model__c'},
    { label: 'Status', fieldName: 'Status__c'},
    { label: 'Base Station Name', fieldName: 'Base_Station_Name'},
    {
        type: 'action',
        typeAttributes: { rowActions: actions },
    },
];


export default class SensorTable extends LightningElement {
    
    @track sensors;

    @track totalRecords = 0;
    @track pageSize = 10;
    @track currentPage = 1;
    @track totalPages;

    @track options = [
        {label: 'Default page size', value: ''},
        {label:'10', value: '10'},
        {label:'25', value: '25'},
        {label:'50', value: '50'},
        {label:'100', value: '100'},
        {label:'200', value: '200'},
    ];

    handleChange(event) {
        console.log('this.value currentTarget ' + event.currentTarget.value);
        console.log('this.pageSize ' + this.pageSize);
        this.value = event.detail.value;
        console.log('page size change works');
        console.log('this.pageSize: ' + this.pageSize);
        this.pageSize = parseInt(event.detail.value);
        this.currentPage = 1;
        this.fetchData();
    }
    
    columns = columns;

    connectedCallback() {
        this.initDefaultRecordsPerPage();
    }

    initDefaultRecordsPerPage() {
        getDefaultRecordsPerPage()
            .then((result) => {
                this.pageSize = result || 10;
                this.fetchData();
                this.options[0].label = 'Default page size: ' + this.pageSize;
                this.options[0].value = this.pageSize;
            })
            .catch((error) => {
                console.error('Error fetching default records per page:', error);
                this.pageSize = 10;
                this.fetchData();
            });
    }

    fetchData() {
        const offset = (this.currentPage - 1) * this.pageSize;
        getSensors({ limitSize: this.pageSize, offset: offset })
            .then(result => {
                console.log('Raws Data:', result); 
                
                // Map over the result to create an array of promises
                const promises = result.map(row => {
                    return getBaseStationName({ bsId: row.Base_Station__c })
                        .then(bsName => {
                            console.log('result of function: ' + bsName);
                            row.Base_Station_Name = bsName;
                            return row; // Return the updated row
                        })
                        .catch((error) => {
                            console.error('The name of Base Station was not found:', error);
                            row.Base_Station_Name = null; // Optionally handle error case
                            return row; // Return the row even if there was an error
                        });
                });
    
                // Wait for all promises to resolve
                return Promise.all(promises);
            })
            .then(updatedResult => {
                this.sensors = updatedResult;
                console.log('modifiedData:', this.sensors); 
                this.updateTotalRecords();
            })
            .catch((error) => {
                console.error('Error fetching sensors:', error);
            });
    }

    updateTotalRecords() {
        getSensorCount()
            .then((result) => {
                this.totalRecords = result;
                this.totalPages = Math.ceil(this.totalRecords / this.pageSize);
                console.log('totalPages: ' + totalPages);
            })
            .catch((error) => {
                console.error('Error fetching sensor count:', error);
            });
    }

    handleRowAction(event) {
        const action = event.detail.action;
        const sensorId = event.detail.row.Id;
        switch (action.name) {
            case 'delete':
                deleteSensor({ sensorId: sensorId })
                .then(() => {
                    this.fetchData();
                })
                .catch((error) => {
                    console.error('Error deleting sensor:', error);
                });
                break;
            default:
        }
    }

    handlePreviousPage() {
        if (this.currentPage > 1) {
            this.currentPage -= 1;
            this.fetchData();
        }
    }

    handleNextPage() {
        if (this.currentPage < this.totalPages) {
            this.currentPage += 1;
            this.fetchData();
        }
    }

    handleFirstPage() {
        this.currentPage = 1;
        this.fetchData();
    }

    handleLastPage() {
        this.currentPage = this.totalPages;
        this.fetchData();
    }
}