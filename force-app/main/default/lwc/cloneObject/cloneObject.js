import { LightningElement, wire } from 'lwc';
import getAccounts from '@salesforce/apex/CloneClass.getAccounts';
import cloneAccont from '@salesforce/apex/CloneClass.cloneAccont';
import getAllObjects from '@salesforce/apex/CloneClass.getAllObjects';
import getObjecttFields from '@salesforce/apex/CloneClass.getObjecttFields';
import cloneWithChildren from '@salesforce/apex/CloneClass.cloneWithChildren';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class CloneObject extends LightningElement {
    accountOptions;
    accid;
    valid;
    childlist;
    recordId;
    childarr = [];
    Objectfileds;
    Object = {};

    @wire(getAllObjects)
    AllObjects;

    get AllObjectsOptions() {
        return this.AllObjects.data;
    }

    handleObjects(event) {
        getAccounts({ objectName: event.detail.value }).then((data) => {
            this.accountOptions = data;
        })
    }

    handleChange(event) {
        var inp = this.template.querySelectorAll("lightning-combobox");
        inp.forEach(function(element) {
            if (element.name == "input1") {
                this.accid = element.value;
            }
        }, this);
        cloneAccont({ accountid: this.accid }).then((data) => {
            this.childlist = data;
        });
        getObjecttFields({ objecttid: this.accid }).then((data) => {
            this.Objectfileds = data;
        });
    }

    hanndlecheck(event) {
        this.recordId = event.target.id;
        this.childarr.push(event.target.name);
    }

    handleFiled(event) {
        var inp = this.template.querySelectorAll(".filedClass");
        inp.forEach(function(element) {
            if (event.target.name === element.name) {
                var key = element.name;
                this.Object[key] = element.value;
            }
        }, this);
    }

    viewRecord() {
        cloneWithChildren({
            childList: this.childarr,
            recId: this.recordId,
            arrayfiled: this.Object
        }).then(() => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Cloned record is successfully created',
                    variant: 'success',
                }),
            );
        }).catch(() => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error!',
                    message: 'Somthing went wrong try again',
                    variant: 'error',
                }),
            );
        })
    }

    handlevalidation() {
        var inp = this.template.querySelectorAll("lightning-combobox");
        inp.forEach(function(element) {
            if (element.name == "inputObj") {
                this.valid = element.value;
            }
        }, this);
        if (this.valid == undefined) {
            const errortoast = new ShowToastEvent({
                'title': 'Error!',
                'message': 'Select the Object Name',
                'variant': 'error'
            });
            this.dispatchEvent(errortoast);
        }
    }
}
