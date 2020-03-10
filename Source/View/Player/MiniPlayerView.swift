//
//  MiniPlayerView.swift
//  Biu
//
//  Created by Ayari on 2019/09/27.
//  Copyright © 2019 Ayari. All rights reserved.
//

import SwiftUI
import KingfisherSwiftUI

struct MiniPlayerView: View {

    @EnvironmentObject var state: AppState

    var body: some View {
        HStack {
            ImageView(imageURL: "\(Router.biuBaseAPICover)/\(self.state.nowPlaying?.id ?? "0")", width: 50, height: 50)
                .clipShape(Circle())
            VStack {
                if !self.state.radioIsLoading {
                    HStack {
                        Text(self.state.nowPlaying?.title ?? "Nothing")
                            .lineLimit(1)
                            .font(.system(size: 16))
                        Spacer()
                    }
                    HStack {
                        Text(self.state.nowPlaying?.singer ?? "Nothing")
                            .lineLimit(1)
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        Spacer()
                    }
                } else {
                    HStack {
                        Text("正在加载FM: \(FMViewItem.FMContents[self.state.fmmode])...")
                            .font(.subheadline)
                        Spacer()
                    }
                }
            }
            VStack(alignment: .center) {
                HStack {
                    if !self.state.isLoading {
                        Button(action: {
                            self.state.playingtoggle()
                        }) {
                            Image(systemName: self.state.isPlaying ? "pause" : "play")
                                .resizable()
                                .cornerRadius(5)
                                .font(Font.title.weight(.light))
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 25, height: 25)
                        }
                        .padding(Edge.Set.trailing, 20)
                        .buttonStyle(PlainButtonStyle())
                        .foregroundColor(Color.blue)
                    } else {
                        ActivityIndicator(style: .large)
                            .frame(width: 25, height: 25)
                            .padding(Edge.Set.trailing, 20)

                    }
                    Button(action: {
                        self.state.push()

                    }) {
                        Image(systemName: "forward.end")
                            .resizable()
                            .font(Font.title.weight(.light))
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 25, height: 25)
                    }
                }
                .padding(Edge.Set.trailing, 40)
                .buttonStyle(PlainButtonStyle())
                .foregroundColor(Color.blue)
            }
        }
        .padding(Edge.Set.leading, 40)
        .padding(Edge.Set.bottom, 10)
    }
}
