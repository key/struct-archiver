//
//  StructArchiver.swift
//  StructArchiver
//
//  Created by naru on 2016/05/24.
//  Copyright © 2016年 naru. All rights reserved.
//

import Foundation

/// Closure to unarchive data
public typealias ArchiveUnarchiveProcedure = (_ data: Data) -> Archivable

/// Closure to restore struct from unarchived dictionary
public typealias ArchiveRestoreProcedure = (_ dictionary: ArchivableDictionary) -> Archivable

/// Class to store procedures for Archive.
open class StructArchiver {
    
    /// Return shared archiver.
    open static let defaultArchiver: StructArchiver = StructArchiver()
    
    /// Store procedure to unarchive data.
    fileprivate var unarchiveProcedures: [String: ArchiveUnarchiveProcedure] = [String: ArchiveUnarchiveProcedure]()
    
    /// Store procedure to restore data.
    fileprivate var restoreProcedures: [String: ArchiveRestoreProcedure] = [String: ArchiveRestoreProcedure]()
    
    /// Register procedure to unarchive data.
    /// - parameter identifier: string to specify struct
    /// - parameter procedure: procedure to store
    open class func registerUnarchiveProcedure(identifier: String, procedure: @escaping ArchiveUnarchiveProcedure) {
        self.defaultArchiver.unarchiveProcedures[identifier] = procedure
    }
    
    /// Register procedure to restore data.
    /// - parameter identifier: string to specify struct
    /// - parameter procedure: procedure to store
    open class func registerRestoreProcedure(identifier: String, procedure: @escaping ArchiveRestoreProcedure) {
        self.defaultArchiver.restoreProcedures[identifier] = procedure
    }
    
    /// Return stored procedure to unarchive.
    /// - parameter identifier: string to specify struct
    /// - returns: stored procedure or nil if procedure for identifier is not stored
    open func unarchiveProcedure(identifier: String) -> ArchiveUnarchiveProcedure? {
        guard let procedure: ArchiveUnarchiveProcedure = self.unarchiveProcedures[identifier] else {
            return nil
        }
        return procedure
    }
    
    /// Return stored procedure to retore struct.
    /// - parameter identifier: string to specify struct
    /// - returns: stored procedure or nil if procedure for identifier is not stored
    open func restoreProcedure(identifier: String) -> ArchiveRestoreProcedure? {
        guard let procedure: ArchiveRestoreProcedure = self.restoreProcedures[identifier] else {
            return nil
        }
        return procedure
    }
    
    /// Unarchive data.
    /// - parameter data: data to unarchive
    /// - returns: unarchived object
    open func unarchive(data: Data) -> Archivable? {
        
        // length_of_identifier / others
        let splitData1: Data.SplitData = data.split(length: MemoryLayout<UInt8>.size)
        var count: UInt8 = 0
        (splitData1.former as NSData).getBytes(&count, length: MemoryLayout<UInt8>.size)
        
        // identifier / others
        let splitData2: Data.SplitData = splitData1.latter.split(length: Int(count))
        let identifier = String(data: splitData2.former, encoding: .utf8) ?? ""
                
        guard let procedure = self.unarchiveProcedure(identifier: identifier) else {
            return nil
        }
        
        let unarchived: Archivable = procedure(splitData2.latter)
        
        if let dictionary = unarchived as? ArchivableDictionary, let restoreProcedure = self.restoreProcedure(identifier: identifier) {
            return restoreProcedure(dictionary)
        } else {
            return unarchived
        }
    }
    
    /// Unarchive data.
    /// - parameter data: data to unarchive
    /// - returns: unarchived object
    open class func unarchive(data: Data) -> Archivable? {
        return self.defaultArchiver.unarchive(data: data)
    }
    
    /// Register procedures for unarchiving and restoring struct.
    /// - parameter withCustomStructActivations: closure to register procedures for custom struct
    open class func activateStandardArchivables(withCustomStructActivations:(() -> Void)?) {
        
        Int.activateArchive()
        UInt.activateArchive()
        Float.activateArchive()
        Double.activateArchive()
        String.activateArchive()
        Archivables.activateArchive()
        ArchivableDictionary.activateArchive()
        
        if let customStructActivations = withCustomStructActivations {
            customStructActivations()
        }
    }
}
