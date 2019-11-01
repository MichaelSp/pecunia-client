//
//  ChipcardPinRequestController.swift
//  Pecunia
//
//  Created by Frank Emminghaus on 30.12.16.
//  Copyright © 2016 Frank Emminghaus. All rights reserved.
//

import Foundation
import HBCI4Swift

class ChipcardPinRequestController : NSWindowController {
    @IBOutlet var messageField:NSTextField!
    var _userIdName:String?
    var _timer:Timer?
    var card:HBCISmartcardDDV!
    var connectResult = HBCISmartcard.ConnectResult.no_card;
    
    override func awakeFromNib() {
        messageField.stringValue = String(format: NSLocalizedString("AP351", comment: ""));
        
        let timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(checkPin), userInfo: nil, repeats: false);
        RunLoop.current.add(timer, forMode: RunLoop.Mode.modalPanel);
        _timer = timer;
    }
    
    @objc func checkPin() {
        if let timer = _timer {
            timer.invalidate();
        }
        if card == nil {
            card = ChipcardManager.manager.card;
        }
        
        if !card.verifyPin() {
            self.close();
            NSApp.stopModal(withCode: NSApplication.ModalResponse.cancel);
        } else {
            self.close();
            NSApp.stopModal(withCode: NSApplication.ModalResponse.OK);

        }
    }
    
    @IBAction override func cancelOperation(_ sender: Any?) {
        if let timer = _timer {
            timer.invalidate();
        }
        self.close();
        NSApp.stopModal(withCode: NSApplication.ModalResponse.cancel);
    }
    
}
