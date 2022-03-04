//
//  ViewController.swift
//  OwnPainting
//
//  Created by Thang Lai on 23/02/2022.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.addBorder(color: .black)
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapImage(gesture:)))
        imageView.addGestureRecognizer(tap)
    }
    
    @objc func tapImage(gesture: UITapGestureRecognizer){
        let drawingViewController = DrawingViewController()
        drawingViewController.modalPresentationStyle = .fullScreen
        drawingViewController.delegate = self
        SampleJson.readJsonDrawing { [weak self] drawing in
            drawingViewController.drawing = drawing
            self?.present(drawingViewController, animated: true) {
                
            }
            
        }
        
    }
    
}
extension ViewController: CustomDrawingDelegate {
    func didDrawingDone(drawing: Drawing?) {
        if let drawing = drawing , let baseImage = imageView.image{
            
            let image = drawing.toImageDrawing(baseImage: baseImage)
            imageView.image = image
        }
    }
    
    
}
