//
//  TransferTableViewCell.swift
//  FinancialTracker
//
//  Created by Boyan Pavlov on 18.02.22.
//

import UIKit

protocol TransferTableViewCellDelegate: AnyObject {
    func didTapTransferStateButton(sender: TransferTableViewCell)
}

class TransferTableViewCell: UITableViewCell {
    @IBOutlet var transferTitleLabel: UILabel!
    @IBOutlet var transferDate: UILabel!
    @IBOutlet var transferStateButton: UIButton!
    
    weak var delegate: TransferTableViewCellDelegate?
    
    @IBAction func transferStateButtonTapped() {        
        delegate?.didTapTransferStateButton(sender: self)
    }
}
