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

   override func viewDidLoad() {
      super.viewDidLoad()

      if #available(iOS 13, *) {
			   self.view.backgroundColor = UIColor.systemBackground
      } else {
			   self.view.backgroundColor = UIColor.white
		  }
   }
}

