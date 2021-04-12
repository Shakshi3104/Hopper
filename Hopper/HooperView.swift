//
//  HooperView.swift
//  Hopper
//
//  Created by MacBook Pro M1 on 2021/04/12.
//

import SwiftUI

struct HooperView: View {
    var body: some View {
        VStack {
            Spacer()
            Text("Trampoline Motion Classifier")
                .foregroundColor(.secondary)
                .font(.title2)
            VStack {
                Text("Prepare")
                    .foregroundColor(.accentColor)
                    .font(.title)
                Text("")
                    .fontWeight(.semibold)
                    .font(.largeTitle)
            }.padding(.vertical, 50)
            Spacer()
        }
    }
}

struct HooperView_Previews: PreviewProvider {
    static var previews: some View {
        HooperView()
            .preferredColorScheme(.dark)
    }
}
