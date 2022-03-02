//
//  ViewController.swift
//  OwnPainting
//
//  Created by Thang Lai on 23/02/2022.
//

import UIKit

class ViewController: UIViewController {

    
    @IBOutlet weak var undoButton: UIButton!
    @IBOutlet weak var redoButton: UIButton!
    @IBOutlet weak var paintView: PaintView!
    
    internal var undoCount: Int = 0 {
        didSet {
            if undoCount == 0 {
                undoButton.isEnabled = false
                undoButton.tintColor = UIColor(white: 0.5, alpha: 1)
            } else {
                undoButton.isEnabled = true
                undoButton.tintColor = UIColor(white: 0, alpha: 1)
            }
        }
    }
    internal var redoCount: Int = 0 {
        didSet {
            if redoCount == 0 {
                redoButton.isEnabled = false
                redoButton.tintColor = UIColor(white: 0.5, alpha: 1)
            } else {
                redoButton.isEnabled = true
                redoButton.tintColor = UIColor(white: 0, alpha: 1)
            }
        }
    }
    
    private lazy var textManagementView: PaintTextManagementView = {
        let view = PaintTextManagementView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(textManagementView)
        paintView.delegate = self
        undoCount = 0
        redoCount = 0
        
        
    }
    

    @IBAction func undoSelection(_ sender: Any) {
        paintView.undo()
    }
    
    @IBAction func redoSelection(_ sender: Any) {
        paintView.redo()
    }
    
    @IBAction func didSelectFreeHandMode(_ sender: Any) {
        paintView.paintType = .freehand
    }
    
    @IBAction func didSelectOvalMode(_ sender: Any) {
        paintView.paintType = .oval
    }
    @IBAction func didSelecTextMode(_ sender: Any) {
        paintView.paintType = .text
        paintView.textManagementView = textManagementView
    }
    
    @IBAction func selectionMode(_ sender: Any) {
        paintView.paintType = .default
        
    }
    @IBAction func removeLayer(_ sender: Any) {
        paintView.removeSelectLayers()
    }
    
}


extension ViewController: PaintViewDelegate {
    
    private func showPaintLayerTip(paintView: PaintView, layers: [PaintLayer]) {
        guard let layer = layers.first else {
            return
        }
        guard let layerFrame: CGRect = layer.path?.boundingBox else {
            return
        }
        let radius = layer.type == .highlighter ? layer.lineWidth / 2 : 0
        let offset = CGRect(x: layerFrame.origin.x - radius, y: layerFrame.origin.y - radius, width: layerFrame.size.width + radius, height: layerFrame.size.height + radius)

        let rect = paintView.convert(offset, to: view)
        let menu = UIMenuController.shared
        menu.arrowDirection = .default
        if layer.type == .text {
            menu.menuItems = [
                UIMenuItem(title: "edit", action: #selector(editTextLayer(_:))),
                UIMenuItem(title: "delete", action: #selector(deleteLayers(_:)))
            ]
        } else {
            menu.menuItems = [
                UIMenuItem(title: "delete", action: #selector(deleteLayers(_:)))
            ]
        }

        menu.showMenu(from: view, rect: rect)

    }
    func paintView(_ paintView: PaintView, didSelectLayers: [PaintLayer]) {
        
    }
    
    func paintView(_ paintView: PaintView, didDeSelectLayers: [PaintLayer]) {
        
    }
    
    func paintView(_ paintView: PaintView, isTouchLayers: [PaintLayer]) {
        
    }
    
    func paintView(_ paintView: PaintView, didChangeUndoStack: [PaintUndoObject]) {
        undoCount = didChangeUndoStack.count
    }
    
    func paintView(_ paintView: PaintView, didChangeRedoStack: [PaintUndoObject]) {
        redoCount = didChangeRedoStack.count
    }
    
    func paintView(_ paintView: PaintView, didChangePainObject: PaintObject) {
        
    }
    
    func paintView(_ paintView: PaintView, willDisplayLoupe layer: PaintLayer, point: CGPoint) {
        
    }
    
    func paintView(_ paintView: PaintView, willMoveLoupe layer: PaintLayer, point: CGPoint) {
        
    }
    
    func paintView(_ paintView: PaintView, didDeDisplayLoupe layer: PaintLayer) {
        
    }
    
    func paintView(_ paintView: PaintView, didEndDrawing layers: [PaintLayer]) {
        
    }
    
    func paintView(_ paintView: PaintView, didEndDrawing layer: PaintLayer, error: PaintView.PaintError) {
        
    }
    
    
}

extension ViewController {
    @objc private func deleteLayers(_ sender: UIMenuItem) {
        paintView.removeSelectLayers()
    }
    
    @objc private func editTextLayer(_ sender: UIMenuItem) {
        paintView.editSelectTextLayer()
    }
}
