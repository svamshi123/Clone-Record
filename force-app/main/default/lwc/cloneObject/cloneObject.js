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
    childObject = false;
    recordId;
    childarr = [];
    Objectfileds;
    fieldvalue;
    fieldArray = [];
    jsonFIled = {
        "Name": ''
    }

    @wire(getAllObjects)
    AllObjects;

    get AllObjectsOptions() {
        return this.AllObjects.data;
    }

    handleObjects(event) {
        console.log("hai");
        console.log(event.detail.value);
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
        console.log(this.accid);
        cloneAccont({ accountid: this.accid }).then((data) => {
            console.log(data.objName);
            console.log(data);
            this.childlist = data;
            console.log(this.childlist);
        });
        getObjecttFields({ objecttid: this.accid }).then((data) => {
            console.log(data);
            this.Objectfileds = data;
        });
    }

    hanndlecheck(event) {
        console.log(event.target.name);
        console.log(event.target.id);
        this.recordId = event.target.id;
        this.childObject = true;
        this.childarr.push(event.target.name);
    }

    handleFiled(event) {
        console.log(event.target.name);
        var inp = this.template.querySelectorAll(".filedClass");
        inp.forEach(function(element) {
            if (event.target.name === element.name) {
                //this.jsonFIled.Name = element.value;
                this.fieldArray.push(element.value);
            }
        }, this);
        console.log(this.fieldArray);
    }

    viewRecord() {
        console.log(this.childObject);
        console.log(this.childarr);
        console.log(this.fieldArray);
        console.log(this.recordId);
        cloneWithChildren({
            childList: this.childarr,
            recId: this.recordId,
            arrayfiled: this.fieldArray
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