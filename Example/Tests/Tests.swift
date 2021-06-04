// https://github.com/Quick/Quick

import Quick
import Nimble
import SwiftTLV
import Foundation

class SwiftTLVSpec : QuickSpec {
    override func spec() {
        describe("A composed TLV") {
            context("with a length greater than 65279") {
                it("should be rejected"){
                    let length : Int = 65279 + 1
                    let value : [UInt8] = [UInt8](repeating: 0, count: length)
                    let tag = 1
                    do{
                        expect(try TLV(typeVal: tag, value: value)).to(raiseException())
//                        expect { try TLV(typeVal: tag, value: value)}.to(matchError(TL))
                    }catch{
                        
                    }
                    
                }
            }
        }
        
        
    }
}


class TableOfContentsSpec: QuickSpec {
    override func spec() {
        describe("these will fail") {
            
            it("can do maths") {
                expect(1) == 2
            }
            
            it("can read") {
                expect("number") == "string"
            }
            
            it("will eventually fail") {
                expect("time").toEventually( equal("done") )
            }
            
            context("these will pass") {
                
                it("can do maths") {
                    expect(23) == 23
                }
                
                it("can read") {
                    expect("🐮") == "🐮"
                }
                
                it("will eventually pass") {
                    var time = "passing"
                    
                    DispatchQueue.main.async {
                        time = "done"
                    }
                    
                    waitUntil { done in
                        Thread.sleep(forTimeInterval: 0.5)
                        expect(time) == "done"
                        
                        done()
                    }
                }
            }
        }
    }
}
