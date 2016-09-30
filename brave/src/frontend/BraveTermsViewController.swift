//
//  BraveTermsViewController.swift
//  Client
//
//  Created by James Mudgett on 9/29/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import UIKit
import Foundation

class BraveTermsViewController: UIViewController {
    
    var braveLogo: UIImageView!
    var termsLabel: UILabel!
    var optLabel: UILabel!
    var checkButton: UIButton!
    
    override func loadView() {
        super.loadView()
        
        view.backgroundColor = UIColor(white: 0.0, alpha: 0.25)
    }
}