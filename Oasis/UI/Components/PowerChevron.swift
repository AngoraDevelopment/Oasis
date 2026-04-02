//
//  PowerChevron.swift
//  Oasis
//
//  Created by Edgardo Ramos on 4/2/26.
//

import SwiftUI

struct PowerChevron: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: rect.midY))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()

        return path
    }
}
