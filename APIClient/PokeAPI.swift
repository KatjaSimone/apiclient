//
//  PokeAPI.swift
//  APIClient
//
//  Created by Nils Fischer on 20.05.16.
//  Copyright © 2016 iOS Dev Kurs Universität Heidelberg. All rights reserved.
//

import Foundation
import Moya
import Freddy


/// The abstraction of the [Poke API](http://pokeapi.co) REST API.
enum PokeAPI: Moya.TargetType, Cacheable {
    
    
    /// MARK: Endpoints
    
    case pokedex(NamedResource<Pokedex>)
    case pokemonSpecies(NamedResource<PokemonSpecies>)
    case pokemon(NamedResource<Pokemon>)
    
    
    // MARK: Network Abstraction
    
    var baseURL: URL { return URL(string: "http://pokeapi.co/api/v2")! }
    
    var path: String {
        switch self {
        case .pokedex(let namedResource): return "/pokedex/\(namedResource.name)"
        case .pokemonSpecies(let namedResource): return "/pokemon-species/\(namedResource.name)"
        case .pokemon(let namedResource): return "/pokemon/\(namedResource.name)"
        }
    }
    
    var method: Moya.Method { return .get }
    
    var parameters: [String : Any]? {
        switch self {
        default: return nil
        }
    }
    
    var parameterEncoding: ParameterEncoding {
        return URLEncoding.default
    }
    
    // TODO: Provide sample data for testing
    var sampleData: Data {
        switch self {
        default: return "".data(using: String.Encoding.utf8)!
        }
    }
    
    var task: Task {
        return .request
    }
    
    var cacheIdentifier: String {
        return self.path
    }
}


/// Represents a resource provided by the Poke API by its name
struct NamedResource<Resource: Freddy.JSONDecodable>: Freddy.JSONDecodable {
    
    let name: String
    
    init(name: String) {
        self.name = name
    }
    
    init(json: JSON) throws {
        self.name = try json.getString(at: "name")
    }
    
}

/// Represents an image resource provided by its URL
struct ImageResource: JSONDecodable {
    
    let url: URL
    
    init(json: JSON) throws {
        guard let url = URL(string: try String(json: json)) else {
            throw DecodeError.unexpectedValue(json, expected: "URL")
        }
        self.url = url
    }
}

struct Language: JSONDecodable {
    
    let name: String
    
    init(json: JSON) throws {
        self.name = try json.decode(at: "name")
    }
    
}


// MARK: - Decoding Utility

enum DecodeError: Swift.Error {
    case unexpectedValue(JSON, expected: String)
    case emptyLanguageList
}

extension JSON {
    
    /// From a list of JSON objects at `path`, that each contains an associated `language` (given by a `NamedResource` representation), select the one most appropriate for the current device locale.
    func getLocalized(at path: JSONPathType) throws -> JSON {
        let preferredLanguages = NSLocale.preferredLanguages
        guard let localized = try self.getArray(at: path).sorted(by: { lhs, rhs in
            guard let lhsLanguage: NamedResource<Language> = try? lhs.decode(at: "language"), let lhsPriority = preferredLanguages.index(where: { $0.hasPrefix(lhsLanguage.name) }) else {
                return false
            }
            guard let rhsLanguage: NamedResource<Language> = try? rhs.decode(at: "language"), let rhsPriority = preferredLanguages.index(where: { $0.hasPrefix(rhsLanguage.name) }) else {
                return true
            }
            return lhsPriority < rhsPriority
        }).first else {
            throw DecodeError.emptyLanguageList
        }
        return localized
    }
    
}
