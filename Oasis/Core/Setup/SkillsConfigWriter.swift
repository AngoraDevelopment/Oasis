//
//  SkillsConfigWriter.swift
//  Oasis
//
//  Created by Edgardo Ramos on 4/5/26.
//

import Foundation

enum SkillsConfigWriter {
    static let skillsDirectory = "/Users/edgardoramos/Oasis/skills"

    static func availableSkills() -> [String] {
        guard let items = try? FileManager.default.contentsOfDirectory(
            atPath: skillsDirectory
        ) else {
            return []
        }

        return items
            .filter { name in
                var isDirectory: ObjCBool = false
                let fullPath = "\(skillsDirectory)/\(name)"
                return FileManager.default.fileExists(atPath: fullPath, isDirectory: &isDirectory) && isDirectory.boolValue
            }
            .sorted()
    }

    static func applySelection(selectedSkills: [String]) {
        let skills = availableSkills()

        for skill in skills {
            let shouldBeActive = selectedSkills.contains(skill)
            setSkill(skill, active: shouldBeActive)
        }
    }

    static func setSkill(_ skillName: String, active: Bool) {
        let configPath = "\(skillsDirectory)/\(skillName)/config.json"

        guard let data = try? Data(contentsOf: URL(fileURLWithPath: configPath)),
              var json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return
        }

        json["isActive"] = active

        guard let updatedData = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted]) else {
            return
        }

        try? updatedData.write(to: URL(fileURLWithPath: configPath), options: .atomic)
    }
}
