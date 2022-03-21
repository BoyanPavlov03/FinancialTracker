//
//  TransferTableViewCell.swift
//  FinancialTracker
//
//  Created by Boyan Pavlov on 18.02.22.
//

import UIKit

protocol TransferTableViewCellDelegate: AnyObject {
    func didTapTransferStateButton(sender: TransferTableViewCell, with title: String, section: Int, row: Int)
}

class TransferTableViewCell: UITableViewCell {
    @IBOutlet var transferTitleLabel: UILabel!
    @IBOutlet var transferDate: UILabel!
    @IBOutlet var transferStateButton: UIButton!
    
    weak var delegate: TransferTableViewCellDelegate?
    
    var section: Int?
    var row: Int?
    
    @IBAction func transferStateButtonTapped() {        
        delegate?.didTapTransferStateButton(sender: self, with: transferStateButton.titleLabel?.text ?? "Nil", section: section ?? 0, row: row ?? 0)
    }
}
