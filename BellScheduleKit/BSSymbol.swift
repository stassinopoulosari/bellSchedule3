//
//  BSSymbol.swift
//  bellScheduleKit
//
//  Created by Ari Stassinopoulos on 2023-05-25.
//

import Foundation

public struct BSSymbol: Hashable {
    public var key: String;
    public var defaultValue: String;
    public var configurable: Bool;
    private var realConfiguredValue: String?;
    
    public init(key: String, defaultValue: String, configurable: Bool, realConfiguredValue: String? = nil) {
        self.key = key
        self.defaultValue = defaultValue
        self.configurable = configurable
        self.realConfiguredValue = realConfiguredValue
    }
    
    public var configuredValue: String {
        get {
            if let configuredValue = realConfiguredValue {
                return configuredValue;
            }
            return "";
        }
        set {
            if newValue.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
                realConfiguredValue = nil;
            } else {
                realConfiguredValue = newValue;
            }
        }
    };
    public var value: String {
        if configurable {
            return configuredValue;
        }
        return defaultValue;
    }
    func render(templateString: String) -> String {
        return templateString.replacingOccurrences(of: "$(\(key)", with: value);
    }
}

public struct BSSymbolTable {
    public var symbolsDict: [String: BSSymbol];
    private var symbols: [BSSymbol] {
        return Array(symbolsDict.values);
    }
    public func render(templateString: String) {
        var renderedString = templateString;
        symbols.forEach { symbol in
            renderedString = symbol.render(templateString: renderedString);
        }
    }
    
    mutating public func register(customSymbols: [String: String]) {
        customSymbols.forEach { (customSymbolKey, customSymbolValue) in
            if symbolsDict.keys.contains(customSymbolKey),
               symbolsDict[customSymbolKey]!.configurable
            {
                symbolsDict[customSymbolKey]?.configuredValue = customSymbolValue
            } else {
                print("Tried to register invalid custom symbol: \(customSymbolKey) = \(customSymbolValue)");
            }
        }
    }
    
    public static func from(dictionary symbolTableDictionary: [String: Any]) -> BSSymbolTable {
        var symbols = [String: BSSymbol]();
        symbolTableDictionary.forEach { (key: String, symbolObject: Any) in
            if let symbolDictionary = symbolObject as? [String: Any],
               let configurable = symbolDictionary["configurable"] as? Bool,
               let value = symbolDictionary["value"] as? String
            {
                symbols[key] = BSSymbol(key: key, defaultValue: value, configurable: configurable);
            }
        }
        return BSSymbolTable(symbolsDict: symbols);
    }
    
    public static func from(string symbolTableString: String) -> BSSymbolTable? {
        do {
            if let symbolTableDictionary = try JSONSerialization.jsonObject(with: symbolTableString.data(using: .utf8)!) as? [String: Any] {
                return BSSymbolTable.from(dictionary: symbolTableDictionary);
            } else {
                return nil;
            }
        } catch {
            return nil;
        }
    }
}
