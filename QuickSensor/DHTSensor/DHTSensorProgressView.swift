//
//  DHTSensorProgressView.swift
//  QuickSensor
//
//  Created by 徐嗣苗 on 2022/11/8.
//

import SwiftUI

enum DHTDataCategory: String, Identifiable {
    case temperature, humidity
    var id: Self { self }
}

struct DHTSensorProgressView: View {
    let temperatureGradient = Gradient(colors: [.teal, .yellow, .red])
    let humidityGradient = Gradient(colors: [.indigo, .cyan, .mint])
    let sliceSize = 0.4
    let progress: Double
    let category: DHTDataCategory

    private let percentageFormatter: NumberFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .percent
        return numberFormatter
    }()

    var strokeGradient: AngularGradient {
        AngularGradient(gradient: category == .temperature ? temperatureGradient : humidityGradient, center:  .center, startAngle: Angle(degrees: 0), endAngle: Angle(degrees: 360 * (1 - sliceSize)))
    }

    var rotateAngle: Angle {
        .degrees(90 + sliceSize * 360 * 0.5)
    }

    private func strokeStyle(_ proxy: GeometryProxy) -> StrokeStyle {
        StrokeStyle(lineWidth: 0.1 * min(proxy.size.width, proxy.size.height),
                    lineCap: .round)
    }

    public var body: some View {
        GeometryReader { proxy in
            ZStack {
                Group {
                    Circle()
                        .trim(from: 0, to: 1 - CGFloat(self.sliceSize))
                        .stroke(.ultraThickMaterial,
                                style: self.strokeStyle(proxy))
                        .padding(.all, /*@START_MENU_TOKEN@*/10/*@END_MENU_TOKEN@*/)

                    Circle()
                        .trim(from: 0, to: CGFloat(self.progress * (1 - self.sliceSize)))
                        .stroke(strokeGradient,
                                style: self.strokeStyle(proxy))
                        .padding(.all, /*@START_MENU_TOKEN@*/10/*@END_MENU_TOKEN@*/)
                }
                .rotationEffect(self.rotateAngle, anchor: /*@START_MENU_TOKEN@*/ .center/*@END_MENU_TOKEN@*/)
                .offset(x: 0, y: 0.1 * min(proxy.size.width, proxy.size.height))
            }
        }
    }
}
