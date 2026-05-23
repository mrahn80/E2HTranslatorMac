import XCTest
@testable import E2HTranslatorMac

final class TranslationTests: XCTestCase {
    
    func testHangulConversion() {
        XCTAssertEqual(HangulUtils.convertEnglishTypedToKorean("rk"), "가")
        XCTAssertEqual(HangulUtils.convertEnglishTypedToKorean("rkskekfk"), "가나다라")
        XCTAssertEqual(HangulUtils.convertEnglishTypedToKorean("gksrmf"), "한글")
        XCTAssertEqual(HangulUtils.convertEnglishTypedToKorean("dkssudgktpdy"), "안녕하세요")
    }
    
    func testTranslationService() async {
        let service = TranslationService()
        
        let result1 = await service.translateAsync("rkskekfk")
        XCTAssertEqual(result1, "가나다라")
        
        let result2 = await service.translateAsync("`Hello` rkskekfk")
        XCTAssertEqual(result2, "Hello 가나다라")
    }
}
