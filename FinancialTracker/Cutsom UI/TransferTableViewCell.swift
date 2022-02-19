//
//  TransferTableViewCell.swift
//  FinancialTracker
//
//  Created by Boyan Pavlov on 18.02.22.
//

import UIKit

class TransferTableViewCell: UITableViewCell {
    @IBOutlet var transferTitleLabel: UILabel!
    @IBOutlet var transferDate: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
