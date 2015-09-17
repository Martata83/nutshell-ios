//
//  User.swift
//  
//
//  Created by Brian King on 9/14/15.
//
//

import Foundation
import CoreData
import SwiftyJSON

class User: NSManagedObject {
    class func fromJSON(json: JSON, moc: NSManagedObjectContext) -> User? {
        if let entityDescription = NSEntityDescription.entityForName("User", inManagedObjectContext: moc) {
            let me = NSManagedObject(entity: entityDescription, insertIntoManagedObjectContext: nil) as! User
            
            me.userid = json["userid"].string
            me.username = json["username"].string
            me.fullName = json["fullName"].string
            
            return me
        }
        
        return nil
    }
}