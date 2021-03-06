//
//  LeftAlignedFlowLayout.m
//
//  Created by qingbin on 2020/9/4.
//  Copyright © 2020 qingbin. All rights reserved.
//

#import "LeftAlignedFlowLayout.h"

@interface UICollectionViewLayoutAttributes (LeftAligned)

- (void)leftAlignFrameWithSectionInset:(UIEdgeInsets)sectionInset;

@end

@implementation UICollectionViewLayoutAttributes (LeftAligned)

- (void)leftAlignFrameWithSectionInset:(UIEdgeInsets)sectionInset
{
    CGRect frame = self.frame;
    frame.origin.x = sectionInset.left;
    self.frame = frame;
}

@end

#pragma mark -

@interface LeftAlignedFlowLayout()
@property(nonatomic, strong) NSMutableDictionary* itemAttributes;
@end

@implementation LeftAlignedFlowLayout

#pragma mark - UICollectionViewLayout

- (NSString*)keyForIndexPath:(NSIndexPath *)indexPath
{
	return [NSString stringWithFormat:@"%@:%@", @(indexPath.item), @(indexPath.section)];
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    NSArray *originalAttributes = [super layoutAttributesForElementsInRect:rect];
    NSMutableArray *updatedAttributes = [NSMutableArray arrayWithArray:originalAttributes];
    for (UICollectionViewLayoutAttributes *attributes in originalAttributes)
	{
        if (!attributes.representedElementKind)
		{
            NSUInteger index = [updatedAttributes indexOfObject:attributes];
            updatedAttributes[index] = [self layoutAttributesForItemAtIndexPath:attributes.indexPath];
        }
    }

    return updatedAttributes;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
	UICollectionViewLayoutAttributes *cacheAttribute = self.itemAttributes[[self keyForIndexPath:indexPath]];
    if (cacheAttribute)
	{
		UICollectionViewLayoutAttributes* currentItemAttributes = [[super layoutAttributesForItemAtIndexPath:indexPath] copy];

		CGRect frame = currentItemAttributes.frame;
		frame.origin.x = cacheAttribute.frame.origin.x;
		currentItemAttributes.frame = frame;

		[self.itemAttributes setValue:currentItemAttributes forKey:[self keyForIndexPath:indexPath]];

		return currentItemAttributes;
	}

    UICollectionViewLayoutAttributes* currentItemAttributes = [[super layoutAttributesForItemAtIndexPath:indexPath] copy];
    UIEdgeInsets sectionInset = [self evaluatedSectionInsetForItemAtIndex:indexPath.section];

    BOOL isFirstItemInSection = indexPath.item == 0;
    CGFloat layoutWidth = CGRectGetWidth(self.collectionView.frame) - sectionInset.left - sectionInset.right;

    if (isFirstItemInSection)
	{
        [currentItemAttributes leftAlignFrameWithSectionInset:sectionInset];
		[self.itemAttributes setValue:currentItemAttributes forKey:[self keyForIndexPath:indexPath]];
        return currentItemAttributes;
    }

    NSIndexPath* previousIndexPath = [NSIndexPath indexPathForItem:indexPath.item-1 inSection:indexPath.section];

	UICollectionViewLayoutAttributes* previousAttributes = self.itemAttributes[[self keyForIndexPath:previousIndexPath]];
	if(!previousAttributes)
	{
		previousAttributes = [self layoutAttributesForItemAtIndexPath:previousIndexPath];
	}

    CGRect previousFrame = previousAttributes.frame;
    CGFloat previousFrameRightPoint = previousFrame.origin.x + previousFrame.size.width;
    CGRect currentFrame = currentItemAttributes.frame;
    CGRect strecthedCurrentFrame = CGRectMake(sectionInset.left,
                                              currentFrame.origin.y,
                                              layoutWidth,
                                              currentFrame.size.height);
    // if the current frame, once left aligned to the left and stretched to the full collection view
    // widht intersects the previous frame then they are on the same line
    BOOL isFirstItemInRow = !CGRectIntersectsRect(previousFrame, strecthedCurrentFrame);

    if (isFirstItemInRow)
	{
        // make sure the first item on a line is left aligned
        [currentItemAttributes leftAlignFrameWithSectionInset:sectionInset];
		[self.itemAttributes setValue:currentItemAttributes forKey:[self keyForIndexPath:indexPath]];
        return currentItemAttributes;
    }

    CGRect frame = currentItemAttributes.frame;
    frame.origin.x = previousFrameRightPoint + [self evaluatedMinimumInteritemSpacingForSectionAtIndex:indexPath.section];
    currentItemAttributes.frame = frame;

	[self.itemAttributes setValue:currentItemAttributes forKey:[self keyForIndexPath:indexPath]];

    return currentItemAttributes;
}

- (CGFloat)evaluatedMinimumInteritemSpacingForSectionAtIndex:(NSInteger)sectionIndex
{
    if ([self.collectionView.delegate respondsToSelector:@selector(collectionView:layout:minimumInteritemSpacingForSectionAtIndex:)]) {
        id<UICollectionViewLeftAlignedFlowLayout> delegate = (id<UICollectionViewLeftAlignedFlowLayout>)self.collectionView.delegate;

        return [delegate collectionView:self.collectionView layout:self minimumInteritemSpacingForSectionAtIndex:sectionIndex];
    } else {
        return self.minimumInteritemSpacing;
    }
}

- (UIEdgeInsets)evaluatedSectionInsetForItemAtIndex:(NSInteger)index
{
    if ([self.collectionView.delegate respondsToSelector:@selector(collectionView:layout:insetForSectionAtIndex:)]) {
        id<UICollectionViewLeftAlignedFlowLayout> delegate = (id<UICollectionViewLeftAlignedFlowLayout>)self.collectionView.delegate;

        return [delegate collectionView:self.collectionView layout:self insetForSectionAtIndex:index];
    } else {
        return self.sectionInset;
    }
}

- (void)invalidateCache
{
	[self.itemAttributes removeAllObjects];
	self.itemAttributes = nil;
}

- (NSMutableDictionary *)itemAttributes
{
	if(!_itemAttributes)
	{
		_itemAttributes = [NSMutableDictionary dictionary];
	}

	return _itemAttributes;
}

@end
