//
//  DocumentViewController.swift
//  iBoard
//
//  Created by Kigen on 23/06/2018.
//  Copyright © 2018 Kigen. All rights reserved.
//

import UIKit
import PDFKit
import QuartzCore


class DocumentViewController: UIViewController{
    
    var document_path = ""
    var meeting_title = ""
    let base_url = "http://iboard.dev"
    var pdfView: PDFView!
    var points = [CGPoint]()
    var highlightColor : UIColor = UIColor.green
    
    
    
    //MARK:- View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        
        let fileName = document_path.substring(from: 8)
        
        if(!fileExists(fileName: fileName)){
            //File does not exist so save it
            saveLocal()
        }
        
        displayDoc()
        
    }
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK:- Custom code
    func configureUI(){
        pdfView = PDFView()
        pdfView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pdfView)
        
        pdfView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        pdfView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        pdfView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        pdfView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        let panGestureRecognizer  = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(panGesture:)))
        
        //Add UIPanGestureRecognizer - For doing user annotations
        
        pdfView.addGestureRecognizer(panGestureRecognizer)
        
        let redAnnotationButton = UIBarButtonItem(image:UIImage(named: "red_pen"), style:.plain, target: self, action:#selector(changeHighlightColor(sender:)))
        redAnnotationButton.tag = 1000
        redAnnotationButton.tintColor = UIColor.red
        
        let greenAnnotationButton = UIBarButtonItem(image:UIImage(named: "green_pen"), style:.plain, target: self, action:#selector(changeHighlightColor(sender:)))
        greenAnnotationButton.tintColor = UIColor.green
        greenAnnotationButton.tag = 1001
        
        let yellowAnnotationButton =  UIBarButtonItem(image:UIImage(named: "yellow_pen"), style:.plain, target: self, action:#selector(changeHighlightColor(sender:)))
        yellowAnnotationButton.tintColor = UIColor.yellow
        yellowAnnotationButton.tag = 1002
        
        let orangeAnnotationButton =  UIBarButtonItem(image:UIImage(named: "orange_pen"), style:.plain, target: self, action:#selector(changeHighlightColor(sender:)))
        orangeAnnotationButton.tintColor = UIColor.orange
        orangeAnnotationButton.tag = 1003
        
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: #selector(changeHighlightColor(sender:)))
        toolbarItems = [
            greenAnnotationButton,
            spacer,
            orangeAnnotationButton,
            spacer,
            yellowAnnotationButton,
            spacer,
            redAnnotationButton
        ]
        
        //navigationController?.toolbar.tintColor = UIColor.flatBlack
        self.navigationItem.title = meeting_title + " Document"
        navigationController?.setToolbarHidden(false, animated: false)
        
    }
    
    
    func fileExists (fileName : String) -> Bool {
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        let url = NSURL(fileURLWithPath: path)
        var exists : Bool = false
        
        if let pathComponent = url.appendingPathComponent(fileName) {
            let filePath = pathComponent.path
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: filePath) {
                exists = true
            }
        }
        
        return exists
        
    }
    
    
    func saveLocal(){
        Global.showProgressView(view)
        if let remoteDocUrl = URL(string: Global.baseUrl() + "/" + document_path),
            let fileData = try? Data(contentsOf: remoteDocUrl){
            
            let localDocUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last as NSURL?
            
            let filename = document_path.substring(from: 8)
            
            let localFileUrl = localDocUrl?.appendingPathComponent(filename)
            do{
                try fileData.write(to: localFileUrl!, options: Data.WritingOptions.atomicWrite)
            }catch{
                print("Error saving: \(filename)")
            }
        }
        view.dismissProgress()
    }
    
    //Display local Doc
    func displayDoc(){
        let fileName = document_path.substring(from: 8)
        
        let localDocUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last as NSURL?
        
        if let fileUrl = localDocUrl?.appendingPathComponent(fileName){
            if let fileData = try? Data(contentsOf: fileUrl),
                let document = PDFDocument(data: fileData){
                pdfView.document = document
                configurePdfView()
            }
        }
    }
    
    //Configure PDFView
    func configurePdfView(){
        pdfView.delegate = self
        pdfView.autoScales = true
        pdfView.backgroundColor = UIColor.lightGray
        pdfView.displayMode = .singlePageContinuous
        
    }
    
    @objc func handlePanGesture(panGesture: UIPanGestureRecognizer){
        let location = panGesture.location(in: view)
        if panGesture.state == .began{
            //Reset array of locations
            points = [CGPoint]();
        }
        
        if panGesture.state != .ended  {
            //Capture all points traversed
            points.append(location)
        }else if panGesture.state == .ended{
            //Gesture has ended - Draw annotation
            
            if let firstPoint = points.first, let lastPoint = points.last{
                let convertedFirstPoint = pdfView.convert(firstPoint, to: pdfView.page(for: firstPoint, nearest: true)!)
                let convertedLastPoint = pdfView.convert(lastPoint, to: pdfView.page(for: lastPoint, nearest: true)!)
                let x : CGFloat = convertedFirstPoint.x
                let y : CGFloat = convertedFirstPoint.y
                let width = convertedLastPoint.x - convertedFirstPoint.x
                let height = convertedLastPoint.y - convertedFirstPoint.y
                let rect = CGRect(x: x, y: y, width: width, height: height)
                let annotation = PDFAnnotation(bounds:rect , forType: PDFAnnotationSubtype.highlight, withProperties: nil)
                annotation.color = highlightColor
                
                pdfView.page(for: firstPoint, nearest: true)?.addAnnotation(annotation)
                
                pdfView.setNeedsDisplay()
                
                //Path to user directory
                let localDocUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last as NSURL?
                
                let filename = document_path.substring(from: 8)
                
                //File URL
                let localFileUrl = localDocUrl?.appendingPathComponent(filename)
                
                let writen = pdfView.document?.write(to: localFileUrl!)
                
                print("Annotations writen \(String(describing: writen))")
            }
        }
    }
    
    
    
    @objc func changeHighlightColor(sender : UIBarButtonItem){
        let alert = UIAlertController(title: "Annotation Color", message: "", preferredStyle: .alert)
        
        let action = UIAlertAction(title: "Ok", style: .cancel) { (action:UIAlertAction) in
            //alert.dismiss(animated: true, completion: nil)
        }
        
        alert.addAction(action)
        
        switch sender.tag {
        case 1000:
            //Red
            highlightColor = UIColor.red
            alert.message = "Changed to Red"
            break
        case 1001:
            //Green
            highlightColor = UIColor.green
            alert.message = "Changed to Green"
            
            break
        case 1002:
            //Yellow
            highlightColor = UIColor.yellow
            alert.message = "Changed to Yellow"
            
            break
        case 1003:
            //Orange
            highlightColor = UIColor.orange
            alert.message = "Changed to Orange"
            
            break
        default:
            highlightColor = UIColor.yellow
            alert.message = "Changed to Yellow"
            break
        }
        
        
        self.present(alert, animated: true, completion: nil)
        
    }
}


extension UIViewController : PDFViewDelegate{
    
    public func pdfViewPerformGo(toPage sender: PDFView) {
        print("Page \(String(describing: sender.currentPage))");
    }
    public func pdfViewWillClick(onLink sender: PDFView, with url: URL) {
        print("Clicked: \(url)")
    }
    
    
}
