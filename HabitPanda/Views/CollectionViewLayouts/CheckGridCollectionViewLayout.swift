//
//  CheckGridCollectionViewLayout.swift
//  HabitPanda
//
//  Created by Tim Nance on 5/26/19.
//  Copyright © 2019 Tim Nance. All rights reserved.
//

import UIKit

class CheckGridCollectionViewLayout: UICollectionViewLayout {
    var itemAttributes = [[UICollectionViewLayoutAttributes]]()
    var contentSize: CGSize = .zero

    lazy var numberOfColumns: Int = {
        return collectionView?.numberOfItems(inSection: 0) ?? 0
    }()

    var rowIndexBoundaryCache: (Int, Int)? = nil
    var colIndexBoundaryCache: (Int, Int)? = nil

    override func prepare() {
        guard let collectionView = collectionView else {
            return
        }
        if collectionView.numberOfSections == 0 || numberOfColumns == 0 {
            return
        }

        if itemAttributes.count != collectionView.numberOfSections {
            // first pass, generate initial values
            generateItemAttributes(collectionView: collectionView)
            return
        }

        // update pass, only need to update frozen rows/cols

        let colIndexBoundaries = getColIndexBoundaries(bypassCache: true)
        let rowIndexBoundaries = getRowIndexBoundaries(bypassCache: true)

        let newX = min(
            max(0, collectionView.contentOffset.x),
            contentSize.width - collectionView.frame.width
        )
        // update row title cells
        for rowIndex in (rowIndexBoundaries.0)...(rowIndexBoundaries.1) {
            itemAttributes[rowIndex][0].frame.origin.x = newX
        }

        let newY = max(
            collectionView.contentOffset.y,
            0
        )
        // update header cells
        for colIndex in (colIndexBoundaries.0)...(colIndexBoundaries.1) {
            itemAttributes[0][colIndex].frame.origin.y = newY
        }
    }

    override var collectionViewContentSize: CGSize {
        return contentSize
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return itemAttributes[indexPath.section][indexPath.row]
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let colIndexBoundaries = getColIndexBoundaries()
        let rowIndexBoundaries = getRowIndexBoundaries()

        var attributesArray = [UICollectionViewLayoutAttributes]()

        for rowIndex in (rowIndexBoundaries.0)...(rowIndexBoundaries.1) {
            attributesArray.append(itemAttributes[rowIndex][0])
            for colIndex in (colIndexBoundaries.0)...(colIndexBoundaries.1) {
                attributesArray.append(itemAttributes[rowIndex][colIndex])
            }
        }
        for colIndex in (colIndexBoundaries.0)...(colIndexBoundaries.1) {
            attributesArray.append(itemAttributes[0][colIndex])
        }

        return attributesArray
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
}


// MARK: - Boundary index methods
extension CheckGridCollectionViewLayout {
    // TODO: make below methods more DRY without sacrificing performance
    func getRowIndexBoundaries(bypassCache: Bool = false) -> (Int, Int) {
        guard let collectionView = collectionView else {
            return (0, 0)
        }
        if !bypassCache && rowIndexBoundaryCache != nil {
            return rowIndexBoundaryCache!
        }

        let minY = collectionView.contentOffset.y
        let maxY = collectionView.contentOffset.y + collectionView.frame.height
        var leftIndex = 1
        var rightIndex = collectionView.numberOfSections - 1

        while leftIndex < rightIndex {
            let midIndex = (leftIndex + rightIndex) / 2
            let y = itemAttributes[midIndex][0].frame.origin.y
            if y < minY {
                // target is to the right
                leftIndex = midIndex + 1
            } else {
                rightIndex = midIndex
            }
        }
        let minIndex = max(leftIndex - 1, 1)

        leftIndex = minIndex
        rightIndex = collectionView.numberOfSections - 1
        while leftIndex < rightIndex {
            let midIndex = (leftIndex + rightIndex) / 2
            let y = itemAttributes[midIndex][0].frame.origin.y
            if y < maxY {
                // target is to the right
                leftIndex = midIndex + 1
            } else {
                rightIndex = midIndex
            }
        }
        let maxIndex = leftIndex

        rowIndexBoundaryCache = (minIndex, maxIndex)

        return rowIndexBoundaryCache!
    }


    func getColIndexBoundaries(bypassCache: Bool = false) -> (Int, Int) {
        guard let collectionView = collectionView else {
            return (0, 0)
        }
        if !bypassCache && colIndexBoundaryCache != nil {
            return colIndexBoundaryCache!
        }

        let minX = collectionView.contentOffset.x
        let maxX = collectionView.contentOffset.x + collectionView.frame.width
        var leftIndex = 1
        var rightIndex = numberOfColumns - 1

        while leftIndex < rightIndex {
            let midIndex = (leftIndex + rightIndex) / 2
            let x = itemAttributes[0][midIndex].frame.origin.x
            if x < minX {
                // target is to the right
                leftIndex = midIndex + 1
            } else {
                rightIndex = midIndex
            }
        }
        let minIndex = max(leftIndex - 1, 1)

        leftIndex = minIndex
        rightIndex = numberOfColumns - 1
        while leftIndex < rightIndex {
            let midIndex = (leftIndex + rightIndex) / 2
            let x = itemAttributes[0][midIndex].frame.origin.x
            if x < maxX {
                // target is to the right
                leftIndex = midIndex + 1
            } else {
                rightIndex = midIndex
            }
        }
        let maxIndex = leftIndex

        colIndexBoundaryCache = (minIndex, maxIndex)

        return colIndexBoundaryCache!
    }

}


// MARK: - Helpers
extension CheckGridCollectionViewLayout {
    func getItemSize(forRow rowIndex: Int, forCol colIndex: Int) -> CGSize {
        guard let collectionView = collectionView else {
            return .zero
        }

        var width: CGFloat
        var height: CGFloat

        if colIndex == 0 {
            width = collectionView.frame.width
            height = CheckGridRowTitleCell.height
        } else if rowIndex == 0 {
            width = CheckGridHeaderCell.width
            height = CheckGridHeaderCell.height
        } else {
            width = CheckGridContentCell.width
            height = CheckGridContentCell.height
        }
        return CGSize(width: width, height: height)
    }

    func generateItemAttributes(collectionView: UICollectionView) {
        var column = 0
        var xOffset: CGFloat = 0
        var yOffset: CGFloat = 0
        var contentWidth: CGFloat = 0

        itemAttributes = []

        for rowIndex in 0..<collectionView.numberOfSections {
            var sectionAttributes: [UICollectionViewLayoutAttributes] = []

            for colIndex in 0..<numberOfColumns {
                let itemSize = getItemSize(forRow: rowIndex, forCol: colIndex)
                let indexPath = IndexPath(item: colIndex, section: rowIndex)
                let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)

                attributes.frame = CGRect(
                    x: xOffset,
                    y: yOffset,
                    width: itemSize.width,
                    height: itemSize.height
                    ).integral

                if rowIndex == 0 {
                    // First cell should be on top
                    attributes.zIndex = 1024
                } else if colIndex == 0 {
                    // First row/column should be above other cells
                    attributes.zIndex = 1023
                }

                if rowIndex == 0 {
                    attributes.frame.origin.y = collectionView.contentOffset.y
                }
                if colIndex == 0 {
                    attributes.frame.origin.x =
                        collectionView.contentOffset.x +
                        collectionView.frame.width -
                        attributes.frame.width
                }

                sectionAttributes.append(attributes)

                if colIndex > 0 {
                    xOffset += attributes.frame.width
                }
                column += 1

                if colIndex == numberOfColumns - 1 {
                    if xOffset > contentWidth {
                        contentWidth = xOffset
                    }

                    column = 0
                    xOffset = 0
                    yOffset += attributes.frame.height
                }
            }

            itemAttributes.append(sectionAttributes)
        }

        if let attributes = itemAttributes.last?.last {
            contentSize = CGSize(width: contentWidth, height: attributes.frame.maxY)
        }
    }
}
