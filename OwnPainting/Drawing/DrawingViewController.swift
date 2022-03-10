//
//  ViewController.swift
//  OwnPainting
//
//  Created by Thang Lai on 23/02/2022.
//

import UIKit

class DrawingViewController: UIViewController {
    
    @IBOutlet weak var viewContent: UIView!
    @IBOutlet weak var mainView: UIView!
    @IBOutlet weak var viewUp: UIView!
    @IBOutlet weak var viewHeader: UIView!
    @IBOutlet weak var viewFooter: UIView!
    @IBOutlet weak var mainScrollView: UIScrollView!
    @IBOutlet weak var undoButton: UIButton!
    @IBOutlet weak var redoButton: UIButton!
    @IBOutlet weak var selectionButton: UIButton!
    @IBOutlet weak var penButton: UIButton!
    @IBOutlet weak var ellipseButton: UIButton!
    @IBOutlet weak var textButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var moveButton: UIButton!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var imageUndo: UIImageView!
    @IBOutlet weak var imageRedo: UIImageView!
    @IBOutlet weak var imageDelete: UIImageView!
    @IBOutlet weak var paintView: PaintView!
    
    var delegate: CustomDrawingDelegate!
    var drawing: Drawing!
    var viewModel = DrawingViewModel()
    lazy var toolButtons: [UIButton] = {
        return  [
            selectionButton,
            penButton,
            ellipseButton,
            textButton,
            moveButton
        ]
    }()
    
    var showSelectedShape: Bool = false {
        didSet {
            applyUndoViewState()
        }
    }
    
    
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
        applyUndoViewState()
        setHighlightColorButton(sender: moveButton)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        configureLayoutDrawing()
        
    }
    func configureLayoutDrawing(){
        let size = paintView.frame.size
        if let sizeDrawing = self.drawing?.size as? CGSize {
            viewModel.delta = CGSize(width: size.width/sizeDrawing.width, height: size.height/sizeDrawing.height)
            let newDrawing = self.drawing.copy()
            let drawing = newDrawing.toResize(with: viewModel.delta)
            self.paintView.drawingObjects = drawing
            
        }
    }
    
    @IBAction func undoSelection(_ sender: UIButton) {
        paintView.undo()
        setHighlightColorButton(sender: sender)
    }
    
    @IBAction func redoSelection(_ sender: UIButton) {
        paintView.redo()
        setHighlightColorButton(sender: sender)
    }
    
    @IBAction func didSelectFreeHandMode(_ sender: UIButton) {
        paintView.paintType = .freehand
        setHighlightColorButton(sender: sender)
    }
    
    @IBAction func didSelectOvalMode(_ sender: UIButton) {
        paintView.paintType = .oval
        setHighlightColorButton(sender: sender)
    }
    @IBAction func didSelecTextMode(_ sender: UIButton) {
        paintView.paintType = .text
        textManagementView.widthScrollView = mainScrollView.contentSize.width
        paintView.textManagementView = textManagementView
        setHighlightColorButton(sender: sender)
        
//        let menu = UIMenuController.shared
//        menu.arrowDirection = .default
//        menu.menuItems = [
//            UIMenuItem(title: "edit", action: #selector(editTextLayer(_:))),
//        ]
//
////        menu.setTargetRect(rect, in: view)
//
//        // Animate the menu onto view
////        menu.setMenuVisible(true, animated: true)
//
//        if #available(iOS 13.0, *) {
//            menu.hideMenu()
//            menu.showMenu(from: view, rect: CGRect(x: 50, y: 50, width: 100, height: 100))
//        } else {
//            // Fallback on earlier versions
//        }
    }
    
    @IBAction func selectionMode(_ sender: UIButton) {
        paintView.paintType = .default
        setHighlightColorButton(sender: sender)
        
    }
    @IBAction func removeLayer(_ sender: UIButton) {
        paintView.removeSelectLayers()
        setHighlightColorButton(sender: sender)
    }
    @IBAction func saveDrawing(_ sender: UIButton) {
        paintView.cancelSelectLayers()
        paintView.save {[weak self] drawing in
            self?.delegate.didDrawingDone(drawing: drawing)
            self?.dismiss(animated: true, completion: nil)
        }
        
    }
    
    @IBAction func moveHandle(_ sender: UIButton) {
        setHighlightColorButton(sender: sender)
    }
    
    @IBAction func editText(_ sender: Any) {
        if paintView.textManagementView == nil {
            paintView.textManagementView = textManagementView
            textManagementView.widthScrollView = mainScrollView.contentSize.width
        }
        //
        paintView.editSelectTextLayer()
    }
    @IBAction func back(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    // update state of buttons on footer
    public func applyUndoViewState() {
        undoButton.isEnabled = undoCount > 0
        redoButton.isEnabled = redoCount > 0
        for button in [undoButton, redoButton] {
            button?.alpha = button!.isEnabled ? 1 : 0.5
        }
        imageUndo.tintColor = undoCount > 0 ? .white : .gray
        imageRedo.tintColor = redoCount > 0 ? .white : .gray
        
        imageDelete.tintColor = showSelectedShape ? .white : .gray
        deleteButton.isEnabled = showSelectedShape
        
    }
    
    // set highlight when press any button on footer
    func setHighlightColorButton(sender: UIButton){
        for item in toolButtons {
            let viewButton = item.superview
            if let imageButton = viewButton?.subviews.first(where: {$0 is UIImageView}) as? UIImageView {
                if item == sender {
                    imageButton.tintColor = .green
                    viewButton?.backgroundColor = .white
                }else {
                    imageButton.tintColor = .white
                    viewButton?.backgroundColor = .clear
                }
            }
        }
        if sender == moveButton || paintView.paintType == .default {
            mainScrollView.isScrollEnabled = true
        }else {
            mainScrollView.isScrollEnabled = false
        }
    }
    
}


extension DrawingViewController: PaintViewDelegate {
    
    
    func paintView(_ paintView: PaintView, didSelectLayers: [PaintLayer]) {
        //        if didSelectLayers.first?.type == .text {
        ////            paintView.paintType = .text
        //            paintView.textManagementView = textManagementView
        //            textManagementView.widthScrollView = mainScrollView.contentSize.width
        //            paintView.editSelectTextLayer()
        //        }
        setHighlightColorButton(sender: deleteButton)
        showSelectedShape = true
        applyUndoViewState()
        mainScrollView.isScrollEnabled = false
        showPaintLayerTip(paintView: paintView, layers: didSelectLayers)

    }
    
    func paintView(_ paintView: PaintView, didDeSelectLayers: [PaintLayer]) {
        showSelectedShape = false
        applyUndoViewState()
        mainScrollView.isScrollEnabled = true
    }
    
    func paintView(_ paintView: PaintView, isTouchLayers: [PaintLayer]) {
        print(isTouchLayers)
        applyUndoViewState()
        showPaintLayerTip(paintView: paintView, layers: isTouchLayers)

    }
    
    func paintView(_ paintView: PaintView, didChangeUndoStack: [PaintUndoObject]) {
        undoCount = didChangeUndoStack.count
        applyUndoViewState()
    }
    
    func paintView(_ paintView: PaintView, didChangeRedoStack: [PaintUndoObject]) {
        redoCount = didChangeRedoStack.count
        applyUndoViewState()
    }
    
    func paintView(_ paintView: PaintView, didChangePainObject: PaintObject) {
        print(didChangePainObject)
        applyUndoViewState()
    }
    
    func paintView(_ paintView: PaintView, willDisplayLoupe layer: PaintLayer, point: CGPoint) {
        applyUndoViewState()
    }
    
    func paintView(_ paintView: PaintView, willMoveLoupe layer: PaintLayer, point: CGPoint) {
        applyUndoViewState()
    }
    
    func paintView(_ paintView: PaintView, didDeDisplayLoupe layer: PaintLayer) {
        applyUndoViewState()
    }
    
    func paintView(_ paintView: PaintView, didEndDrawing layers: [PaintLayer]) {
        print(layers)
        applyUndoViewState()
        
    }
    
    func paintView(_ paintView: PaintView, didEndDrawing layer: PaintLayer, error: PaintView.PaintError) {
        print(layer)
        applyUndoViewState()
    }
    func didEnterEditTextMode(_ paintView: PaintView) {
        if paintView.textManagementView == nil {
            paintView.textManagementView = textManagementView
            textManagementView.widthScrollView = mainScrollView.contentSize.width
        }
        self.paintView.editSelectTextLayer()
    }
    
    
    
}

extension DrawingViewController {
    @objc private func deleteLayers(_ sender: UIMenuItem) {
        paintView.removeSelectLayers()
    }
    
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
            ]
        }
        
//        menu.setTargetRect(rect, in: view)
        
        // Animate the menu onto view
//        menu.setMenuVisible(true, animated: true)
        
        if #available(iOS 13.0, *) {
            menu.hideMenu()
            menu.showMenu(from: view, rect: rect)
        } else {
            // Fallback on earlier versions
        }

//        cell?.scrollView.isScrollEnabled = false
    }
    
    @objc private func editTextLayer(_ sender: UIMenuItem) {
        paintView.editSelectTextLayer()
    }
}

protocol CustomDrawingDelegate{
    func didDrawingDone(drawing: Drawing?)
}
