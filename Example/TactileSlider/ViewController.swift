//
//  ViewController.swift
//  TactileSlider
//
//  Created by daprice on 01/22/2019.
//  Copyright (c) 2019 daprice. All rights reserved.
//

import UIKit
import TactileSlider

class ViewController: UIViewController {

	@IBOutlet weak var rightToLeftSlider: TactileSlider!
	@IBOutlet weak var leftToRightSlider: TactileSlider!
	@IBOutlet weak var topToBottomSlider: TactileSlider!
	@IBOutlet weak var bottomToTopSlider: TactileSlider!
	
	override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
		
		rightToLeftSlider.direction = .rightToLeft
		leftToRightSlider.direction = .leftToRight
		topToBottomSlider.direction = .topToBottom
		bottomToTopSlider.direction = .bottomToTop
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

