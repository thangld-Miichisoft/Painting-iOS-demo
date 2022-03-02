//
//  ObjcUtility.m
//  Photoruction
//
//  Created by Yuta Fujita on 2016/11/21.
//  Copyright © 2016年 jp.co.concores. All rights reserved.
//

#import "ObjcUtility.h"

@implementation ObjcUtility

//http://qiita.com/takabosoft/items/c6f88a8e7df2815206e0
//Swift3+iOS8ではCIContextのイニシャライザでクラッシュするバグがあるもよう
+ (CIContext *)cicontextWithOptions:(NSDictionary<NSString *, id> *)options {
    return [CIContext contextWithOptions:options];
}

- (UIBezierPath *)bezierPath:(NSAttributedString *)attrString rect:(CGRect)rect {
    
    if (attrString.length == 0) {
        return nil;
    }
    
    CGMutablePathRef letters = CGPathCreateMutable();
    
//    CGRect bounds = CGRectMake(0, 0, rect.size.width, rect.size.height);
    
//    CGPathRef pathRef = CGPathCreateWithRect(bounds, NULL);
    
    NSDictionary *attributes = [attrString attributesAtIndex:0 longestEffectiveRange:nil inRange:NSMakeRange(0, attrString.length)];
    UIFont *font = (UIFont *)[attributes objectForKey:NSFontAttributeName];
    
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)(attrString));
    
    CGSize size = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, attrString.length), nil, CGSizeMake(rect.size.width, CGFLOAT_MAX), nil);
    CGRect bounds = CGRectMake(0, 0, size.width, size.height);
    CGPathRef pathRef = CGPathCreateWithRect(bounds, NULL);
    
    CTFrameRef frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, attrString.length), pathRef, NULL);
    
    CFArrayRef lines = CTFrameGetLines(frame);
    
    CGPoint *points = malloc(sizeof(CGPoint) * CFArrayGetCount(lines));
    
    NSInteger numLines = CFArrayGetCount(lines);
    
    CTFrameGetLineOrigins(frame, CFRangeMake(0, numLines), points);
    
    // for each LINE
    for (CFIndex lineIndex = 0; lineIndex < numLines; lineIndex++) {
        
        CTLineRef lineRef = CFArrayGetValueAtIndex(lines, lineIndex);
        
        CFRange r = CTLineGetStringRange(lineRef);
        
        NSParagraphStyle *paragraphStyle = [attrString attribute:NSParagraphStyleAttributeName atIndex:r.location effectiveRange:NULL];
        NSTextAlignment alignment = paragraphStyle.alignment;
        
        CGFloat flushFactor = 0.0;  //NSTextAlignmentLeft
        if (alignment == NSTextAlignmentCenter) {
            flushFactor = 0.5;
        } else if (alignment == NSTextAlignmentRight) {
            flushFactor = 1.0;
        }
        
        CGFloat penOffset = CTLineGetPenOffsetForFlush(lineRef, flushFactor, rect.size.width);
        
        // create a new justified line if the alignment is justified
        if (alignment == NSTextAlignmentJustified) {
            lineRef = CTLineCreateJustifiedLine(lineRef, 1.0, rect.size.width);
            penOffset = 0;
        }
        
        CGFloat lineOffset = (numLines - lineIndex - 1) * [font pointSize];
        
        CFArrayRef runArray = CTLineGetGlyphRuns(lineRef);
        
        // for each RUN
        for (CFIndex runIndex = 0; runIndex < CFArrayGetCount(runArray); runIndex++) {
            
            // Get FONT for this run
            CTRunRef run = (CTRunRef)CFArrayGetValueAtIndex(runArray, runIndex);
            CTFontRef runFont = CFDictionaryGetValue(CTRunGetAttributes(run), kCTFontAttributeName);
            
            // for each GLYPH in run
            for (CFIndex runGlyphIndex = 0; runGlyphIndex < CTRunGetGlyphCount(run); runGlyphIndex++) {
                
                // get Glyph & Glyph-data
                CFRange thisGlyphRange = CFRangeMake(runGlyphIndex, 1);
                CGGlyph glyph;
                CGPoint position;
                CTRunGetGlyphs(run, thisGlyphRange, &glyph);
                CTRunGetPositions(run, thisGlyphRange, &position);
                
                position.y += lineOffset;
                position.x += penOffset;
                
                CGPathRef letter = CTFontCreatePathForGlyph(runFont, glyph, NULL);
                CGAffineTransform t = CGAffineTransformMakeTranslation(position.x, position.y);
                
                CGPathAddPath(letters, &t, letter);
                CGPathRelease(letter);
            }
        }
        
        // if the text is justified then release the new justified line we created.
        if (alignment == NSTextAlignmentJustified) {
            CFRelease(lineRef);
        }
    }
    
    free(points);
    
    CGPathRelease(pathRef);
    CFRelease(frame);
    CFRelease(framesetter);
    
    CGAffineTransform transform = CGAffineTransformMakeScale(1, -1);
    transform = CGAffineTransformTranslate(transform, 0, -[font pointSize] * numLines);
    transform = CGAffineTransformTranslate(transform, rect.origin.x, -rect.origin.y);
    CGPathRef finalPath = CGPathCreateCopyByTransformingPath(letters, &transform);
    
    UIBezierPath *path = [UIBezierPath bezierPathWithCGPath: finalPath];
    
    CGPathRelease(letters);
    CGPathRelease(finalPath);
    
    return path;
}

- (UIBezierPath *)singleLineStringBezierPath:(NSString *)string fontSize:(CGFloat)fontSize {
    
    if ([string length] == 0) {
        return nil;
    }
    
    UIFont *font = [UIFont fontWithName:@"IPAexGothic" size:fontSize];
    
    NSMutableDictionary<NSAttributedStringKey, id> *attributes = [[NSMutableDictionary<NSAttributedStringKey, id> alloc] init];
    [attributes setObject:font forKey:NSFontAttributeName];
    NSAttributedString *attrString = [[NSAttributedString alloc] initWithString:string attributes:attributes];
    
    CGMutablePathRef letters = CGPathCreateMutable();
    
    CTLineRef line = CTLineCreateWithAttributedString((__bridge CFAttributedStringRef)attrString);
    
    CFArrayRef runArray = CTLineGetGlyphRuns(line);
    
    for (CFIndex runIndex = 0; runIndex < CFArrayGetCount(runArray); runIndex++) {
        CTRunRef run = (CTRunRef)CFArrayGetValueAtIndex(runArray, runIndex);
        CTFontRef runFont = CFDictionaryGetValue(CTRunGetAttributes(run), kCTFontAttributeName);
        
        for (CFIndex runGlyphIndex = 0; runGlyphIndex < CTRunGetGlyphCount(run); runGlyphIndex++) {
            CFRange thisGlyphRange = CFRangeMake(runGlyphIndex, 1);
            CGGlyph glyph;
            CGPoint position;
            CTRunGetGlyphs(run, thisGlyphRange, &glyph);
            CTRunGetPositions(run, thisGlyphRange, &position);
            
            CGPathRef letter = CTFontCreatePathForGlyph(runFont, glyph, NULL);
            CGAffineTransform t = CGAffineTransformMakeTranslation(position.x, position.y);
            CGPathAddPath(letters, &t, letter);
            CGPathRelease(letter);
        }
    }
    
    CFRelease(line);
    
    CGRect rect = CGPathGetBoundingBox(letters);
    CGPoint center = CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
    
    CGAffineTransform transform = CGAffineTransformMakeScale(1, -1);
    transform = CGAffineTransformTranslate(transform, 0, 0);
    CGPathRef tmpPath = CGPathCreateCopyByTransformingPath(letters, &transform);
    transform = CGAffineTransformMakeTranslation(-center.x, center.y);
    CGPathRef finalPath = CGPathCreateCopyByTransformingPath(tmpPath, &transform);
    UIBezierPath *path = [UIBezierPath bezierPathWithCGPath:finalPath];
    
    CGPathRelease(letters);
    CGPathRelease(tmpPath);
    CGPathRelease(finalPath);
    
    return path;
}

- (UIBezierPath *)bezierPath:(NSAttributedString *)attrString {
    return [self bezierPath:attrString maxSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
}

- (UIBezierPath *)bezierPath:(NSAttributedString *)attrString maxSize:(CGSize)maxSize {
    
    if (attrString.length == 0) {
        return nil;
    }
    NSDictionary *layoutAttributes;
    
    CGMutablePathRef letters = CGPathCreateMutable();
    
    NSDictionary *attributes = [attrString attributesAtIndex:0 longestEffectiveRange:nil inRange:NSMakeRange(0, attrString.length)];
    UIFont *font = (UIFont *)[attributes objectForKey:NSFontAttributeName];
    
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)(attrString));
    
    CGSize size = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, attrString.length), nil, maxSize, nil);
    if (size.width == 0 && size.height == 0) {
        return nil;
    }
    CGRect bounds = CGRectZero;
    if ([attributes objectForKey: NSVerticalGlyphFormAttributeName] == [NSNumber numberWithBool: true]) {
        bounds = CGRectMake(0, 0, size.height, size.width);
        layoutAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                            [NSNumber numberWithInt: kCTFrameProgressionRightToLeft], kCTFrameProgressionAttributeName, nil];
    } else {
        bounds = CGRectMake(0, 0, size.width, size.height);
    }
    CGPathRef pathRef = CGPathCreateWithRect(bounds, NULL);
    
    CTFrameRef frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, attrString.length), pathRef, (__bridge CFDictionaryRef)layoutAttributes);
    
    CFArrayRef lines = CTFrameGetLines(frame);
    
    CGPoint *points = malloc(sizeof(CGPoint) * CFArrayGetCount(lines));
    
    NSInteger numLines = CFArrayGetCount(lines);
    
    CTFrameGetLineOrigins(frame, CFRangeMake(0, numLines), points);
    
    // for each LINE
    for (CFIndex lineIndex = 0; lineIndex < numLines; lineIndex++) {
        
        CTLineRef lineRef = CFArrayGetValueAtIndex(lines, lineIndex);
        
        CFRange r = CTLineGetStringRange(lineRef);
        
        NSParagraphStyle *paragraphStyle = [attrString attribute:NSParagraphStyleAttributeName atIndex:r.location effectiveRange:NULL];
        NSTextAlignment alignment = paragraphStyle.alignment;
        
        CGFloat flushFactor = 0.0;  //NSTextAlignmentLeft
        if (alignment == NSTextAlignmentCenter) {
            flushFactor = 0.5;
        } else if (alignment == NSTextAlignmentRight) {
            flushFactor = 1.0;
        }
        
        CGFloat penOffset = CTLineGetPenOffsetForFlush(lineRef, flushFactor, CGFLOAT_MAX);
        
        // create a new justified line if the alignment is justified
        if (alignment == NSTextAlignmentJustified) {
            lineRef = CTLineCreateJustifiedLine(lineRef, 1.0, CGFLOAT_MAX);
            penOffset = 0;
        }
        
        CGFloat lineOffset = (numLines - lineIndex - 1) * [font pointSize];
        
        CFArrayRef runArray = CTLineGetGlyphRuns(lineRef);
        
        // for each RUN
        for (CFIndex runIndex = 0; runIndex < CFArrayGetCount(runArray); runIndex++) {
            
            // Get FONT for this run
            CTRunRef run = (CTRunRef)CFArrayGetValueAtIndex(runArray, runIndex);
            CTFontRef runFont = CFDictionaryGetValue(CTRunGetAttributes(run), kCTFontAttributeName);
            
            // for each GLYPH in run
            for (CFIndex runGlyphIndex = 0; runGlyphIndex < CTRunGetGlyphCount(run); runGlyphIndex++) {
                
                // get Glyph & Glyph-data
                CFRange thisGlyphRange = CFRangeMake(runGlyphIndex, 1);
                CGGlyph glyph;
                CGPoint position;
                CTRunGetGlyphs(run, thisGlyphRange, &glyph);
                CTRunGetPositions(run, thisGlyphRange, &position);
                
                position.y += lineOffset;
                position.x += penOffset;
                
                CGPathRef letter = CTFontCreatePathForGlyph(runFont, glyph, NULL);
                CGAffineTransform t = CGAffineTransformMakeTranslation(position.x, position.y);
                
                CGPathAddPath(letters, &t, letter);
                CGPathRelease(letter);
            }
        }
        
        // if the text is justified then release the new justified line we created.
        if (alignment == NSTextAlignmentJustified) {
            CFRelease(lineRef);
        }
    }
    
    free(points);
    
    CGPathRelease(pathRef);
    CFRelease(frame);
    CFRelease(framesetter);
    
    CGAffineTransform transform = CGAffineTransformMakeScale(1, -1);
    CGPathRef mPath = CGPathCreateCopyByTransformingPath(letters, &transform);
    UIBezierPath *mBPath = [UIBezierPath bezierPathWithCGPath: mPath];
    transform = CGAffineTransformTranslate(transform, -mBPath.bounds.origin.x, mBPath.bounds.origin.y);
    transform = CGAffineTransformTranslate(transform, -(mBPath.bounds.size.width / 2), 0);
//    CGPathRef mPath1 = CGPathCreateCopyByTransformingPath(letters, &transform);
//    UIBezierPath *mBPath1 = [UIBezierPath bezierPathWithCGPath: mPath1];
//    NSLog(@"%@", NSStringFromCGRect(mBPath.bounds));
//    NSLog(@"%@", NSStringFromCGRect(mBPath1.bounds));
//    if ([attributes objectForKey: NSVerticalGlyphFormAttributeName] != [NSNumber numberWithBool: true]) {
//        transform = CGAffineTransformTranslate(transform, -(mBPath.bounds.size.width / 2), 0);
//    } else {
//        transform = CGAffineTransformTranslate(transform, -(mBPath.bounds.size.width / 2), 0);
//    }
    CGPathRelease(mPath);
    mBPath = nil;
    
    UIBezierPath *path = nil;
    
    if (!isnan(transform.tx) && !isnan(transform.ty)) {
        CGPathRef finalPath = CGPathCreateCopyByTransformingPath(letters, &transform);
        
        path = [UIBezierPath bezierPathWithCGPath: finalPath];
        
        CGPathRelease(finalPath);
    }
    
    CGPathRelease(letters);
    
    return path;
}

@end
