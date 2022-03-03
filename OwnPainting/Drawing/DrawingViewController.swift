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
        
//        let string = JSONString.stringEllipse
//        let dataJson = string.data(using: .utf8)!
//
//        do {
//            if let b = try? JSONDecoder().decode(DrawingObject.self, from: dataJson) {
//                paintView.drawingObjects = b
//            }
//
//        } catch let error as NSError {
//            print(error)
//        }
        SampleJson.readJsonDrawing { [weak self] drawing in
            self?.paintView.drawingObjects = drawing
        }
//
        applyUndoViewState()
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
        paintView.textManagementView = textManagementView
        setHighlightColorButton(sender: sender)
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
        paintView.save(layer_id: "", completion: nil)
    }
    
    @IBAction func moveHandle(_ sender: UIButton) {
        setHighlightColorButton(sender: sender)
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
        if sender == moveButton {
            mainScrollView.isScrollEnabled = true
        }else {
            mainScrollView.isScrollEnabled = false
        }
    }
    
}


extension DrawingViewController: PaintViewDelegate {
    
   
    func paintView(_ paintView: PaintView, didSelectLayers: [PaintLayer]) {
        print(didSelectLayers)
        setHighlightColorButton(sender: deleteButton)
        showSelectedShape = true
    }
    
    func paintView(_ paintView: PaintView, didDeSelectLayers: [PaintLayer]) {
        print(didDeSelectLayers)
        showSelectedShape = false
    }
    
    func paintView(_ paintView: PaintView, isTouchLayers: [PaintLayer]) {
        print(isTouchLayers)
    }
    
    func paintView(_ paintView: PaintView, didChangeUndoStack: [PaintUndoObject]) {
        undoCount = didChangeUndoStack.count
    }
    
    func paintView(_ paintView: PaintView, didChangeRedoStack: [PaintUndoObject]) {
        redoCount = didChangeRedoStack.count
    }
    
    func paintView(_ paintView: PaintView, didChangePainObject: PaintObject) {
        print(didChangePainObject)
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

extension DrawingViewController {
    @objc private func deleteLayers(_ sender: UIMenuItem) {
        paintView.removeSelectLayers()
    }
    
    @objc private func editTextLayer(_ sender: UIMenuItem) {
        paintView.editSelectTextLayer()
    }
}
