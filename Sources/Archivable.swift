//
//  Archivable.swift
//  StructArchiver
//
//  Created by naru on 2016/05/24.
//  Copyright © 2016年 naru. All rights reserved.
//

import Foundation

/// Protocol for mutual conversion of struct and NSData
public protocol Archivable {
    
    /// String to identify struct. (Implemented default behavior.)
//    static var archivedIdentifier: String { get }
    
    /// String to identify struct. (Implemented default behavior.)
//    var archivedIdentifier: String { get }
    
    /// Number of bytes of data to identify archived struct. (Implemented default behavior.)
//    var archivedIDLength: Int { get }
    
    /// Number of bytes of the whole archived data.
    var archivedDataLength: Int { get }
    
    /// Metadata for the archived data.
    var archivedHeaderData: [Data] { get }
    
    /// Body data for the archived data.
    var archivedBodyData: [Data] { get }
    
    /// The whole of archived data. (Implemented default behavior.)
//    var archivedData: NSData { get }
    
    /// Closure to unarchive data.
    static var unarchiveProcedure: ArchiveUnarchiveProcedure { get }
}

/// Represent array of archivable object.
public typealias Archivables = [Archivable]

/// Represent type of dictionary containing archivable value.
public typealias ArchivableDictionary = [String: Archivable]


/// Define default implementation for the Archivable.
public extension Archivable {

    /// Return name of type.
    public static var archivedIdentifier: String {
        return "\(self)"
    }

    /// Return name of type.
    public var archivedIdentifier: String {
        return "\(Mirror(reflecting: self).subjectType)"
    }
    
    /// Length of identifier data
    public var archivedIDLength: Int {
        return MemoryLayout<UInt8>.size + self.archivedIdentifier.characters.count
    }
    
    /// Identifier data
    public var archivedIdentifierData: Data {
        // count
        let identifier: String = self.archivedIdentifier
        var count: UInt8 = UInt8(identifier.characters.count)
        // + identifier string
        var identifierData = Data(bytes: &count, count: MemoryLayout<UInt8>.size)
        if let data = identifier.data(using: String.Encoding.utf8) {
            identifierData.append(data)
        }
        return identifierData
    }
    
    /// Whole of archived data
    public var archivedData: Data {
        var data = self.archivedIdentifierData
        for subdata in self.archivedHeaderData + self.archivedBodyData {
            data.append(subdata)
        }
        return data
    }
    
    /// Store procedure to unarchive data on memory.
    public static func activateArchive() {
        StructArchiver.registerUnarchiveProcedure(identifier: self.archivedIdentifier, procedure: self.unarchiveProcedure)
    }
}


extension Int: Archivable {

    public static let ArchivedDataLength: Int = MemoryLayout<UInt8>.size + "Int".characters.count + MemoryLayout<Int>.size
    
    public var archivedDataLength: Int {
        return Int.ArchivedDataLength
    }
    
    public var archivedHeaderData: [Data] {
        return [Data()]
    }
    
    public var archivedBodyData: [Data] {
        return [Data(bytes: convertValueToBytes(value: self), count: MemoryLayout<Int>.size)]
    }
    
    public static var unarchiveProcedure: ArchiveUnarchiveProcedure {
        return { data in
            // unarchive data as Int
            var value: Int = 0
            let data: Data = data.subdata(in: Range(uncheckedBounds: (0, MemoryLayout<Int>.size)))
            (data as NSData).getBytes(&value, length: MemoryLayout<Int>.size)
            return value
        }
    }
}

extension UInt: Archivable {
    
    public var archivedDataLength: Int {
        return self.archivedIDLength + MemoryLayout<UInt>.size
    }
    
    public var archivedHeaderData: [Data] {
        return [Data()]
    }
    
    public var archivedBodyData: [Data] {
        return [Data(bytes: convertValueToBytes(value: self), count: MemoryLayout<UInt>.size)]
    }
    
    public static var unarchiveProcedure: ArchiveUnarchiveProcedure {
        return { data in
            // unarchive data as UInt
            var value: UInt = 0
            let data: Data = data.subdata(in: Range(uncheckedBounds: (0, MemoryLayout<UInt>.size)))
            (data as NSData).getBytes(&value, length: MemoryLayout<UInt>.size)
            return value
        }
    }
}

extension Float: Archivable {
    
    public var archivedDataLength: Int {
        return self.archivedIDLength + MemoryLayout<Float>.size
    }
    
    public var archivedHeaderData: [Data] {
        return [Data()]
    }
    
    public var archivedBodyData: [Data] {
        return [Data(bytes: convertValueToBytes(value: self), count: MemoryLayout<Float>.size)]
    }
    
    public static var unarchiveProcedure: ArchiveUnarchiveProcedure {
        return { data in
            // unarchive data as Float
            var value: Float = 0
            let data: Data = data.subdata(in: Range(uncheckedBounds: (0, MemoryLayout<Float>.size)))
            (data as NSData).getBytes(&value, length: MemoryLayout<Float>.size)
            return value
        }
    }
}

extension Double: Archivable {
    
    public var archivedDataLength: Int {
        return self.archivedIDLength + MemoryLayout<Double>.size
    }
    
    public var archivedHeaderData: [Data] {
        return [Data()]
    }
    
    public var archivedBodyData: [Data] {
        return [Data(bytes: convertValueToBytes(value: self), count: MemoryLayout<Double>.size)]
    }
    
    public static var unarchiveProcedure: ArchiveUnarchiveProcedure {
        return { data in
            // unarchive data as Double
            var value: Double = 0
            let data: Data = data.subdata(in: Range(uncheckedBounds: (0, MemoryLayout<Double>.size)))
            (data as NSData).getBytes(&value, length: MemoryLayout<Double>.size)
            return value
        }
    }
}

extension String: Archivable {
    
    public var archivedDataLength: Int {
        return self.archivedIDLength + Int.ArchivedDataLength + self.lengthOfBytes(using: String.Encoding.utf8)
    }
    
    public var archivedHeaderData: [Data] {
        let length: Int = self.lengthOfBytes(using: String.Encoding.utf8)
        return [length.archivedData]
    }
    
    public var archivedBodyData: [Data] {
        guard let data = self.data(using: String.Encoding.utf8) else {
            return [Data()]
        }
        return [data]
    }
    
    public static var unarchiveProcedure: ArchiveUnarchiveProcedure {
        
        return { data in
            
            // get length of string
            let lengthData: Data = data.subdata(in: Range(uncheckedBounds: (0, Int.ArchivedDataLength)))
            let length: Int = StructArchiver.defaultArchiver.unarchive(data: lengthData) as! Int
            
            // unarchive data as String
            let textRange = Range(uncheckedBounds: (Int.ArchivedDataLength, length))
//            let textRange = NSMakeRange(Int.ArchivedDataLength, length)
            let textData = data.subdata(in: textRange)
            let text = NSString(data: textData, encoding: String.Encoding.utf8.rawValue) as String? ?? ""
            return text
        }
    }
}


public protocol ElementArchivable {
    func archivable() -> Archivable
}

extension Array: Archivable, ElementArchivable {
    
    public func archivable() -> Archivable {
        
        var archivables: Archivables = Archivables()
        self.forEach {
            if let archivable: Archivable = $0 as? Archivable {
                archivables.append(archivable)
            }
        }
        return archivables
    }
    
    public var archivedDataLength: Int {
        let archivables: Archivables = self.archivable() as! Archivables
        let elementsLength: Int = archivables.reduce(0, {
            $0 + $1.archivedDataLength
        })
        return self.archivedIDLength + Int.ArchivedDataLength*(1+archivables.count) + elementsLength
    }
    
    public var archivedHeaderData: [Data] {
        let archivables: Archivables = self.archivable() as! Archivables
        let count: Data = archivables.count.archivedData
        let data: [Data] = archivables.map { element in
            return element.archivedDataLength
        }.map { length in
            return length.archivedData
        }
        return [count] + data
    }
    
    public var archivedBodyData: [Data] {
        let archivables: Archivables = self.archivable() as! Archivables
        let data: [Data] = archivables.map { element in
            return element.archivedData
        }
        return data
    }
    
    public static var unarchiveProcedure: ArchiveUnarchiveProcedure {
        
        return { data in
            
            // get number of elements
            let countData = data.subdata(in: Range(uncheckedBounds: (0, Int.ArchivedDataLength)))
            let count: Int = StructArchiver.unarchive(data: countData) as! Int
            
            let subdata: Data = data.subdata(in: Range(uncheckedBounds: (0, Int.ArchivedDataLength)))
            let splitData: Data.SplitData = subdata.split(length: Int.ArchivedDataLength*count)
            
            // get lengths of each elements
            let lengths: [Int] = splitData.former.splitIntoSubdata(lengths: [Int](repeating: Int.ArchivedDataLength, count: count)).map { element in
                return StructArchiver.unarchive(data: element) as! Int
            }
            
            // unarchive each elements
            let elements: [Archivable] = splitData.latter.splitIntoSubdata(lengths: lengths).flatMap { element in
                return StructArchiver.unarchive(data: element)
            }
            
            return elements
        }
    }
}

extension Dictionary: Archivable, ElementArchivable {
    
    public func archivable() -> Archivable {
        
        var archivableDictionary: ArchivableDictionary = ArchivableDictionary()
        for (label, value) in self {
            if let label = label as? String, let value = value as? Archivable {
                archivableDictionary[label] = value
            }
        }
        return archivableDictionary
    }
    
    public var archivedDataLength: Int {
        
        let archivableDictionary: ArchivableDictionary = self.archivable() as! ArchivableDictionary
        
        let elementsLength: Int = archivableDictionary.keys.reduce(0) { (length, key) in
            length + key.archivedDataLength
        } + archivableDictionary.values.reduce(0) { (length, value) in
            length + value.archivedDataLength
        }
        
        return self.archivedIDLength + Int.ArchivedDataLength*(1+archivableDictionary.keys.count*2) + elementsLength
    }
    
    public var archivedHeaderData: [Data] {
        
        let archivableDictionary: ArchivableDictionary = self.archivable() as! ArchivableDictionary
        
        // number of pair of key, value
        let count: Data = Int(archivableDictionary.keys.count).archivedData
        
        // lengths of each key data
        let keys: [Data] = archivableDictionary.keys.map { key in
            return key.archivedDataLength
        }.map { (length: Int) in
            return length.archivedData
        }
        
        // lengths of each value data
        let values: [Data] = archivableDictionary.values.map { value in
            return value.archivedDataLength
        }.map { (length: Int) in
            return length.archivedData
        }
        
        return [count] + keys + values
    }
    
    public var archivedBodyData: [Data] {
        
        let archivableDictionary: ArchivableDictionary = self.archivable() as! ArchivableDictionary
        
        let keys: [Data] = archivableDictionary.keys.map { key in
            return key.archivedData
        }
        let values: [Data] = archivableDictionary.values.map { value in
            return value.archivedData
        }
        return keys + values
    }
    
    public static var unarchiveProcedure: ArchiveUnarchiveProcedure {
        
        return { data in
            
            // get number of pair of key, value
            let countData = data.subdata(in: Range(uncheckedBounds: (0, Int.ArchivedDataLength)))
            let count: Int = StructArchiver.unarchive(data: countData) as! Int
            
            let subdata: Data = data.subdata(in: Range(uncheckedBounds: (0, data.count - Int.ArchivedDataLength)))
            let splitData: Data.SplitData = subdata.split(length: Int.ArchivedDataLength*count*2)
            
            // get lengths of each data
            let lengths: [Int] = splitData.former.splitIntoSubdata(lengths: [Int](repeating: Int.ArchivedDataLength, count: count*2)).map { element in
                return StructArchiver.unarchive(data: element) as! Int
            }
            
            let bodyParts: [Data] = splitData.latter.splitIntoSubdata(lengths: lengths)
            
            // get keys and values
            let keys: [String] = bodyParts[0..<count].flatMap { data in
                return StructArchiver.unarchive(data: data) as? String
            }
            let values: [Archivable] = bodyParts[count..<count*2].flatMap { data in
                return StructArchiver.unarchive(data: data)
            }
            
            // get result dictionary
            var dictionary: [String: Archivable] =  [String: Archivable]()
            keys.enumerated().forEach { index, key in
                dictionary[key] = values[index]
            }
            
            return dictionary
        }
    }
}

public extension Data {
    
    typealias SplitData = (former: Data, latter: Data)
    
    func split(length: Int) -> SplitData {
        let former: Data = self.subdata(in: Range(uncheckedBounds: (0, length)))
        let latter: Data = self.subdata(in: Range(uncheckedBounds: (length, self.count - length)))
        return (former: former, latter: latter)
    }
    
    func splitIntoSubdata(lengths: [Int]) -> [Data] {
        
        let data: Data = NSData(data: self) as Data
        var result: [Data] = [Data]()
        
        var position: Int = 0
        for length in lengths {
            let range = Range(uncheckedBounds: (position, length))
            result.append(data.subdata(in: range))
            position = position + length
        }
        return result
    }
}

fileprivate func convertValueToBytes<T>(value: T) -> [UInt8] {
    var mutableValue = value
    let bytes = Array<UInt8>(withUnsafeBytes(of: &mutableValue) {
        $0
    })
    return bytes
}
