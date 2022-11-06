//
//  AppIconView.swift
//  Walkly
//
//  Created on 2022/10/10.
//  
//

import SwiftUI

struct AppIconView: View {
    var body: some View {
        HStack {
            ZStack {
                Rectangle()
                    .fill(.green.gradient)
                Image(systemName: "figure.walk.circle")
                    .resizable()
                //.renderingMode(.original)
                    .foregroundColor(.white)
                    .scaledToFit()
                    .padding(40)
                //.imageScale(.large)
            }
        }
        .frame(width: 300, height: 300)
    }
}

struct AppIconView_Previews: PreviewProvider {
    static var previews: some View {
        AppIconView()
    }
}
