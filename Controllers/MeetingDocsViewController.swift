//
//  MeetingDocsViewController.swift
//  iBoard
//
//  Created by Kigen on 23/06/2018.
//  Copyright © 2018 Kigen. All rights reserved.
//

import UIKit
import CoreData
import Alamofire
import SwiftyJSON
import SVProgressHUD

class MeetingDocsViewController: UITableViewController {

    
    var meeting_title = ""
    let base_url = "http://iboard.dev"
    
    var meeting : Meeting? {
        didSet{
            //Fetch locally stored documents
            getCachedDocs()
            
            var saved_doc_ids : Array<String> = [String]()
            if !documents.isEmpty{
                
                for doc : Document in documents{
                    if let id = doc.document_id{
                        saved_doc_ids.append(id)
                    }
                }
            }
            
            fetchFromServer(saved_ids: saved_doc_ids)
            
        }
    }
   
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    var documents = [Document]()
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - Custom code
    
    //Fetch Meeting Documents
    func fetchFromServer(saved_ids : Array<String>) {
            if let meeting_id = meeting?.meeting_id{
            SVProgressHUD.show(withStatus: "Processing......")
            let docs_url = "\(Global.baseUrl())/meeting_docs"
            
            //let saved_doc_ids = [String]()
           
            let params : [String : Any] = ["meeting_id" : meeting_id, "saved_doc_ids" : saved_ids]
            
            
            //Alamofire.request(login_url, method: .post, parameters: params).responseJSON {
            Alamofire.request(docs_url, method: .post, parameters : params).responseJSON {
                response in
                if(response.result.isSuccess){
                    let responseJSON  : JSON = JSON(response.result.value!)
                    
                    self.saveDocs(json: responseJSON)
                    
                }else{
                    print("Meetings Error:\(String(describing: response.result.error))")
                }
                
            }
            SVProgressHUD.dismiss()
        
        }
    }
    
    func saveDocs(json : JSON){
        //Parse JSON response
        for(_, subJson):(String, JSON) in json{
            
            for(key, meetingDocs): (String, JSON) in subJson{
                
                if(key == "documents"){
                    for(_, document):(String, JSON) in meetingDocs{
                        
                        let doc : Document = Document(context: context)
                        doc.document_id = document["id"].stringValue
                        doc.document_title = document["document_title"].stringValue
                        doc.document_type = document["document_type"].stringValue
                        doc.document_path = document["document_path"].stringValue
                        doc.meeting = meeting
                        saveContext()
                    }
                }
            }
        }
        
        getCachedDocs()
    }
    
    func getCachedDocs(){
        let request : NSFetchRequest<Document> = Document.fetchRequest()
        
        do{
            if let meeting_id = meeting?.meeting_id {
                request.predicate = NSPredicate(format: "meeting.meeting_id == %@", meeting_id)
                documents = try context.fetch(request)
            }
            
        }catch{
            print("Error fetching cached docs: \(error)")
        }
        tableView.reloadData()
        
    }
    //Save context to coredata
    func saveContext(){
        do{
            try context.save();
        }catch{
            print("Error saving context \(error)")
        }
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return documents.count
    }
    
    // MARK: - Table view data delegates
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "documents_cell", for: indexPath)
        // Configure the cell...
        let titleLabel : UILabel = cell.viewWithTag(101) as! UILabel
        
        //Populate meetings
        let document : Document = documents[indexPath.row]
        
        titleLabel.text = document.document_title
    
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "showDoc", sender: self)
    }
    
  
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let selectedDoc = documents[(tableView.indexPathForSelectedRow?.row)!]
        
        let docViewController : DocumentViewController = segue.destination as! DocumentViewController
        
        docViewController.document_path = selectedDoc.document_path!
        
        if  meeting != nil{
            
            docViewController.meeting_title = (meeting?.meeting_title!)!
            
        }
        
        
       
        
    }

}
