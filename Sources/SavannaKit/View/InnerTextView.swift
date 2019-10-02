//
//  InnerTextView.swift
//  SavannaKit
//
//  Created by Louis D'hauwe on 09/07/2017.
//  Copyright © 2017 Silver Fox. All rights reserved.
//

import Foundation
import CoreGraphics
import AppKit
import Carbon.HIToolbox

protocol InnerTextViewDelegate: class {
	func didUpdateCursorFloatingState()
}

final class InnerTextView: NSTextView {

	weak var innerDelegate: InnerTextViewDelegate?
	
	var theme: SyntaxColorTheme?
	
	var cachedParagraphs: [Paragraph]?
    
    override func menu(for event: NSEvent) -> NSMenu? {
        let menu = super.menu(for: event)
        
        let bannedItems = [
            "changeLayoutOrientation:",
            "replaceQuotesInSelection:",
            "toggleAutomaticQuoteSubstitution:",
            "orderFrontFontPanel:"
        ]
        
        // This is a mess.
        menu?.items = menu?.items.filter { menuItem in
            return !(menuItem.submenu?.items.contains { item in
                    return bannedItems.contains(item.action?.description ?? "")
                } ?? false)
        } ?? []
        
        return menu
    }
    
	func invalidateCachedParagraphs() {
		cachedParagraphs = nil
	}
    
    // Automatic closing
    
    override func insertBacktab(_ sender: Any?) {
        // TODO: Handle this
    }
    
    override func insertText(_ insertString: Any) {
        
        switch insertString as? String {
        case "[":
            insertAfter(insertString, "]")
        case "{":
            insertAfter(insertString, "}")
        case "(":
            insertAfter(insertString, ")")
        case "\"":
            insertQuotes(insertString, "\"")
        case "'":
            insertQuotes(insertString, "'")
        default:
            self.insertText(insertString, replacementRange: self.selectedRange)
        }
        
    }
    
    private func insertAfter(_ before: Any, _ after: String) {
        
        self.insertText(before, replacementRange: self.selectedRange)
        self.insertText(after, replacementRange: self.selectedRange)
        self.moveBackward(self)
    }
    
    private func insertQuotes(_ before: Any, _ after: String) {
        
        guard self.selectedRange.length > 0 else {
            insertAfter(before, after)
            return
        }
        
        var originalRange = self.selectedRange
        var targetRange = originalRange
        targetRange.length = 0
        
        self.insertText(before, replacementRange: targetRange)
        
        targetRange.location = originalRange.upperBound + 1
        
        self.insertText(after, replacementRange: targetRange)
        
        originalRange.location += 1
        
        self.setSelectedRange(originalRange)
    }
	
    override func insertTab(_ sender: Any?) {
        
        self.undoManager?.beginUndoGrouping()
        
        var range = self.selectedRange
        
        let spaces = String(repeating: " ", count: theme?.tabWidth ?? 4)
        
        self.insertText(spaces, replacementRange: range)
        
        self.undoManager?.endUndoGrouping()
        
        // TODO: Add selection tabbing support
    }
    
    // Overscroll
    // Inspired by https://christiantietze.de
    
    public func scrollViewDidResize(_ scrollView: NSScrollView) {
        let offset = scrollView.bounds.height / 4
        textContainerInset = NSSize(width: 0, height: offset)
        overscrollY = offset
    }

    var overscrollY: CGFloat = 0

    override var textContainerOrigin: NSPoint {
        return super
            .textContainerOrigin
            .applying(.init(translationX: 0, y: -overscrollY))
    }
}
