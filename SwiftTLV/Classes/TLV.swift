//
//  TLV.swift
//  SwiftTLV
//
//  Created by David Shalaby on 2021-06-03.
//

import Foundation

public struct TLV : Equatable{
    var typeVal: UInt32
    var value : [UInt8]
    
    public init(){
        typeVal = 0
        value = []
    }
    
    public init(typeVal: UInt32, value: [UInt8]) throws{
        if(typeVal > 65279){
            throw TLVError.InvalidTypeValue
        }
        if (value.count > 65279){
            throw TLVError.InvalidValueLength
        }
        self.typeVal = typeVal
        self.value = value
    }
    
    public func toByteArray() throws -> [UInt8] {
        if(typeVal > 65279){
            throw TLVError.InvalidTypeValue
        }
        if (value.count > 65279){
            throw TLVError.InvalidValueLength
        }
        var tlvAsByteArray : [UInt8] = []
        if(typeVal > 254){
            tlvAsByteArray.append(0xFF)
            tlvAsByteArray.append(contentsOf: byteArray(from: Int16(typeVal)))
        }else{
            tlvAsByteArray.append(contentsOf: byteArray(from: Int8(typeVal)))
        }
        
        if(value.count > 254){
            tlvAsByteArray.append(0xFF)
            tlvAsByteArray.append(contentsOf: byteArray(from: Int16(value.count)))
        }else{
            tlvAsByteArray.append(contentsOf: byteArray(from: Int8(value.count)))
        }
        
        tlvAsByteArray.append(contentsOf: value)
        
        return tlvAsByteArray
    }
}

public func writeTLVsToByteArray(tlvs: [TLV]) throws -> [UInt8]{
    var tlvsAsByteArray : [UInt8] = []
    
    for tlv in tlvs {
        do{
            try tlvsAsByteArray.append(contentsOf: tlv.toByteArray())
        }catch TLVError.InvalidTypeValue{
            throw TLVError.InvalidValueLength
        }catch TLVError.InvalidValueLength{
            throw TLVError.InvalidValueLength
        }catch{
            throw TLVError.UnknownOrOther
        }
    }
    
    return tlvsAsByteArray
}

public func parseTlvByteArray(tlvByteArray: [UInt8]) throws -> [TLV]{
    if (tlvByteArray.count < 2){
        throw TLVError.ArrayTooShort
    }
    
    var currentIndex : UInt32 = 0
    var tlvs : [TLV] = []
    var tag : UInt32
    var length : UInt32
    var value : [UInt8] = []
    var isTwoByteTag : Bool
    var isTwoByteLength : Bool
    
    do{
        while(currentIndex + 2 <= tlvByteArray.count){
            isTwoByteTag = false
            isTwoByteLength = false
            value = []
            if(tlvByteArray[Int(currentIndex)] == 0xFF){ //two byte tag
                if(currentIndex+2 < tlvByteArray.count){
                    isTwoByteTag = true
                    tag = try bytesToUInt(bytes: [tlvByteArray[Int(currentIndex+1)],tlvByteArray[Int(currentIndex+2)]])
                }else{
                    throw TLVError.ArrayTooShort
                }
            }else{ //one byte tag
                tag = UInt32(tlvByteArray[Int(currentIndex)])
            }
            
            if (isTwoByteTag){
                if(currentIndex + 3 < tlvByteArray.count){
                    if(tlvByteArray[Int(currentIndex+3)] == 0xFF){ //two byte length with two byte tag
                        isTwoByteLength = true
                        if(currentIndex + 5 < tlvByteArray.count){
                            length = try bytesToUInt(bytes: [tlvByteArray[Int(currentIndex+4)],tlvByteArray[Int(currentIndex+5)]])
                        }else{
                            throw TLVError.ArrayTooShort
                        }
                    }else{ //one byte length with two byte tag
                        if(currentIndex + 3 < tlvByteArray.count){
                            length = try bytesToUInt(bytes: [tlvByteArray[Int(currentIndex+3)]])
                        }else{
                            throw TLVError.ArrayTooShort
                        }
                    }
                }else{
                    throw TLVError.ArrayTooShort
                }
           
            }else{
                if(tlvByteArray[Int(currentIndex+1)] == 0xFF){ //two byte length with one byte tag
                    isTwoByteLength = true
                    if(currentIndex + 3 < tlvByteArray.count){
                        length = try bytesToUInt(bytes: [tlvByteArray[Int(currentIndex+2)],tlvByteArray[Int(currentIndex+3)]])
                    }else{
                        throw TLVError.ArrayTooShort
                    }
                }else{ //one byte length with one byte tag
                    length = try bytesToUInt(bytes: [tlvByteArray[Int(currentIndex+1)]])
                }
            }
                
            if(tlvByteArray.count < currentIndex + length + 2){
                throw TLVError.ArrayTooShort
            }
                         
            var valueStart : UInt32
            
            if (isTwoByteTag && isTwoByteLength){
                valueStart = currentIndex + 6
            }else if (isTwoByteTag && !isTwoByteLength){
                valueStart = currentIndex + 4
            }else if (!isTwoByteTag && isTwoByteLength){
                valueStart = currentIndex + 4
            }else if(!isTwoByteTag && !isTwoByteLength){
                valueStart = currentIndex + 2
            }else{
                throw TLVError.UnknownOrOther
            }
            
            if(valueStart + length - 1 < tlvByteArray.count && length != 0){
                value.append(contentsOf: tlvByteArray[Int(valueStart)...Int(valueStart+length-1)])
            }else if (length != 0){
                throw TLVError.ArrayTooShort
            }
                        
            do{
                try tlvs.append(TLV(typeVal: tag, value: value))
            }catch TLVError.InvalidTypeValue{
                throw TLVError.InvalidValueLength
            }catch TLVError.InvalidValueLength{
                throw TLVError.InvalidValueLength
            }catch{
                throw TLVError.UnknownOrOther
            }
            
            currentIndex = currentIndex + (isTwoByteTag ? 3 : 1) + (isTwoByteLength ? 3 : 1) + length
        }
    }catch TLVError.ArrayTooShort{
        throw TLVError.ArrayTooShort
    }catch TLVError.InvalidTypeValue{
        throw TLVError.InvalidTypeValue
    }catch TLVError.InvalidValueLength{
        throw TLVError.InvalidValueLength
    }catch TLVError.UnsupportedIntegerSize{
        throw TLVError.UnsupportedIntegerSize
    }catch{
        throw TLVError.UnknownOrOther
    }
    
    return tlvs
}


public enum TLVError: Error{
    case InvalidTypeValue
    case InvalidValueLength
    case ArrayTooShort
    case UnsupportedIntegerSize
    case UnknownOrOther
}
       
func byteArray<T>(from value: T) -> [UInt8] where T: FixedWidthInteger {
    withUnsafeBytes(of: value.bigEndian, Array.init)
}

func bytesToUInt(bytes: [UInt8]) throws -> UInt32{
    
    let data = Data(bytes: bytes/*, count: bytes.count*/)
    var value8 : UInt8
    var value16 : UInt16
    var value32 : UInt32
    if (bytes.count == 1){
        value8 = UInt8(bigEndian: data.withUnsafeBytes({$0.pointee}))
        return UInt32(value8)
    }else if (bytes.count == 2){
        value16 = UInt16(bigEndian: data.withUnsafeBytes({$0.pointee}))
        return UInt32(value16)
    }else if (bytes.count == 4){
        value32 = UInt32(bigEndian: data.withUnsafeBytes({$0.pointee}))
        return value32
    }else{
        throw TLVError.UnsupportedIntegerSize
    }
}
                
                
                
                

