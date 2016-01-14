//
//  DimmingPresentationController.swift
//  StoreSearch
//
//  Created by Hasan Rafi on 1/13/16.
//  Copyright © 2016 Hasan Rafi. All rights reserved.
//

import Foundation
import UIKit

class DimmingPresentationController: UIPresentationController {
    override func shouldRemovePresentersView() -> Bool {
        return false
    }
}