//
//  LoginView.swift
//  Biu
//
//  Created by Ayari on 2019/09/28.
//  Copyright © 2019 Ayari. All rights reserved.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var inita: Initialization
    @State var showbutton = true
    @State var showreg = false
    @EnvironmentObject var loginhelper: LoginHelper
    var strengths = ["汉子", "妹子", "秀吉"]
    @State private var selectedStrength = 0

    var body: some View {
        VStack {
            //App图标
            Image(uiImage: UIImage(named: "biu_trans")!)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 150, height: 150, alignment: .center)
                .clipShape(Circle())
                .overlay(
                    Circle().stroke(Color.white, lineWidth: 4))
                .shadow(radius: 5)
                .padding(Edge.Set.top, 40)
                .padding(Edge.Set.bottom, 25)
                .padding(10)

            VStack {
                //输入邮件
                TextField("Email", text: $loginhelper.username)
                    .textContentType(.emailAddress)
                    .padding()
                    .overlay(
                        Rectangle()
                            .frame(height: 1.5, alignment: .bottom)
                            .foregroundColor(Color.gray), alignment: .bottom)
                    .padding(10)

                if self.showreg {
                    //输入密码
                        SecureField("Password", text: $loginhelper.password)
                            .padding()
                            .overlay(
                                Rectangle()
                                    .frame(height: 1.5, alignment: .bottom)
                                    .foregroundColor(Color.gray), alignment: .bottom)
                            .padding(10)
                        //j重复输入密码
                        SecureField("Repeat Password", text: $loginhelper.password2)
                            .padding()
                            .overlay(
                                Rectangle()
                                    .frame(height: 1.5, alignment: .bottom)
                                    .foregroundColor(Color.gray), alignment: .bottom)
                            .padding(10)
                        //输入用户名
                        TextField("Name", text: $loginhelper.name)
                            .padding()
                            .overlay(
                                Rectangle()
                                    .frame(height: 1.5, alignment: .bottom)
                                    .foregroundColor(Color.gray), alignment: .bottom)
                            .padding(10)
                    .padding(Edge.Set.bottom, 20)
                } else {
                        //输入密码
                        SecureField("Password", text: $loginhelper.password, onCommit: commit)
                            .padding()
                            .overlay(
                                Rectangle()
                                    .frame(height: 1.0, alignment: .bottom)
                                    .foregroundColor(Color.gray), alignment: .bottom)
                            .padding(10)
                            .padding(Edge.Set.bottom, 40)
                }

                Button(action: {
                    self.commit()
                }) {
                    if self.loginhelper.answer == "正在请求数据..." {
                        ActivityIndicator(style: .large)
                            .frame(width: 55, height: 55)
                    } else {
                        //显示下一步标志(一个被圈起来的向右箭头)
                        Image(systemName: "arrow.right.circle")
                            .renderingMode(.original)
                            .resizable()
                            .font(Font.title.weight(.ultraLight))
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 55, height: 55)
                    }
                }
                .disabled(self.loginhelper.signing)
                //我也不知道这是个啥
                Spacer()
                    .frame(width: 15, alignment: .center)
                //注册/登录切换按钮
                Button(action: {

                    withAnimation(.easeInOut(duration: 0.5)) { self.showreg.toggle() } }) {
                    if self.showreg {
                        Text("Return to Login")
                    } else {
                        Text("Sign up, If you're new!")
                    }
                }
                .disabled(self.loginhelper.signing)
                //或许是那个密码错误的提示吧
                Text(self.loginhelper.answer)
                    .font(.headline)
                    .padding(25)

            }
        }
        //在推出的过程中获取JSON
        .onDisappear(){ //inita的类型Initialization在翻译的时候为什么会被标上罗马音......
            //in･ì･tial･i･zá･tion
            //大概是初始化的意思的说
            self.inita.getJsonData()
        }
        .padding(20)
        .gesture(
            DragGesture()
                .onChanged({ (_) in
                    UIApplication.shared.endEditing()
                })
        )
        //        .sheet(isPresented: $signin) {
        //            SigninView()
        //                .environmentObject(self.loginhelper)
        //        }
    }
    

    func commit() {
        UIApplication.shared.endEditing()
        self.loginhelper.answer = "正在请求数据..."
        //reg?|redʒ|的话......注册的意思嘛
        if self.showreg {
            self.loginhelper.signup()
        } else {
            self.loginhelper.login()
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()//这不是个struct嘛???怎么成func了QAQ
    }
}
