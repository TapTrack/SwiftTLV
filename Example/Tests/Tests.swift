// https://github.com/Quick/Quick

import Quick
import Nimble
import SwiftTLV
import Foundation

class SwiftTLVSpec : QuickSpec {
    override func spec() {
        describe("A composed TLV") {
            context("with a length greater than 65279") {
                it("should thow an error"){
                    let length : Int = 65279 + 1
                    let value : [UInt8] = [UInt8](repeating: 0, count: length)
                    let tag : UInt32 = 1
                    expect { try TLV(typeVal: tag, value: value)}.to(throwError(TLVError.InvalidValueLength))
                }
            }
            
            context("with a tag greater than 65279") {
                it("should throw an error"){
                    let tag : UInt32 = 65279 + 1
                    let value : [UInt8] = [UInt8](repeating: 0, count: 65279)
                    expect { try TLV(typeVal: tag, value: value)}.to(throwError(TLVError.InvalidTypeValue))
                }
            }
        }
        
        describe("When converting a TLV to a byte array") {
            context("with a single byte length and single byte tag") {
                it("should correctly compose the byte array"){
                    let length : Int = 5
                    let value : [UInt8] = [UInt8](repeating: 0, count: length)
                    let tag : UInt32 = 1
                    let expectedByteArray : [UInt8] = [0x01,0x05,0x00,0x00,0x00,0x00,0x00]
                    expect(try! TLV(typeVal: tag, value: value).toByteArray).to(equal(expectedByteArray))
     
                }
            }
            
            context("with a single byte length and single byte tag") {
                it("should correctly compose the byte array"){
                    let length : Int = 32
                    let value : [UInt8] = [UInt8](repeating: 0, count: length)
                    let tag : UInt32 = 1
                    var expectedByteArray : [UInt8] = [UInt8](repeating: 0, count: length+2)
                    expectedByteArray[0] = 0x01
                    expectedByteArray[1] = 0x20
                    expect(try! TLV(typeVal: tag, value: value).toByteArray).to(equal(expectedByteArray))
                }
            }
            
            context("with a two byte length and single byte tag") {
                it("should correctly compose the byte array"){
                    let length : Int = 1000
                    let value : [UInt8] = [UInt8](repeating: 0, count: length)
                    let tag : UInt32 = 1
                    var expectedByteArray : [UInt8] = [UInt8](repeating: 0, count: length+4)
                    expectedByteArray[0] = 0x01
                    expectedByteArray[1] = 0xFF
                    expectedByteArray[2] = 0x03
                    expectedByteArray[3] = 0xE8
                    expect(try! TLV(typeVal: tag, value: value).toByteArray).to(equal(expectedByteArray))     
                }
            }
            
            context("with a single byte length and two byte tag") {
                it("should correctly compose the byte array"){
                    let length : Int = 32
                    let value : [UInt8] = [UInt8](repeating: 0, count: length)
                    let tag : UInt32 = 1000
                    var expectedByteArray : [UInt8] = [UInt8](repeating: 0, count: length+4)
                    expectedByteArray[0] = 0xFF
                    expectedByteArray[1] = 0x03
                    expectedByteArray[2] = 0xE8
                    expectedByteArray[3] = 0x20
                    expect(try! TLV(typeVal: tag, value: value).toByteArray).to(equal(expectedByteArray))
                }
            }
            
            context("with a two byte length and two byte tag") {
                it("should correctly compose the byte array"){
                    let length : Int = 1000
                    let value : [UInt8] = [UInt8](repeating: 0, count: length)
                    let tag : UInt32 = 1000
                    var expectedByteArray : [UInt8] = [UInt8](repeating: 0, count: length+6)
                    expectedByteArray[0] = 0xFF
                    expectedByteArray[1] = 0x03
                    expectedByteArray[2] = 0xE8
                    expectedByteArray[3] = 0xFF
                    expectedByteArray[4] = 0x03
                    expectedByteArray[5] = 0xE8
                    expect(try! TLV(typeVal: tag, value: value).toByteArray).to(equal(expectedByteArray))
                }
            }
        }
        
        describe("When converting list of TLVs to a byte array") {
            context("with two TLVs in a list") {
                it("the composed byte array should be correct"){
                    let length : Int = 5
                    let value : [UInt8] = [UInt8](repeating: 0, count: length)
                    let firstTag : UInt32 = 1
                    let secondTag : UInt32 = 2
                    let expectedByteArray : [UInt8] = [0x01,0x05,0x00,0x00,0x00,0x00,0x00,0x02,0x05,0x00,0x00,0x00,0x00,0x00]
                    var listOfTlvs : [TLV] = []
                    listOfTlvs.append(try! TLV(typeVal: firstTag, value: value))
                    listOfTlvs.append(try! TLV(typeVal: secondTag, value: value))
                    expect(try! writeTLVsToByteArray(tlvs: listOfTlvs)).to(equal(expectedByteArray))
                }
            }
        }
        
        describe("When parsing a raw TLV list as a byte array into list of TLVs") {
            
            context("with a byte array of only one byte") {
                it("should throw an error"){
                    let rawTlvs : [UInt8] = [UInt8](repeating: 0, count: 1)
                    expect { try parseTlvByteArray(tlvByteArray: rawTlvs)}.to(throwError(TLVError.ArrayTooShort))
                }
            }
            
            context("with two TLVs, both single tag, single byte length of zero") {
                it("the parsed array should be correct"){
                    let rawTlvs : [UInt8] = [0x01,0x00,0x02,0x00]
                    let length : Int = 0
                    let value : [UInt8] = [UInt8](repeating: 0, count: length)
                    let firstTag : UInt32 = 1
                    let secondTag : UInt32 = 2
                    
                    var listOfTlvs : [TLV] = []
                    listOfTlvs.append(try! TLV(typeVal: firstTag, value: value))
                    listOfTlvs.append(try! TLV(typeVal: secondTag, value: value))
                    expect(try! parseTlvByteArray(tlvByteArray: rawTlvs)).to(equal(listOfTlvs))
                }
            }
            
            context("with three TLVs, first two single tag, single byte length of zero, third with non-zero length") {
                it("the parsed array should be correct"){
                    let rawTlvs : [UInt8] = [0x01,0x00,0x02,0x00,0x03,0x05,0x00,0x00,0x00,0x00,0x00]
                    let zeroLength : Int = 0
                    let nonZeroLength : Int = 5
                    let value : [UInt8] = [UInt8](repeating: 0, count: nonZeroLength)
                    let zeroLengthValue : [UInt8] = [UInt8](repeating: 0, count: zeroLength)
                    let tag1 : UInt32 = 1
                    let tag2 : UInt32 = 2
                    let tag3 : UInt32 = 3
                    
                    var listOfTlvs : [TLV] = []
                    listOfTlvs.append(try! TLV(typeVal: tag1, value: zeroLengthValue))
                    listOfTlvs.append(try! TLV(typeVal: tag2, value: zeroLengthValue))
                    listOfTlvs.append(try! TLV(typeVal: tag3, value: value))
                    expect(try! parseTlvByteArray(tlvByteArray: rawTlvs)).to(equal(listOfTlvs))
                }
            }
            
            context("with two TLVs, both single tag, single byte length") {
                it("the parsed array should be correct"){
                    let rawTlvs : [UInt8] = [0x01,0x05,0x00,0x00,0x00,0x00,0x00,0x02,0x05,0x00,0x00,0x00,0x00,0x00]
                    let length : Int = 5
                    let value : [UInt8] = [UInt8](repeating: 0, count: length)
                    let firstTag : UInt32 = 1
                    let secondTag : UInt32 = 2
                    
                    var listOfTlvs : [TLV] = []
                    listOfTlvs.append(try! TLV(typeVal: firstTag, value: value))
                    listOfTlvs.append(try! TLV(typeVal: secondTag, value: value))
                    expect(try! parseTlvByteArray(tlvByteArray: rawTlvs)).to(equal(listOfTlvs))
                }
            }
            
            context("with two TLVs, first with single byte tag & dual byte length, second with single byte tag & single byte length") {
                it("the parsed array should be correct"){
                    let length1 : Int = 1000
                    let length2 : Int = 5
                    let value1 : [UInt8] = [UInt8](repeating: 0, count: length1)
                    let value2 : [UInt8] = [UInt8](repeating: 0, count: length2)
                    let tag1 : UInt32 = 1
                    let tag2 : UInt32 = 2
                    var rawTlvs : [UInt8] = [UInt8](repeating: 0, count: length1 + length2 + 6)
                    rawTlvs[0] = UInt8(tag1)
                    rawTlvs[1] = 0xFF
                    rawTlvs[2] = 0x03
                    rawTlvs[3] = 0xE8
                    rawTlvs[4+length1] = UInt8(tag2)
                    rawTlvs[5+length1] = UInt8(length2)
                    
                    var listOfTlvs : [TLV] = []
                    listOfTlvs.append(try! TLV(typeVal: tag1, value: value1))
                    listOfTlvs.append(try! TLV(typeVal: tag2, value: value2))
                    expect(try! parseTlvByteArray(tlvByteArray: rawTlvs)).to(equal(listOfTlvs))
                }
            }
            
            context("with two TLVs, first with single byte tag & single byte length, second with single byte tag & dual byte length") {
                it("the parsed array should be correct"){
                    let length1 : Int = 1000
                    let length2 : Int = 5
                    let value1 : [UInt8] = [UInt8](repeating: 0, count: length1)
                    let value2 : [UInt8] = [UInt8](repeating: 0, count: length2)
                    let tag1 : UInt32 = 1
                    let tag2 : UInt32 = 2
                    var rawTlvs : [UInt8] = [UInt8](repeating: 0, count: length1 + length2 + 6)
                    rawTlvs[0] = UInt8(tag2)
                    rawTlvs[1] = UInt8(length2)
                    rawTlvs[2+length2] = UInt8(tag1)
                    rawTlvs[3+length2] = 0xFF
                    rawTlvs[4+length2] = 0x03
                    rawTlvs[5+length2] = 0xE8
                                     
                    var listOfTlvs : [TLV] = []
                    listOfTlvs.append(try! TLV(typeVal: tag2, value: value2))
                    listOfTlvs.append(try! TLV(typeVal: tag1, value: value1))
                    expect(try! parseTlvByteArray(tlvByteArray: rawTlvs)).to(equal(listOfTlvs))
                }
            }
            
            context("with two TLVs, first with dual byte tag & single byte length, second with dual byte tag & dual byte length") {
                it("the parsed array should be correct"){
                    let length1 : Int = 5
                    let length2 : Int = 1000
                    let value1 : [UInt8] = [UInt8](repeating: 0, count: length1)
                    let value2 : [UInt8] = [UInt8](repeating: 0, count: length2)
                    let tag1 : UInt32 = 1000
                    let tag2 : UInt32 = 2000
                    var rawTlvs : [UInt8] = [UInt8](repeating: 0, count: length1 + length2 + 10)
                    rawTlvs[0] = 0xFF
                    rawTlvs[1] = 0x03
                    rawTlvs[2] = 0xE8
                    rawTlvs[3] = 0x05
                    rawTlvs[4+length1] = 0xFF
                    rawTlvs[5+length1] = 0x07
                    rawTlvs[6+length1] = 0xD0
                    rawTlvs[7+length1] = 0xFF
                    rawTlvs[8+length1] = 0x03
                    rawTlvs[9+length1] = 0xE8
                                    
                    var listOfTlvs : [TLV] = []
                    listOfTlvs.append(try! TLV(typeVal: tag1, value: value1))
                    listOfTlvs.append(try! TLV(typeVal: tag2, value: value2))
                    expect(try! parseTlvByteArray(tlvByteArray: rawTlvs)).to(equal(listOfTlvs))
                }
            }
            
            context("with two TLVs, first with dual byte tag & dual byte length, second with dual byte tag & single byte length") {
                it("the parsed array should be correct"){
                    let length1 : Int = 5
                    let length2 : Int = 1000
                    let value1 : [UInt8] = [UInt8](repeating: 0, count: length1)
                    let value2 : [UInt8] = [UInt8](repeating: 0, count: length2)
                    let tag1 : UInt32 = 1000
                    let tag2 : UInt32 = 2000
                    var rawTlvs : [UInt8] = [UInt8](repeating: 0, count: length1 + length2 + 10)
                    rawTlvs[0] = 0xFF
                    rawTlvs[1] = 0x07
                    rawTlvs[2] = 0xD0
                    rawTlvs[3] = 0xFF
                    rawTlvs[4] = 0x03
                    rawTlvs[5] = 0xE8
                    rawTlvs[6+length2] = 0xFF
                    rawTlvs[7+length2] = 0x03
                    rawTlvs[8+length2] = 0xE8
                    rawTlvs[9+length2] = 0x05
                                    
                    var listOfTlvs : [TLV] = []
                    listOfTlvs.append(try! TLV(typeVal: tag2, value: value2))
                    listOfTlvs.append(try! TLV(typeVal: tag1, value: value1))
                    expect(try! parseTlvByteArray(tlvByteArray: rawTlvs)).to(equal(listOfTlvs))
                }
            }
            
            context("with two TLVs, both dual tag, dual byte length") {
                it("the parsed array should be correct"){
                    let length1 : Int = 1002
                    let length2 : Int = 2002
                    let value1 : [UInt8] = [UInt8](repeating: 0, count: length1)
                    let value2 : [UInt8] = [UInt8](repeating: 0, count: length2)
                    let tag1 : UInt32 = 1000
                    let tag2 : UInt32 = 2000
                    var rawTlvs : [UInt8] = [UInt8](repeating: 0, count: length1 + length2 + 12)
                    rawTlvs[0] = 0xFF
                    rawTlvs[1] = 0x03
                    rawTlvs[2] = 0xE8
                    rawTlvs[3] = 0xFF
                    rawTlvs[4] = 0x03
                    rawTlvs[5] = 0xEA
                    rawTlvs[6+length1] = 0xFF
                    rawTlvs[7+length1] = 0x07
                    rawTlvs[8+length1] = 0xD0
                    rawTlvs[9+length1] = 0xFF
                    rawTlvs[10+length1] = 0x07
                    rawTlvs[11+length1] = 0xD2
                                    
                    var listOfTlvs : [TLV] = []
                    listOfTlvs.append(try! TLV(typeVal: tag1, value: value1))
                    listOfTlvs.append(try! TLV(typeVal: tag2, value: value2))
                    expect(try! parseTlvByteArray(tlvByteArray: rawTlvs)).to(equal(listOfTlvs))
                }
            }
            
            context("with 100 TLVs, all dual tag, dual byte length") {
                it("the parsed array should be correct"){
                    let length1 : Int = 1002
                    let length2 : Int = 2002
                    let value1 : [UInt8] = [UInt8](repeating: 0, count: length1)
                    let value2 : [UInt8] = [UInt8](repeating: 0, count: length2)
                    let tag1 : UInt32 = 1000
                    let tag2 : UInt32 = 2000
                    var rawTlvsBlock : [UInt8] = [UInt8](repeating: 0, count: length1 + length2 + 12)
                    rawTlvsBlock[0] = 0xFF
                    rawTlvsBlock[1] = 0x03
                    rawTlvsBlock[2] = 0xE8
                    rawTlvsBlock[3] = 0xFF
                    rawTlvsBlock[4] = 0x03
                    rawTlvsBlock[5] = 0xEA
                    rawTlvsBlock[6+length1] = 0xFF
                    rawTlvsBlock[7+length1] = 0x07
                    rawTlvsBlock[8+length1] = 0xD0
                    rawTlvsBlock[9+length1] = 0xFF
                    rawTlvsBlock[10+length1] = 0x07
                    rawTlvsBlock[11+length1] = 0xD2
                    
                    var rawTlvs : [UInt8] = []
                    var listOfTlvs : [TLV] = []
                    var numBlocksAppended = 0
                    
                    while(numBlocksAppended < 100){
                        rawTlvs.append(contentsOf: rawTlvsBlock)
                        listOfTlvs.append(try! TLV(typeVal: tag1, value: value1))
                        listOfTlvs.append(try! TLV(typeVal: tag2, value: value2))
                        numBlocksAppended+=1
                    }
                   
                    expect(try! parseTlvByteArray(tlvByteArray: rawTlvs)).to(equal(listOfTlvs))
                }
            }
            
            context("with 100 TLVs, all single tag, single byte length") {
                it("the parsed array should be correct"){
                    let length1 : Int = 5
                    let length2 : Int = 10
                    let value1 : [UInt8] = [UInt8](repeating: 0, count: length1)
                    let value2 : [UInt8] = [UInt8](repeating: 0, count: length2)
                    let tag1 : UInt32 = 1
                    let tag2 : UInt32 = 2
                    var rawTlvsBlock : [UInt8] = [UInt8](repeating: 0, count: length1 + length2 + 4)
                    rawTlvsBlock[0] = UInt8(tag1)
                    rawTlvsBlock[1] = UInt8(length1)
                    rawTlvsBlock[2+length1] = UInt8(tag2)
                    rawTlvsBlock[3+length1] = UInt8(length2)
                        
                    var rawTlvs : [UInt8] = []
                    var listOfTlvs : [TLV] = []
                    var numBlocksAppended = 0
                    
                    while(numBlocksAppended < 100){
                        rawTlvs.append(contentsOf: rawTlvsBlock)
                        listOfTlvs.append(try! TLV(typeVal: tag1, value: value1))
                        listOfTlvs.append(try! TLV(typeVal: tag2, value: value2))
                        numBlocksAppended+=1
                    }
                   
                    expect(try! parseTlvByteArray(tlvByteArray: rawTlvs)).to(equal(listOfTlvs))
                }
            }
            
            context("with 100 TLVs, alternating between dual byte tag/length and single byte tag/lengh") {
                it("the parsed array should be correct"){
                    let length1 : Int = 1002
                    let length2 : Int = 5
                    let value1 : [UInt8] = [UInt8](repeating: 0, count: length1)
                    let value2 : [UInt8] = [UInt8](repeating: 0, count: length2)
                    let tag1 : UInt32 = 1000
                    let tag2 : UInt32 = 1
                    var rawTlvsBlock : [UInt8] = [UInt8](repeating: 0, count: length1 + length2 + 8)
                    rawTlvsBlock[0] = 0xFF
                    rawTlvsBlock[1] = 0x03
                    rawTlvsBlock[2] = 0xE8
                    rawTlvsBlock[3] = 0xFF
                    rawTlvsBlock[4] = 0x03
                    rawTlvsBlock[5] = 0xEA
                    rawTlvsBlock[6+length1] = UInt8(tag2)
                    rawTlvsBlock[7+length1] = UInt8(length2)        
                    
                    var rawTlvs : [UInt8] = []
                    var listOfTlvs : [TLV] = []
                    var numBlocksAppended = 0
                    
                    while(numBlocksAppended < 100){
                        rawTlvs.append(contentsOf: rawTlvsBlock)
                        listOfTlvs.append(try! TLV(typeVal: tag1, value: value1))
                        listOfTlvs.append(try! TLV(typeVal: tag2, value: value2))
                        numBlocksAppended+=1
                    }
                   
                    expect(try! parseTlvByteArray(tlvByteArray: rawTlvs)).to(equal(listOfTlvs))
                }
            }

        }
        
        describe("When fetching a TLV from a list") {
            context("with fetchTlv and the TLV is present in the list") {
                it("should return the fetched TLV"){
                    let length : Int = 1
                    let value : [UInt8] = [UInt8](repeating: 0, count: length)
                    let tag : UInt32 = 1
                    let tlv = try! TLV(typeVal: tag, value: value)
                    var tlvList : [TLV] = []
                    tlvList.append(tlv)
                    expect {try fetchTlv(tagToFetch: tag, from: tlvList)}.to(equal(tlv))
                }
            }
            
            context("with fetchTlv and the TLV is not present in the list") {
                it("should throw an error"){
                    let length : Int = 1
                    let value : [UInt8] = [UInt8](repeating: 0, count: length)
                    let tag : UInt32 = 1
                    let tlv = try! TLV(typeVal: tag, value: value)
                    var tlvList : [TLV] = []
                    tlvList.append(tlv)
                    expect {try fetchTlv(tagToFetch: tag+1, from: tlvList)}.to(throwError(TLVError.TlvNotFound))
                }
            }
            
            context("with fetchTlvIfPresent and the TLV is present in the list") {
                it("should return the fetched TLV"){
                    let length : Int = 1
                    let value : [UInt8] = [UInt8](repeating: 0, count: length)
                    let tag : UInt32 = 1
                    let tlv = try! TLV(typeVal: tag, value: value)
                    var tlvList : [TLV] = []
                    tlvList.append(tlv)
                    expect (fetchTlvIfPresent(tagToFetch: tag, from: tlvList)).to(equal(tlv))
                }
            }
            
            context("with fetchTlvIfPresent and the TLV is not present in the list") {
                it("should throw return nill"){
                    let length : Int = 1
                    let value : [UInt8] = [UInt8](repeating: 0, count: length)
                    let tag : UInt32 = 1
                    let tlv = try! TLV(typeVal: tag, value: value)
                    var tlvList : [TLV] = []
                    tlvList.append(tlv)
                    expect (fetchTlvIfPresent(tagToFetch: tag+1, from: tlvList)).to(beNil())
                }
            }

        }
        
        describe("When fetching a TLV from a long list") {
            context("with fetchTlv and the TLV is present in the list") {
                it("should return the fetched TLV"){
                    let length : Int = 1
                    let value : [UInt8] = [UInt8](repeating: 0, count: length)
                    let tag : UInt32 = 1
                    let tlv = try! TLV(typeVal: tag, value: value)
                    let nonMatchingTlv = try! TLV(typeVal: tag+1, value: value)
                    var tlvList : [TLV] = []
                    tlvList.append(nonMatchingTlv)
                    tlvList.append(nonMatchingTlv)
                    tlvList.append(nonMatchingTlv)
                    tlvList.append(tlv)
                    tlvList.append(nonMatchingTlv)
                    tlvList.append(nonMatchingTlv)
                    expect {try fetchTlv(tagToFetch: tag, from: tlvList)}.to(equal(tlv))
                }
            }
            
            context("with fetchTlv and the TLV is not present in the list") {
                it("should throw an error"){
                    let length : Int = 1
                    let value : [UInt8] = [UInt8](repeating: 0, count: length)
                    let tag : UInt32 = 1
                    let nonMatchingTlv = try! TLV(typeVal: tag+1, value: value)
                    var tlvList : [TLV] = []
                    tlvList.append(nonMatchingTlv)
                    tlvList.append(nonMatchingTlv)
                    tlvList.append(nonMatchingTlv)
                    tlvList.append(nonMatchingTlv)
                    tlvList.append(nonMatchingTlv)
                    expect {try fetchTlv(tagToFetch: tag, from: tlvList)}.to(throwError(TLVError.TlvNotFound))
                }
            }
            
            context("with fetchTlvIfPresent and the TLV is present in the list") {
                it("should return the fetched TLV"){
                    let length : Int = 1
                    let value : [UInt8] = [UInt8](repeating: 0, count: length)
                    let tag : UInt32 = 1
                    let tlv = try! TLV(typeVal: tag, value: value)
                    let nonMatchingTlv = try! TLV(typeVal: tag+1, value: value)
                    var tlvList : [TLV] = []
                    tlvList.append(nonMatchingTlv)
                    tlvList.append(nonMatchingTlv)
                    tlvList.append(nonMatchingTlv)
                    tlvList.append(tlv)
                    tlvList.append(nonMatchingTlv)
                    tlvList.append(nonMatchingTlv)
                    expect { fetchTlvIfPresent(tagToFetch: tag, from: tlvList)}.to(equal(tlv))
                }
            }
            
            context("with fetchTlvIfPresent and the TLV is not present in the list") {
                it("should throw return nill"){
                    let length : Int = 1
                    let value : [UInt8] = [UInt8](repeating: 0, count: length)
                    let tag : UInt32 = 1
                    let nonMatchingTlv = try! TLV(typeVal: tag+1, value: value)
                    var tlvList : [TLV] = []
                    tlvList.append(nonMatchingTlv)
                    tlvList.append(nonMatchingTlv)
                    tlvList.append(nonMatchingTlv)
                    tlvList.append(nonMatchingTlv)
                    tlvList.append(nonMatchingTlv)
                    expect (fetchTlvIfPresent(tagToFetch: tag, from: tlvList)).to(beNil())
                }
            }

        }
        
    }
}
