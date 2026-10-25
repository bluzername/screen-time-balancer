import XCTest
@testable import ScreenTimeCore

final class EmailValidatorTests: XCTestCase {
    func testAcceptsWellFormedAddresses() {
        XCTAssertTrue(EmailValidator.isValid("parent@example.com"))
        XCTAssertTrue(EmailValidator.isValid("first.last+tag@sub.example.co.uk"))
    }

    func testRejectsMalformedAddresses() {
        XCTAssertFalse(EmailValidator.isValid(""))
        XCTAssertFalse(EmailValidator.isValid("no-at-sign"))
        XCTAssertFalse(EmailValidator.isValid("user@"))
        XCTAssertFalse(EmailValidator.isValid("user@host"))
    }

    func testValidationMessages() {
        XCTAssertEqual(EmailValidator.validationError(for: ""), "Email is required")
        XCTAssertEqual(EmailValidator.validationError(for: "bad"), "Please enter a valid email address")
        XCTAssertNil(EmailValidator.validationError(for: "ok@example.com"))
    }
}

final class PasswordValidatorTests: XCTestCase {
    func testEmptyPasswordIsRequired() {
        let result = PasswordValidator.validate("")
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "Password is required")
    }

    func testShortPasswordFails() {
        XCTAssertFalse(PasswordValidator.validate("Ab1!").isValid)
    }

    func testLowercaseOnlyNeedsSecondClass() {
        let result = PasswordValidator.validate("alllowercase")
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errors.contains { $0.contains("uppercase letter, number, or special") })
    }

    func testStrengthTiers() {
        XCTAssertEqual(PasswordValidator.strength("short"), .weak)
        XCTAssertEqual(PasswordValidator.strength("abcdefgh"), .weak)
        XCTAssertEqual(PasswordValidator.strength("Abcdefg1"), .medium)
        XCTAssertEqual(PasswordValidator.strength("Abcdefghijk1!xyz"), .strong)
    }

    func testStrengthWithoutStrengthRequirement() {
        XCTAssertTrue(PasswordValidator.validate("alllowercase", requireStrength: false).isValid)
    }
}

final class NameAndInviteCodeTests: XCTestCase {
    func testNameSanitizerCollapsesWhitespaceAndDropsSymbols() {
        XCTAssertEqual(NameValidator.sanitize("  Ada   Lovelace  "), "Ada Lovelace")
        XCTAssertEqual(NameValidator.sanitize("Ada <script>"), "Ada script")
        XCTAssertEqual(NameValidator.validationError(for: "   "), "Name is required")
    }

    func testInviteCodeRules() {
        XCTAssertTrue(InviteCodeValidator.isValid("abcd1234"))
        XCTAssertFalse(InviteCodeValidator.isValid("abc-1234"))
        XCTAssertFalse(InviteCodeValidator.isValid("abcd123"))
        XCTAssertEqual(InviteCodeValidator.format("abcd1234xyz"), "ABCD1234")
        XCTAssertEqual(InviteCodeValidator.validationError(for: "abc"), "Invite code must be exactly 8 characters")
        XCTAssertEqual(InviteCodeValidator.validationError(for: "abcd-234"), "Invite code can only contain letters and numbers")
        XCTAssertNil(InviteCodeValidator.validationError(for: "ABCD1234"))
    }
}

final class InputSanitizerTests: XCTestCase {
    func testSanitizeText() {
        XCTAssertEqual(InputSanitizer.sanitizeText("  a\r\nb\0  "), "a\nb")
    }

    func testSanitizeInteger() {
        XCTAssertEqual(InputSanitizer.sanitizeInteger("12a3"), 123)
        XCTAssertNil(InputSanitizer.sanitizeInteger("abc"))
    }

    func testLimitLength() {
        XCTAssertEqual(InputSanitizer.limitLength("abcdef", maxLength: 3), "abc")
        XCTAssertEqual(InputSanitizer.limitLength("ab", maxLength: 3), "ab")
    }
}
