import { LightningElement, track } from 'lwc';
import getSensors from '@salesforce/apex/SensorController.getSensors';
import getSensorCount from '@salesforce/apex/SensorController.getSensorCount';
import deleteSensor from '@salesforce/apex/SensorController.deleteSensor';
import getDefaultRecordsPerPage from '@salesforce/apex/SensorController.getDefaultRecordsPerPage';

export default class SensorTable extends LightningElement {
    @track sensors = [];
    @track totalRecords = 0;
    @track pageSize = 10;
    @track currentPage = 1;
    @track totalPages = 0;
    @track pageSizeOptions = [10, 25, 50, 100, 200];

    connectedCallback() {
        this.initDefaultRecordsPerPage();
    }

    initDefaultRecordsPerPage() {
        getDefaultRecordsPerPage()
            .then((result) => {
                this.pageSize = result || 10;
                this.fetchData();
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
            .then((result) => {
                this.sensors = result;
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
            })
            .catch((error) => {
                console.error('Error fetching sensor count:', error);
            });
    }

    handleDelete(event) {
        const sensorId = event.target.dataset.id;
        deleteSensor({ sensorId: sensorId })
            .then(() => {
                this.fetchData();
            })
            .catch((error) => {
                console.error('Error deleting sensor:', error);
            });
    }

    handlePageSizeChange(event) {
        this.pageSize = parseInt(event.target.value, 10);
        this.currentPage = 1;
        this.fetchData();
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