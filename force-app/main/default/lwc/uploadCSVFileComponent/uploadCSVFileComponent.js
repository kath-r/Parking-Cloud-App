import { LightningElement } from 'lwc';
import parseCSVInsertData from '@salesforce/apex/CSVHandler.parseCSVInsertData';

export default class uploadCSVFileComponent extends LightningElement {
    handleUploadFinished(event) {
        const uploadedFiles = event.detail.files;
        
        if (uploadedFiles.length > 0) {
            const contentDocumentId = uploadedFiles[0].documentId; // Assuming a single file upload
            console.log('Uploaded file document ID:', contentDocumentId); // Debugging line

            // Call Apex to parse and insert data
            parseCSVInsertData({ contentDocumentId: contentDocumentId })
                .then(result => {
                    // Handle success
                    console.log('Data inserted successfully');
                })
                .catch(error => {
                    // Handle error
                    console.error('Error:', error);
                });
        } else {
            console.error('No files were uploaded.');
        }
    }
}