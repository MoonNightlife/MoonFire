//
//  ContactTableViewController.swift
//  Moon
//
//  Created by Evan Noble on 9/12/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import UIKit
import ContactsUI
import Firebase
import SCLAlertView

class ContactTableViewController: UITableViewController, CNContactPickerDelegate {
    
    var objects = [CNContact]()

    override func viewDidLoad() {
        super.viewDidLoad()
        requestForAccess { (accessGranted) in
            if accessGranted ==  true {
                self.searchForContactUsingPhoneNumber("3367458849")
            }
        }
//        let contactPickerViewController = CNContactPickerViewController()
//        
//        contactPickerViewController.predicateForEnablingContact = NSPredicate(format: "birthday != nil")
//        
//        contactPickerViewController.delegate = self
//        
//        presentViewController(contactPickerViewController, animated: true, completion: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        checkIfWeHaveUsersPhoneNumber()
    }
    
    func checkIfWeHaveUsersPhoneNumber() {
        currentUser.child("phoneNumber").observeSingleEventOfType(.Value, withBlock: { (snap) in
            if (snap.value is NSNull) {
                let alertView = SCLAlertView(appearance: K.Apperances.NormalApperance)
                let phoneNumber = alertView.addTextField()
                alertView.addButton("Save", action: {
                    currentUser.child("phoneNumber").setValue(phoneNumber.text!)
                })
                alertView.showNotice("Enter Phonennmber", subTitle: "Enter your phone number so users can find you more easily.")
            }
        }) { (error) in
            print(error)
        }
    }

    // MARK: - Contact methods
    func searchForContactUsingPhoneNumber(phoneNumber: String) {
        
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0), { () -> Void in
            self.requestForAccess { (accessGranted) -> Void in
                if accessGranted {
                    let keys = [CNContactFormatter.descriptorForRequiredKeysForStyle(.FullName), CNContactPhoneNumbersKey]
                    var contacts = [CNContact]()
                    var message: String!
                    
                    let contactsStore = CNContactStore()
                    do {
                        try contactsStore.enumerateContactsWithFetchRequest(CNContactFetchRequest(keysToFetch: keys)) {
                            (contact, cursor) -> Void in
                            if (!contact.phoneNumbers.isEmpty) {
                                let phoneNumberToCompareAgainst = phoneNumber.componentsSeparatedByCharactersInSet(NSCharacterSet.decimalDigitCharacterSet().invertedSet).joinWithSeparator("")
                                for phoneNumber in contact.phoneNumbers {
                                    if let phoneNumberStruct = phoneNumber.value as? CNPhoneNumber {
                                        let phoneNumberString = phoneNumberStruct.stringValue
                                        let phoneNumberToCompare = phoneNumberString.componentsSeparatedByCharactersInSet(NSCharacterSet.decimalDigitCharacterSet().invertedSet).joinWithSeparator("")
                                        if phoneNumberToCompare == phoneNumberToCompareAgainst {
                                            contacts.append(contact)
                                        }
                                    }
                                }
                            }
                        }
                        
                        if contacts.count == 0 {
                            message = "No contacts were found matching the given phone number."
                        }
                    }
                    catch {
                        message = "Unable to fetch contacts."
                    }
                    
                    if message != nil {
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            self.showMessage(message)
                        })
                    }
                    else {
                        // Success
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            // Do someting with the contacts in the main queue
                            self.objects = contacts
                            self.tableView.reloadData()
                            //print(contacts) // Will print all contact info for each contact (multiple line is, for example, there are multiple phone numbers or email addresses)
                            let contact = contacts[0] // For just the first contact (if two contacts had the same phone number)
                            //print(contact.givenName) // Print the "first" name
                            //print(contact.familyName) // Print the "last" name
                            print((contact.phoneNumbers[0].value as! CNPhoneNumber).valueForKey("digits") as! String)
                        })
                    }
                }
            }
        })
    }
    
    func requestForAccess(completionHandler: (accessGranted: Bool) -> Void) {
        // Get authorization
        let authorizationStatus = CNContactStore.authorizationStatusForEntityType(CNEntityType.Contacts)
        
        // Find out what access level we have currently
        switch authorizationStatus {
        case .Authorized:
            completionHandler(accessGranted: true)
            
        case .Denied, .NotDetermined:
            CNContactStore().requestAccessForEntityType(CNEntityType.Contacts, completionHandler: { (access, accessError) -> Void in
                if access {
                    completionHandler(accessGranted: access)
                }
                else {
                    if authorizationStatus == CNAuthorizationStatus.Denied {
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            let message = "\(accessError!.localizedDescription)\n\nPlease allow the app to access your contacts through the Settings."
                            self.showMessage(message)
                        })
                    }
                }
            })
            
        default:
            completionHandler(accessGranted: false)
        }
    }
    
    func showMessage(message: String) {
        // Create an Alert
        let alertController = UIAlertController(title: "Alert", message: message, preferredStyle: UIAlertControllerStyle.Alert)
        
        // Add an OK button to dismiss
        let dismissAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default) { (action) -> Void in
        }
        alertController.addAction(dismissAction)
        
        // Show the Alert
        self.presentViewController(alertController, animated: true, completion: nil)
    }

    // MARK: - Table view data source
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return objects.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("contactCell", forIndexPath: indexPath)
        
        let contact = self.objects[indexPath.row]
        let formatter = CNContactFormatter()
        
        cell.textLabel?.text = formatter.stringFromContact(contact)
        cell.detailTextLabel?.text = (contact.phoneNumbers[0].value as! CNPhoneNumber).valueForKey("digits") as? String
        
        return cell
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
