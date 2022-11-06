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
            if #available(iOS 16.0, *) {
                ZStack {
                    Rectangle()
                        .fill(.green.gradient)
                    Image(systemName: "figure.walk.circle")
                        .resizable()
                        //.renderingMode(.original)
                        .foregroundColor(.white)
                        .scaledToFit()
                        .padding(40)
//                    .imageScale(.large)
                }
            } else {
                Rectangle()
                    .fill(.green)
                    .frame(width:120, height:120)
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
