//
//  RuntimeService.swift
//  Oasis
//
//  Created by Edgardo Ramos on 4/1/26.
//

final class RuntimeService: ServiceProcess {
    init() {
        super.init(
            name: "Skill Runtime",
            executable: OasisConfig.nodePath,
            arguments: ["skill-runtime/server.js"],
            workingDirectory: OasisConfig.rootPath
        )
    }
}
