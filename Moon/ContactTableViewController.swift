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

class ContactTableViewController: UITableViewController, CNContactPickerDelegate, UITextFieldDelegate {
    
    var contacts = [CNContact]()
    var firebaseContact = [(userId: String, phoneNumber: String)]()

    override func viewDidLoad() {
        super.viewDidLoad()
        requestForAccess { (accessGranted) in
            if accessGranted ==  true {
                self.getArrayOfPhoneNumbers({ (phoneNumbers) in
                    self.firebaseContact = phoneNumbers
                })
            }
        }
    }
    
    func getArrayOfPhoneNumbers(handler: (phoneNumbers: [(userId: String, phoneNumber: String)])->()) {
        var firebaseContactTemp = [(userId: String, phoneNumber: String)]()
        rootRef.child("phoneNumbers").observeSingleEventOfType(.Value, withBlock: { (snap) in
            if !(snap.value is NSNull) {
                for child in snap.children {
                    let id = child as! FIRDataSnapshot
                    firebaseContactTemp.append((id.key, id.value as! String))
                    self.searchForContactUsingPhoneNumber(id.value as! String)
                }
                self.firebaseContact = firebaseContactTemp
            }
            }) { (error) in
                print(error)
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        checkIfWeHaveUsersPhoneNumber()
        setUpNavigation()
    }
    
    func findUserIdForPhoneNumber(phoneNumber: String) -> String?  {
        if let index = firebaseContact.indexOf({$0.phoneNumber.componentsSeparatedByCharactersInSet(NSCharacterSet.decimalDigitCharacterSet().invertedSet).joinWithSeparator("") == phoneNumber}) {
            return firebaseContact[index].userId
        } else {
            return nil
        }
    }
    
    func checkIfWeHaveUsersPhoneNumber() {
        currentUser.child("phoneNumber").observeSingleEventOfType(.Value, withBlock: { (snap) in
            if (snap.value is NSNull) {
                promptForPhoneNumber(self)
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
                    
                    let contactsStore = CNContactStore()
                    do {
                        try contactsStore.enumerateContactsWithFetchRequest(CNContactFetchRequest(keysToFetch: keys)) {
                            (contact, cursor) -> Void in
                            if (!contact.phoneNumbers.isEmpty) {
                                let phoneNumberToCompareAgainst = phoneNumber.componentsSeparatedByCharactersInSet(NSCharacterSet.decimalDigitCharacterSet().invertedSet).joinWithSeparator("")
                                let phoneNumberToCompareAgainstWithOneInFront = "1" + phoneNumberToCompareAgainst
                                for phoneNumber in contact.phoneNumbers {
                                    if let phoneNumberStruct = phoneNumber.value as? CNPhoneNumber {
                                        let phoneNumberString = phoneNumberStruct.stringValue
                                        let phoneNumberToCompare = phoneNumberString.componentsSeparatedByCharactersInSet(NSCharacterSet.decimalDigitCharacterSet().invertedSet).joinWithSeparator("")
                                        let phoneNumberToCompareWithOneInFront = "1" + phoneNumberToCompare
                                        
                                        let compareNormal = phoneNumberToCompare == phoneNumberToCompareAgainst
                                        let compareCross1 = phoneNumberToCompare == phoneNumberToCompareAgainstWithOneInFront
                                        let compareCross2 = phoneNumberToCompareWithOneInFront == phoneNumberToCompareAgainst
                                        let compareBothOnes = phoneNumberToCompareWithOneInFront == phoneNumberToCompareAgainstWithOneInFront
                                        
                                        if compareNormal || compareCross1 || compareCross2 || compareBothOnes {
                                            contacts.append(contact)
                                        }
                                    }
                                }
                            }
                        }
                        
                        if !contacts.isEmpty {
                            // Success
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                // Do someting with the contacts in the main queue
                                self.contacts.append(contacts.first!)
                                self.tableView.reloadData()
                            })
                        }
                    }
                    catch {
                        let alertView = SCLAlertView(appearance: K.Apperances.NormalApperance)
                        alertView.showNotice("Error", subTitle: "Unable to fetch contacts.")
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
        return contacts.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("contactCell", forIndexPath: indexPath)
        
        let contact = self.contacts[indexPath.row]
        let formatter = CNContactFormatter()
        
        cell.textLabel?.text = formatter.stringFromContact(contact)
        cell.textLabel?.font = UIFont(name: "Roboto-Bold", size: 18)
        cell.textLabel?.textColor = UIColor.darkGrayColor()
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let contact = self.contacts[indexPath.row]
        let phoneNumber = (contact.phoneNumbers[0].value as! CNPhoneNumber).valueForKey("digits") as! String
        if let userId = findUserIdForPhoneNumber(phoneNumber) {
            performSegueWithIdentifier("contactsToUserProfile", sender: userId)
        } else if let userId = findUserIdForPhoneNumber("1" + (phoneNumber)) {
            performSegueWithIdentifier("contactsToUserProfile", sender: userId)
        } else if let userId = findUserIdForPhoneNumber(String(phoneNumber.characters.dropFirst())) {
            performSegueWithIdentifier("contactsToUserProfile", sender: userId)
        }
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        //clears the back button title
        let backItem = UIBarButtonItem()
        backItem.title = " "
        navigationItem.backBarButtonItem = backItem
        
        if segue.identifier == "contactsToUserProfile" {
            let vc = segue.destinationViewController as! UserProfileViewController
            vc.userID = sender as! String
        }
        
    }
    
    
    func setUpNavigation(){
        
        //navigation controller set up
        self.navigationItem.title = "Contacts"
        navigationController?.navigationBar.backIndicatorImage = UIImage(named: "Back_Arrow")
        navigationController?.navigationBar.backIndicatorTransitionMaskImage = UIImage(named: "Back_Arrow")
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        self.navigationController?.navigationBar.barStyle = UIBarStyle.Black
        self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        
        //Top View set up
        let header = "Header_base.png"
        let headerImage = UIImage(named: header)
        self.navigationController!.navigationBar.setBackgroundImage(headerImage, forBarMetrics: .Default)
        
    }
    
    // MARK: - Textfield delegate
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        // Used to format the phone number entered into the first prompted text box
        if textField.tag == 69 {
            return shouldPhoneNumberTextChangeHelperMethod(textField, range: range, string: string)
        }
        
        // Used to prevent the user from entering in more than four characters
        if textField.tag == 169 {
            return shouldPinNumberTextFieldChange(textField, range: range, string: string)
        }
        
        return true
    }
    

}
