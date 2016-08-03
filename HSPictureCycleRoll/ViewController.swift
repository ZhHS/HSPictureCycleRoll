//
//  ViewController.swift
//  HSPictureCycleRoll
//
//  Created by ZhangHS on 16/8/3.
//  Copyright © 2016年 ZhangHS. All rights reserved.
//

import UIKit

class ViewController: UIViewController {



    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        var ary = [UIImage]()
        (0...4).forEach {
            ary.append(UIImage(named: "c_item\($0)")!)
        }

        let imageRollView = ImageScrollView(frame: CGRect(x: 0, y: 0, width: CGRectGetWidth(self.view.bounds), height: 200),
                                            isAutoRoll: true,
                                            rollDirection: .Right,
                                            timeInt: 4,
                                            images: ary) { (page) in
                                                print("第\(page)页")
        }
        self.view.addSubview(imageRollView)

    }

}

