//
//  LoginViewController.swift
//  iBoard
//
//  Created by Kigen on 19/06/2018.
//  Copyright © 2018 Kigen. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import CoreData
import iProgressHUD





class LoginViewController: UIViewController, UITextFieldDelegate{
    
    
    var currentUser = [User]()
    
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    @IBOutlet weak var txtEmail: UITextField!
    @IBOutlet weak var txtPassword: UITextField!
    
    //MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
       
        txtEmail.delegate = self
        txtPassword.delegate = self
        getCurrentUser()
        
        if(currentUser.count>0){
            performSegue(withIdentifier: "showMeetings", sender: self)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super .viewWillAppear(animated)
        
    }
    
    
    
    
    //MARK: - Custom code
    @IBAction func doLogin(_ sender: UIButton) {
        
        let params : [String : String] = ["email": txtEmail.text!, "password":txtPassword.text!]
        
        let login_url = "\(Global.baseUrl())/app_login"
        
        Global.showProgressView(self.view)
        
        Alamofire.request(login_url, method: .post, parameters: params).responseJSON {
            response in
            
            if response.result.isSuccess {
                
                let responseJSON : JSON = JSON(response.result.value!)
                
                if(self.currentUser.count==0){
                    self.saveUser(json: responseJSON)
                }
            }
            else {
                print("Error \(String(describing: response.result.error))")
            }
            self.view.dismissProgress()
        }
    }
    
    //Save logged in user
    func saveUser(json: JSON){
        let user = User(context: context);
        user.email = json["user"]["email"].stringValue
        user.names = json["user"]["names"].stringValue
        user.id = json["user"]["id"].stringValue
        user.user_role_id = json["user"]["user_role_id"].stringValue
        user.organization_id = json["user"]["organization_id"].stringValue
        //Persist user to storage
        saveContext()
    }
    
    //Check if user is saved to SQLIte and fetch them
    func getCurrentUser(){
        let request : NSFetchRequest<User> = User.fetchRequest()
        do{
            currentUser = try context.fetch(request);
            
        }catch{
            print("Error fetchin User")
        }
        
    }
    
    //Save context
    func saveContext(){
        do{
            try context.save();
        }catch{
            print("Error saving context \(error)")
        }
        
        showMeetings()
    }
    //Show user meetings
    func showMeetings(){
        performSegue(withIdentifier: "showMeetings", sender: self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    
        
    }
    
    //MARK: - TextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool{
        textField.resignFirstResponder()
        return true
    }
    
    
    
    
    
}
