//
//  ContentView.swift
//  rangefinder
//
//  Created by skyjerry on 2024/3/19.
//

import SwiftUI
import ARKit

struct ContentView: View {
    @State private var distance: String = "0 m"
    @State private var screenCenterY: CGFloat = 0
    
    var body: some View {
        VStack {
            ZStack(alignment: .center) {
                ARViewContainer(distance: $distance, screenCenterY: $screenCenterY)
                    .edgesIgnoringSafeArea(.all)
                
                Image(systemName: "circle.fill")
                    .font(.headline)
                    .foregroundColor(.red)
                    .position(x: UIScreen.main.bounds.width / 2, y: screenCenterY)
            }
            .frame(height: 300)
            
            VStack {
                Text("距离信息")
                    .font(.title)
                Text(distance)
                    .font(.headline)
            }
            .frame(maxHeight: .infinity)
        }
    }
}

//#Preview {
//    ContentView()
//}
