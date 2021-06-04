//
//  TLV.swift
//  SwiftTLV
//
//  Created by David Shalaby on 2021-06-03.
//

import Foundation

public struct TLV {
    var typeVal: Int
    var value : [UInt8]
    
    public init(){
        typeVal = 0
        value = []
    }
    
    public init(typeVal: Int, value: [UInt8]) throws{
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
    
    var currentIndex = 0
    var tlvs : [TLV] = []
    var tag : Int
    var length : Int
    var value : [UInt8] = []
    var isTwoByteTag : Bool
    var isTwoByteLength : Bool
    
    while(currentIndex + 2 <= tlvByteArray.count){
        isTwoByteTag = false
        isTwoByteLength = false
        value = []
        if(tlvByteArray[currentIndex] == 0xFF){ //two byte tag
            if(currentIndex+2 < tlvByteArray.count){
                isTwoByteTag = true
                tag = bytesToInt(bytes: [tlvByteArray[currentIndex+1],tlvByteArray[currentIndex+2]])
            }else{
                throw TLVError.ArrayTooShort
            }
        }else{ //one byte tag
            tag = Int(tlvByteArray[currentIndex])
        }
        
        if (isTwoByteTag){
            if(currentIndex + 3 < tlvByteArray.count){
                if(tlvByteArray[currentIndex+3] == 0xFF){ //two byte length with two byte tag
                    isTwoByteLength = true
                    if(currentIndex + 5 < tlvByteArray.count){
                        length = bytesToInt(bytes: [tlvByteArray[currentIndex+4],tlvByteArray[currentIndex+5]])
                    }else{
                        throw TLVError.ArrayTooShort
                    }
                }else{ //one byte length with two byte tag
                    if(currentIndex + 3 < tlvByteArray.count){
                        length = bytesToInt(bytes: [tlvByteArray[currentIndex+3]])
                    }else{
                        throw TLVError.ArrayTooShort
                    }
                }
            }else{
                throw TLVError.ArrayTooShort
            }
       
        }else{
            if(tlvByteArray[currentIndex+1] == 0xFF){ //two byte length with one byte tag
                isTwoByteLength = true
                if(currentIndex + 3 < tlvByteArray.count){
                    length = bytesToInt(bytes: [tlvByteArray[currentIndex+2],tlvByteArray[currentIndex+3]])
                }else{
                    throw TLVError.ArrayTooShort
                }
            }else{ //one byte length with one byte tag
                length = bytesToInt(bytes: [tlvByteArray[currentIndex+1]])
            }
        }
            
        if(tlvByteArray.count < currentIndex + length + 2){
            throw TLVError.ArrayTooShort
        }
                     
        var valueStart : Int
        
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
        
        if(valueStart + length < tlvByteArray.count){
            value.append(contentsOf: tlvByteArray[valueStart...valueStart+length])
        }else{
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
    
    return tlvs
}


public enum TLVError: Error{
    case InvalidTypeValue
    case InvalidValueLength
    case ArrayTooShort
    case UnknownOrOther
}
       
func byteArray<T>(from value: T) -> [UInt8] where T: FixedWidthInteger {
    withUnsafeBytes(of: value.bigEndian, Array.init)
}

func bytesToInt(bytes: [UInt8]) -> Int{
    let data = Data(_: bytes)
    return Int(bigEndian: data.withUnsafeBytes(_:{$0.pointee}))
}
                
                
                
                

