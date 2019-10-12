//
//  UISegmentedControl+Border.swift
//  HabitPanda
//
//  Created by Tim Nance on 4/30/19.
//  Copyright © 2019 Tim Nance. All rights reserved.
//

import UIKit

extension UISegmentedControl {
    // remove borders while maintaining dividers and highlighting behaviors
    func removeBorders() {
        if let backgroundColor = backgroundColor {
            let backgroundImage = UIImage.imageWithSize(
                size: CGSize.one_one,
                color: backgroundColor
            )
            setBackgroundImage(backgroundImage, for: .normal, barMetrics: .default)
        }

        if let tintColor = tintColor {
            let tintImage = UIImage.imageWithSize(size: CGSize.one_one, color: tintColor)
            let tintImage2 = UIImage.imageWithSize(
                size: CGSize.one_one,
                color: tintColor.withAlphaComponent(0.25)
            )
            setBackgroundImage(tintImage, for: .selected, barMetrics: .default)
            setBackgroundImage(tintImage, for: [.highlighted, .selected], barMetrics: .default)
            setBackgroundImage(tintImage2, for: .highlighted, barMetrics: .default)
            setDividerImage(
                tintImage,
                forLeftSegmentState: .normal,
                rightSegmentState: .normal,
                barMetrics: .default
            )
        }

        if #available(iOS 13, *) {
            layer.masksToBounds = false

            let borderView = UIView()
            borderView.layer.borderWidth = 0
            borderView.isUserInteractionEnabled = false
            borderView.translatesAutoresizingMaskIntoConstraints = false

            addSubview(borderView)

            NSLayoutConstraint(item: borderView, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 0).isActive = true
            NSLayoutConstraint(item: borderView, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0).isActive = true
            NSLayoutConstraint(item: borderView, attribute: .width, relatedBy: .equal, toItem: self, attribute: .width, multiplier: 1, constant: 0).isActive = true
            NSLayoutConstraint(item: borderView, attribute: .height, relatedBy: .equal, toItem: self, attribute: .height, multiplier: 1, constant: 0).isActive = true
        }
    }
}

extension CGSize {
    static var one_one: CGSize{
        return CGSize(width: 1.0, height: 1.0)
    }
}

extension UIImage {
    static func imageWithSize(size: CGSize, color: UIColor = UIColor.white) -> UIImage? {
        var image: UIImage? = nil
        UIGraphicsBeginImageContext(size)
        if let context = UIGraphicsGetCurrentContext() {
            context.setFillColor(color.cgColor)
            context.addRect(CGRect(origin: CGPoint.zero, size: size));
            context.drawPath(using: .fill)
            image = UIGraphicsGetImageFromCurrentImageContext();
        }
        UIGraphicsEndImageContext()
        return image
    }
}
