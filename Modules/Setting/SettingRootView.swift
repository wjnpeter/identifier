//
//  SettingRootView.swift
//  identifier-ios (iOS)
//
//  Created by Pete Li on 29/3/2022.
//

import SwiftUI
import PLKit

struct SettingRootView: View {
    @EnvironmentObject var sharedUI: PKUI

    let authWireframe: AuthWireframe
    let familyWireframe: FamilyWireframe

    @ObservedObject var themeVM = ThemeViewModel.shared
    @ObservedObject var authVM = AuthViewModel.shared

    @State private var alert: PKAlertItem?

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading) {
                    Section(pkls("general")) {
                        vTheme
                        vContact
                        vDonation

                        if !authVM.isLoggedIn {
                            vSignInOut
                        }
                    }

                    Spacer(minLength: themeVM.spacing.section)

                    if authVM.isLoggedIn {
                        Section(content: {
                            // https://pcstudio.atlassian.net/browse/PCS-4
//                            vMyFamily

                            vSignInOut

                        }, header: {
                            HStack {
                                PKText(pkls("account"))

                                if let acountName = authVM.userNickName ?? authVM.userEmail {
                                    PKText("(\(acountName))")
                                }
                            }
                        })

                        Section(pkls("account")) {
//                            vMyFamily
//
//                            vSignInOut
                            vDeleteAccount
                        }
                    }

                    Spacer(minLength: themeVM.spacing.section)

                    vVersion
                }
            }
            .navigationTitle(pkls("settings"))
            .padding()
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private var vMyFamily: some View {
        makeAction(icon: "person.3", pkls("my_family"), rightView: familyWireframe.addButton(), action: {
            sharedUI.fullScreenCoverView = AnyView(familyWireframe.listView())
        })
    }

    private var vVersion: some View {
        let appName = PKUtils.bundleDisplayName() ?? ""
        let buildVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        return PKText("\(appName) v\(buildVersion ?? "")")
            .frame(maxWidth: .infinity, alignment: .center)
    }

    private var vDeleteAccount: some View {
        PKButton(pkls("delete_account"), action: {
            sharedUI.alert = PKAlertItem(title: pkls("delete_account"), message: pkls("do_you_want_to_continue?"), primaryButton: .destructive(Text(pkls("delete"))) {
                Task {
                    // FixMe: remomve s3 authUserId folder

                    await authVM.deleteUser()
                }
            }, secondaryButton: .cancel())
        })
        .asSecondary()
        .frame(maxWidth: .infinity, alignment: .center)
    }

    @ViewBuilder
    private var vSignInOut: some View {
        PKButton(pkls(authVM.isLoggedIn ? "sign_out" : "sign_in"), action: {
            if authVM.isLoggedIn {
                Task {
                    await authVM.signOut()
                }

            } else {
                sharedUI.fullScreenCoverView = AnyView(
                    authWireframe.rootView()
                        .modifier(WithTitleBar())
                )
            }
        })
        .asSecondary()
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private var vReminder: some View {
        PKButton(icon: UIImage(systemName: "bell"), action: {})
            .asCircle(title: pkls("reminder"))
            .padding()
            .modifier(WithinCard())
    }

    private var vCalendar: some View {
        PKButton(icon: UIImage(systemName: "calendar"), action: {})
            .asCircle(title: pkls("calendar"))
            .padding()
            .modifier(WithinCard())
    }

    private var vTheme: some View {
        let toggle = Toggle("", isOn: Binding(get: { themeVM.dark }, set: { isOn in themeVM.updateDarkMode(isOn) }))
        return makeAction(icon: "paintpalette", pkls("dark_mode"), rightView: toggle, action: {
            themeVM.updateDarkMode(!themeVM.dark)
        })
    }

    private var vContact: some View {
        makeAction(icon: "envelope", pkls("feedback"), action: {
            PKUtils.sendEmail(to: K.feedbackEMail)
        })
    }

    private var vDonation: some View {
        makeAction(icon: "dollarsign.circle", pkls("help_the_project"), action: {
            sharedUI.fullScreenCoverView = AnyView(
                DonationView()
                    .modifier(WithTitleBar())
            )
        })
    }

    private var vAbout: some View {
        makeAction(icon: "info", pkls("about"), action: {})
    }
}

extension SettingRootView {
    func makeAction(icon: String? = nil, _ title: String, rightIcon: String? = nil, action: Callback? = nil) -> some View {
        makeAction(icon: icon, title, rightView: rightIcon.isNotEmpty ? Image(systemName: rightIcon!) : nil, action: action)
    }

    func makeAction<RightView: View>(icon: String? = nil, _ title: String, rightView: RightView? = nil, action: Callback? = nil) -> some View {
        Button(action: action ?? {}, label: {
            makeActionContent(icon: icon, title, rightView: rightView)
        })
            .disabled(action.isNil && rightView.isNil)
    }

    func makeAction<RightView: View, Destination: View>(icon: String? = nil, _ title: String, rightView: RightView? = nil, destination: Destination) -> some View {
        NavigationLink(destination: { destination }, label: {
            makeActionContent(icon: icon, title, rightView: rightView)
        })
    }

    private func makeActionContent<RightView: View>(icon: String? = nil, _ title: String, rightView: RightView? = nil) -> some View {
        HStack {
            if icon.isNotEmpty {
                Image(systemName: icon!)
                    .frame(width: 32)
            }

            PKText(title)
                .multilineTextAlignment(.center)

            if icon.isNotEmpty || rightView.isNotNil {
                Spacer()
            }

            rightView
        }
        .frame(maxWidth: .infinity)
        .foregroundColor(themeVM.textColorOnBackground)
        .modifier(WithinCard())
    }
}

struct SettingRootView_Previews: PreviewProvider {
    static var previews: some View {
        SettingRootView(authWireframe: AuthWireframe(), familyWireframe: FamilyWireframe())
    }
}
