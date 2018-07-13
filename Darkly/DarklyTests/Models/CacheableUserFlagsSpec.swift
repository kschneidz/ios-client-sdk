//
//  CacheableUserFlagsSpec.swift
//  DarklyTests
//
//  Created by Mark Pokorny on 2/21/18. +JMJ
//  Copyright © 2018 LaunchDarkly. All rights reserved.
//

import Foundation
import Quick
import Nimble
@testable import LaunchDarkly

final class CacheableUserFlagsSpec: QuickSpec {
    struct Constants {
        static let lastUpdatedString = "2018-02-21T18:10:40.823Z"
        static let lastUpdatedDate = lastUpdatedString.dateValue
    }

    override func spec() {
        initSpec()
        dictionaryValueSpec()
        equalsSpec()
    }

    private func initSpec() {
        var subject: CacheableUserFlags?

        describe("init with flags and date") {
            beforeEach {
                subject = CacheableUserFlags(flags: DarklyServiceMock.Constants.featureFlags(includeNullValue: false, includeVersions: true), lastUpdated: Constants.lastUpdatedDate)
            }
            it("creates a matching CacheableUserFlags") {
                expect(AnyComparer.isEqual(subject?.flags, to: DarklyServiceMock.Constants.featureFlags(includeNullValue: false, includeVersions: true))).to(beTrue())
                expect(subject?.lastUpdated) == Constants.lastUpdatedDate
            }
        }

        describe("init with user") {
            var user: LDUser!
            var flagStoreMock: FlagMaintainingMock! { return user.flagStore as! FlagMaintainingMock }
            var userFlags: [LDFlagKey: Any]? { return flagStoreMock.featureFlags }

            beforeEach {
                user = LDUser.stub()
                subject = CacheableUserFlags(user: user)
            }
            it("creates a matching CacheableUserFlags") {
                expect(AnyComparer.isEqual(subject?.flags, to: userFlags)).to(beTrue())
                expect(subject?.lastUpdated) == user.lastUpdated
            }
        }

        describe("init with dictionary") {
            var flagDictionary: [String: Any]!
            context("with flags and lastUpdated") {
                context("matching types") {
                    beforeEach {
                        flagDictionary = [CacheableUserFlags.CodingKeys.flags.rawValue: DarklyServiceMock.Constants.featureFlags(includeNullValue: false, includeVersions: true)
                            .dictionaryValue(exciseNil: false),
                                          CacheableUserFlags.CodingKeys.lastUpdated.rawValue: Constants.lastUpdatedString]
                        subject = CacheableUserFlags(dictionary: flagDictionary)
                    }
                    it("creates a matching CacheableUserFlags") {
                        expect(subject).toNot(beNil())
                        expect(AnyComparer.isEqual(subject?.flags, to: DarklyServiceMock.Constants.featureFlags(includeNullValue: false, includeVersions: true))).to(beTrue())
                        expect(subject?.lastUpdated) == Constants.lastUpdatedDate
                    }
                }
                context("flag type mismatch") {
                    beforeEach {
                        flagDictionary = [CacheableUserFlags.CodingKeys.flags.rawValue: Constants.lastUpdatedString,
                                          CacheableUserFlags.CodingKeys.lastUpdated.rawValue: Constants.lastUpdatedString]
                        subject = CacheableUserFlags(dictionary: flagDictionary)
                    }
                    it("returns nil") {
                        expect(subject).to(beNil())
                    }
                }
                context("date type mismatch") {
                    beforeEach {
                        flagDictionary = [CacheableUserFlags.CodingKeys.flags.rawValue: DarklyServiceMock.Constants.featureFlags(includeNullValue: false, includeVersions: true),
                                          CacheableUserFlags.CodingKeys.lastUpdated.rawValue: Constants.lastUpdatedDate]
                        subject = CacheableUserFlags(dictionary: flagDictionary)
                    }
                    it("creates a matching CacheableUserFlags with the current date") {
                        expect(AnyComparer.isEqual(subject?.flags, to: DarklyServiceMock.Constants.featureFlags(includeNullValue: false, includeVersions: true))).to(beTrue())
                        expect(subject?.lastUpdated.timeIntervalSinceNow) > -0.1   //The exact date won't be right, so this is close enough
                    }
                }
            }
            context("without flags") {
                beforeEach {
                    flagDictionary = [CacheableUserFlags.CodingKeys.lastUpdated.rawValue: Constants.lastUpdatedString]
                    subject = CacheableUserFlags(dictionary: flagDictionary)
                }
                it("returns nil") {
                    expect(subject).to(beNil())
                }
            }
            context("without lastUpdated") {
                beforeEach {
                    flagDictionary = [CacheableUserFlags.CodingKeys.flags.rawValue: DarklyServiceMock.Constants.featureFlags(includeNullValue: false, includeVersions: true)]
                    subject = CacheableUserFlags(dictionary: flagDictionary)
                }
                it("creates a matching CacheableUserFlags with the current date") {
                    expect(AnyComparer.isEqual(subject?.flags, to: DarklyServiceMock.Constants.featureFlags(includeNullValue: false, includeVersions: true))).to(beTrue())
                    expect(subject?.lastUpdated.timeIntervalSinceNow) > -0.1   //The exact date won't be right, so this is close enough
                }
            }
        }

        describe("init with object") {
            var object: Any!

            context("object is a dictionary") {
                beforeEach {
                    object = [CacheableUserFlags.CodingKeys.flags.rawValue: DarklyServiceMock.Constants.featureFlags(includeNullValue: false, includeVersions: true)
                        .dictionaryValue(exciseNil: false),
                              CacheableUserFlags.CodingKeys.lastUpdated.rawValue: Constants.lastUpdatedString]
                    subject = CacheableUserFlags(object: object)
                }
                it("creates a matching CacheableUserFlags") {
                    expect(subject).toNot(beNil())
                    expect(AnyComparer.isEqual(subject?.flags, to: DarklyServiceMock.Constants.featureFlags(includeNullValue: false, includeVersions: true))).to(beTrue())
                    expect(subject?.lastUpdated) == Constants.lastUpdatedDate
                }
            }
            context("object is not a dictionary") {
                beforeEach {
                    object = Constants.lastUpdatedString
                    subject = CacheableUserFlags(object: object)
                }
                it("returns nil") {
                    expect(subject).to(beNil())
                }
            }
        }
    }

    func dictionaryValueSpec() {
        var featureFlags: [LDFlagKey: FeatureFlag]!
        var subject: CacheableUserFlags!
        var subjectDictionary: [String: Any]!
        var subjectDictionaryFlags: [String: Any]? { return subjectDictionary[CacheableUserFlags.CodingKeys.flags.rawValue] as? [String: Any] }
        var subjectDictionaryFeatureFlags: [LDFlagKey: FeatureFlag]? { return subjectDictionaryFlags?.flagCollection }
        var subjectDictionaryLastUpdated: String? { return subjectDictionary[CacheableUserFlags.CodingKeys.lastUpdated.rawValue] as? String }
        describe("dictionaryValue") {
            context("when flags do not contain null values") {
                beforeEach {
                    featureFlags = DarklyServiceMock.Constants.featureFlags(includeNullValue: false, includeVersions: true)
                    subject = CacheableUserFlags(flags: featureFlags, lastUpdated: Constants.lastUpdatedDate)
                    subjectDictionary = subject.dictionaryValue
                }
                it("creates a matching dictionary") {
                    expect(subjectDictionaryFeatureFlags) == featureFlags
                    expect(subjectDictionaryLastUpdated) == Constants.lastUpdatedString
                }
            }
            context("when flags contain null values") {
                beforeEach {
                    subject = CacheableUserFlags(flags: DarklyServiceMock.Constants.featureFlags(includeNullValue: true, includeVersions: true), lastUpdated: Constants.lastUpdatedDate)
                    subjectDictionary = subject.dictionaryValue
                }
                it("creates a matching dictionary without null values") {
                    expect(subjectDictionaryFeatureFlags) == DarklyServiceMock.Constants.featureFlags(includeNullValue: false, includeVersions: true)
                    expect(subjectDictionaryLastUpdated) == Constants.lastUpdatedString
                }
            }
            context("when flags contain null versions") {
                var flagDictionary: [String: Any]?
                var flagDictionaryValue: Any? { return flagDictionary?[FeatureFlag.CodingKeys.value.rawValue] }
                var flagDictionaryVersion: Int? { return flagDictionary?[FeatureFlag.CodingKeys.version.rawValue] as? Int }
                beforeEach {
                    featureFlags = DarklyServiceMock.Constants.featureFlags(includeNullValue: false, includeVersions: false)
                    subject = CacheableUserFlags(flags: featureFlags, lastUpdated: Constants.lastUpdatedDate)
                    subjectDictionary = subject.dictionaryValue
                }
                it("creates a matching dictionary with version placeholders") {
                    featureFlags.keys.forEach { (key) in
                        flagDictionary = subjectDictionaryFlags?[key] as? [String: Any]
                        expect(AnyComparer.isEqual(flagDictionaryValue, to: featureFlags[key]?.value)).to(beTrue())
                        expect(flagDictionaryVersion) == FeatureFlag.Constants.nilVersionPlaceholder
                    }
                }
            }
        }
    }

    func equalsSpec() {
        var subject: CacheableUserFlags!
        var other: CacheableUserFlags!
        describe("equals") {
            context("when flags and lastUpdated match") {
                beforeEach {
                    subject = CacheableUserFlags(flags: DarklyServiceMock.Constants.featureFlags(includeNullValue: false, includeVersions: true), lastUpdated: Constants.lastUpdatedDate)
                    other = CacheableUserFlags(flags: DarklyServiceMock.Constants.featureFlags(includeNullValue: false, includeVersions: true), lastUpdated: Constants.lastUpdatedDate)
                }
                it("returns true") {
                    expect(subject) == other
                }
            }
            context("when flags do not match") {
                beforeEach {
                    subject = CacheableUserFlags(flags: DarklyServiceMock.Constants.featureFlags(includeNullValue: true, includeVersions: true), lastUpdated: Constants.lastUpdatedDate)
                    other = CacheableUserFlags(flags: DarklyServiceMock.Constants.featureFlags(includeNullValue: false, includeVersions: true), lastUpdated: Constants.lastUpdatedDate)
                }
                it("returns false") {
                    expect(subject) != other
                }
            }
            context("when last updates does not match") {
                beforeEach {
                    subject = CacheableUserFlags(flags: DarklyServiceMock.Constants.featureFlags(includeNullValue: false, includeVersions: true), lastUpdated: Constants.lastUpdatedDate)
                    other = CacheableUserFlags(flags: DarklyServiceMock.Constants.featureFlags(includeNullValue: false, includeVersions: true), lastUpdated: Date())
                }
                it("returns false") {
                    expect(subject) != other
                }
            }
        }
    }
}
