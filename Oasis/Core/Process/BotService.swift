//
//  BotService.swift
//  Oasis
//
//  Created by Edgardo Ramos on 4/1/26.
//

final class BotService: ServiceProcess {
    init() {
        super.init(
            name: "Bot",
            executable: OasisConfig.nodePath,
            arguments: ["bot.js"],
            workingDirectory: OasisConfig.rootPath
        )
    }
}
