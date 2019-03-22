//
//  ViewController.swift
//  FlowerSnapp
//
//  Created by Emanuel Covaci on 22/03/2019.
//  Copyright © 2019 Emanuel Covaci. All rights reserved.
//

import UIKit
import Vision
import CoreML
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate	 {
    
    @IBOutlet weak var imageView: UIImageView!
    
    let  imagePicker = UIImagePickerController()
    let wikipediaURl = "https://en.wikipedia.org/w/api.php"

    @IBOutlet weak var about: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        imagePicker.delegate = self
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .camera
    }
    
    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[.originalImage] as? UIImage{
            
            imageView.contentMode = .scaleAspectFit
            guard let ciimage = CIImage(image: pickedImage) else { fatalError("Could not convert UIImage into CIImage")}
            
            detect(image: ciimage)
            
            imagePicker.dismiss(animated: true, completion: nil)
        }
    }
    
    func detect(image: CIImage){
        
        guard let model =  try? VNCoreMLModel(for: FlowerClassifier().model) else {fatalError("Loading CoreML Model Field")}
        
        let request = VNCoreMLRequest(model: model) { (request, error) in
            
            guard let result = request.results as? [VNClassificationObservation] else {fatalError("Model Field to process image")}
            
                        if let firstResult = result.first {
                                print(firstResult.identifier)
                                let flowerName = firstResult.identifier.capitalized
                                self.navigationItem.title = flowerName
                                self.requestInformation(for: flowerName)
                            
                        }
            
        }
        
        let handler = VNImageRequestHandler(ciImage: image)
        
        do{
            try handler.perform([request])
        }catch{
            print(error)
        }
        
        
        
    }
    
    func requestInformation(for flowerName:String){
        
        let parameters : [String:String] = [
            "format" : "json",
            "action" : "query",
            "prop" : "extracts|pageimages",
            "exintro" : "",
            "explaintext" : "",
            "titles" : flowerName,
            "indexpageids" : "",
            "redirects" : "1",
            "pithumbsize":"500"
            ]

        Alamofire.request(wikipediaURl,method: .get, parameters: parameters).responseJSON { (response) in
            if response.result.isSuccess{
                print("Succes!")
                let responseJSON : JSON = JSON(response.result.value!)
                print(responseJSON)
                let pageid = responseJSON["query"]["pageids"][0].stringValue
                print(pageid)
                let about = responseJSON["query"]["pages"][pageid]["extract"]
                print(about)
                self.about.text = about.stringValue
                
                let flowerImageURL = responseJSON["query"]["pages"][pageid]["thumbnail"]["source"].stringValue
                
                self.imageView.sd_setImage(with: URL(string: flowerImageURL))
            }
        }
    }

    
    
    @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
        present(imagePicker,animated: true,completion: nil)
    }
    
    
    


}

