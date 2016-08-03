//
//  ImageScrollView.swift
//  PhoenixDriving
//
//  Created by ZhangHS on 16/7/20.
//  Copyright © 2016年 ZhangHS. All rights reserved.
//

import UIKit

/// 自定义一个类，在类中添加一个方法返回对象类型为NSTimer，使用定时器时就用该对象创建，让NSTimer对这个对象进行强引用，而不对视图控制器进行强引用
class WeakTimerObject: NSObject {
    weak var targat: AnyObject?
    var selector: Selector?
    var timer: NSTimer?
    static func scheduledTimerWithTimeInterval(interval: NSTimeInterval,
                                               aTargat: AnyObject,
                                               aSelector: Selector,
                                               userInfo: AnyObject?,
                                               repeats: Bool) -> NSTimer {
        let weakObject      = WeakTimerObject()
        weakObject.targat   = aTargat
        weakObject.selector = aSelector
        weakObject.timer    = NSTimer.scheduledTimerWithTimeInterval(interval,
                                                                  target: weakObject,
                                                                  selector: #selector(fire),
                                                                  userInfo: userInfo,
                                                                  repeats: repeats)
        return weakObject.timer!
    }
    func fire(ti: NSTimer) {
        if let _ = targat {
            targat?.performSelector(selector!, withObject: ti.userInfo)
        } else {
            timer?.invalidate()
        }
    }
}

class ImageScrollView: UIView, UIScrollViewDelegate {

    private var scrollView      = UIScrollView()
    private var pageControl     = UIPageControl()
    private var leftImageView   = UIImageView()
    private var centerImageView = UIImageView()
    private var rightImageView  = UIImageView()
    private var currentPage     = 0
    private var width: CGFloat!
    private var height: CGFloat!
    private var timer: NSTimer?

    /// 滚动方向
    enum RollingDirection : Int {
        case Left
        case Right
    }
    /// 指示器当前页颜色
    var currentPageIndicatorTintColor:UIColor = .whiteColor(){
        willSet{
            pageControl.currentPageIndicatorTintColor = newValue
        }
    }
    /// 指示器颜色
    var pageIndicatorTintColor:UIColor = .whiteColor(){
        willSet{
            pageControl.pageIndicatorTintColor = newValue
        }
    }
    /// 是否自动滚动
    var autoRoll = false {
        willSet {
            if newValue {
                startTimer()
            } else {
                stopTimer()
            }
        }
    }
    /// 滚动方向
    var direction: RollingDirection = .Right {
        willSet {
            stopTimer()
        }
        didSet {
            if autoRoll {
                startTimer()
            }
        }
    }
    /// 间隔时间
    var timeInterval: NSTimeInterval = 3 {
        willSet {
            stopTimer()
        }
        didSet {
            if autoRoll {
                startTimer()
            }
        }
    }
    /// 图片数组
    var imageArray: [UIImage] = [] {
        willSet {
            stopTimer()
            currentPage = 0
            pageControl.numberOfPages = newValue.count
        }
        didSet {
            updateImageData()
            if autoRoll {
                startTimer()
            }
        }
    }

    /// 滚动完成响应事件
    var operate: ((page: Int)->())?

    //构建scrollView和pageControl
    func initializeUserInterface() {
        width                                     = self.bounds.size.width
        height                                    = self.bounds.size.height
        scrollView.frame                          = self.bounds
        scrollView.delegate                       = self
        scrollView.contentSize                    = CGSize(width: width * 3, height: height)
        scrollView.pagingEnabled                  = true
        scrollView.showsHorizontalScrollIndicator = false
        self.addSubview(scrollView)

        pageControl.frame                         = CGRect(x: 0, y: height - 20, width: width, height: 20)
        pageControl.currentPage                   = 0
        self.addSubview(pageControl)

        let imageViews                            = [leftImageView, centerImageView, rightImageView]
        for index in 0...2 {
            imageViews[index].frame = CGRect(x: CGFloat(index) * width, y: 0, width: width, height: height)
            scrollView.addSubview(imageViews[index])
        }
    }

    /**
     自定义构造函数

     - parameter frame:                 frame
     - parameter isAutoRoll:            是否自动滚动
     - parameter rollDirection:         滚动方向
     - parameter timeInt:               滚动时间间隔
     - parameter images:                图片数组
     - parameter scrollCompleteOperate: 滚动完成响应闭包,page为当前页数
     */
    init(frame: CGRect,
         isAutoRoll: Bool?,
         rollDirection: RollingDirection?,
         timeInt: NSTimeInterval?,
         images:[UIImage],
         scrollCompleteOperate:((page: Int)->())?) {
        super.init(frame: frame)
        initializeUserInterface()

        imageArray = images
        pageControl.numberOfPages = imageArray.count
        if let autoR = isAutoRoll {
            autoRoll = autoR
        }
        if let direct = rollDirection {
            direction = direct
        }
        if let timeI = timeInt {
            timeInterval = timeI
        }
        if let completeOperate = scrollCompleteOperate {
            operate = completeOperate
        }
        //初始化
        updateImageData()
        startTimer()
    }

    //重写父类初始化方法
    override init(frame: CGRect) {
        super.init(frame: frame)
        initializeUserInterface()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        fatalError("init(coder:) has not been implemented")

    }

    //启动定时器
    private func startTimer() {
        timer = nil
        //调用自定义对象，让timer对其进行强引用，而不对视图控制器强引用
        timer = WeakTimerObject.scheduledTimerWithTimeInterval(timeInterval, aTargat: self, aSelector: #selector(pageRoll), userInfo: nil, repeats: true)
    }

    //关闭定时器
    private func stopTimer() {
        if let _ = timer?.valid {
            timer?.invalidate()
            timer = nil
        }
    }

    //定时器触发方法
    @objc private func pageRoll() {
        switch direction {
        case .Left:
            scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
        case .Right:
            scrollView.setContentOffset(CGPoint(x: width * 2, y: 0), animated: true)
        }
    }

    //判断向左滑动还是向右滑动
    private func endScrollAnimation(ratio: CGFloat) {
        if ratio < 1 {
            if currentPage == 0 {
                currentPage = imageArray.count - 1
            } else {
                currentPage -= 1
            }
        } else if ratio > 1 {
            if currentPage == imageArray.count - 1 {
                currentPage = 0
            } else {
                currentPage += 1
            }
        }
        updateImageData()
    }

    //核心算法
    private func updateImageData() {
        if currentPage == 0 {
            leftImageView.image   = imageArray.last
            centerImageView.image = imageArray[currentPage]
            rightImageView.image  = imageArray[currentPage + 1]
        } else if currentPage == imageArray.count - 1 {
            leftImageView.image   = imageArray[currentPage - 1]
            centerImageView.image = imageArray[currentPage]
            rightImageView.image  = imageArray.first
        } else {
            leftImageView.image   = imageArray[currentPage - 1]
            centerImageView.image = imageArray[currentPage]
            rightImageView.image  = imageArray[currentPage + 1]
        }
        if let completeOperate = operate {
            completeOperate(page: currentPage)
        }
        pageControl.currentPage = currentPage
        scrollView.setContentOffset(CGPoint(x: width, y: 0), animated: false)
    }

    //MARK:-scrollViewDelegate
    //手动滑动停止调用
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        endScrollAnimation(scrollView.contentOffset.x / width)
    }
    //自动滑动停止调用
    func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView) {
        endScrollAnimation(scrollView.contentOffset.x / width)
    }

    deinit {
        stopTimer()
        print("停止定时器")
    }
}

