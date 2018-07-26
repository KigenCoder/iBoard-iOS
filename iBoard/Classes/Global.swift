//
//  Global.swift
//  iBoard
//
//  Created by Kigen on 22/06/2018.
//  Copyright © 2018 Kigen. All rights reserved.
//
import UIKit
import Foundation
import iProgressHUD


class Global{
    static func baseUrl () ->String {
        //return "http://iboard.dev"
        return "http://167.99.101.175"
    }
    
    static func showProgressView(_ view: UIView){
        
        let iprogress: iProgressHUD = iProgressHUD()
        iprogress.isShowModal = true
        iprogress.isShowCaption = true
        iprogress.isTouchDismiss = true
        
        // Attach iProgressHUD to views
        iprogress.attachProgress(toViews: view)
        
        // Show iProgressHUD directly from view
        view.showProgress()

    }
    

}

