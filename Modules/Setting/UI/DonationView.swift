//
//  DonationView.swift
//  identifier-ios (iOS)
//
//  Created by Pete Li on 9/4/2022.
//

import SwiftUI
import StoreKit
import PLKit

struct DonationView: View {
    @State private var iapDonate: SKProduct?

    var body: some View {
        VStack {
            PKText(title, .title1)
                .padding(.bottom)

            PKText(content, .title3)

            let displayPrice = iapDonate?.localizedPrice() ?? ""
            PKButton(pkls("donate") + " \(displayPrice)") {
                pay()
            }
            .asPrimary()
            .padding(.vertical)

            Spacer()
        }
        .padding()
        .task {
            iapDonate = try? await PKPayment.shared.getProduct(K.IAP.donate)
        }
    }

    private func pay() {
        guard iapDonate.isNotNil else { return }

        PLKHUD.show()
        PKPayment.shared.purchaseProduct(iapDonate!) { error in
            if error.isNotNil {
                PLKHUD.dismiss(withError: error!.localizedDescription)
            } else {
                PLKHUD.success(withMessage: pkls("thank_you"))
            }
        }
    }
}

struct DonationView_Previews: PreviewProvider {
    static var previews: some View {
        DonationView()
    }
}

extension DonationView {
    private var title: String { "We need your support!" }
    private var content: String {
        """
        We believe this little app has huge potential of shinning bright like a diamond, so we keep working on it to bring  more features!

        But we can't do this without your support, Please donate to help improving the app..

        All donations will use in the app development, buying  accurate data and resource.
        """
    }
}
