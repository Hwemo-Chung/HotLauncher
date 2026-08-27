import Testing
@testable import HotLauncher

@Test func donateURLIsPayPalMe199USD() {
    #expect(Donate.url.absoluteString == "https://paypal.me/HWEMOCHUNG/1.99USD")
}
