//
//  MeetingsScheduleController.swift
//  iBoard
//
//  Created by Kigen on 10/07/2018.
//  Copyright © 2018 Kigen. All rights reserved.
//

import UIKit
import CoreData
import Alamofire
import SwiftyJSON
import SVProgressHUD
import JTAppleCalendar
import ChameleonFramework

class MeetingScheduleController: UIViewController {
    
    @IBOutlet weak var yearMonthLabel: UILabel!
    @IBOutlet weak var calendarView: JTAppleCalendarView!
    var organization_id = ""
    let base_url = "http://iboard.dev"
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
   let dateFormatter = DateFormatter()
    var meetings = [Meeting]()
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        //Custom setup
        setup()
        
        //Get User Organization
        getUserOrganizationId()
        
       
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //If meetings get only the ones not saved
        
        //Saved on users phone for offline access
        
        getCachedMeetings()
        
        var saved_meeting_ids = [String]()
        
        if !meetings.isEmpty {
            for meeting : Meeting in meetings{
                if let id = meeting.meeting_id{
                    saved_meeting_ids.append(id)
                }
            }
        }
        fetchFromServer(saved_ids: saved_meeting_ids)
        
    }
    //MARK: - Custom code
    func setup(){
        self.navigationItem.setHidesBackButton(true, animated: true)
    }
    func getUserOrganizationId(){
        
        do{
            let result : NSFetchRequest<User> = User.fetchRequest();
            let user : [User] = try context.fetch(result)
            
            if(user.count > 0){
                let current_user = user.first
                
                self.organization_id = (current_user?.organization_id)!
            }
            
            
        }catch{
            print("Error fetching user: \(error)")
        }
    }
    
    //Fetch meetings from the Server
    func fetchFromServer(saved_ids : Array<String>){
        if(!organization_id.isEmpty){
            
            let meetings_url = "\(Global.baseUrl())/org_meetings"
            
            let params : [String : Any] = ["organization_id" :organization_id, "saved_meeting_ids" : saved_ids]
            
            Alamofire.request(meetings_url, method: .post, parameters : params).responseJSON {
                response in
                if(response.result.isSuccess){
                    let responseJSON  : JSON = JSON(response.result.value!)
                    
                    self.saveMeetings(json: responseJSON)
                    
                }else{
                    print("Meetings Error:\(String(describing: response.result.error))")
                }
                
            }
        }
        
    }
    
    func saveMeetings(json : JSON){
        //Parse JSON response
        for(_, subJson):(String, JSON) in json{
            
            for(key, meetingData): (String, JSON) in subJson{
                
                if(key == "meetings"){
                    for(_, meeting):(String, JSON) in meetingData{
                        let current_meeting = Meeting(context: context)
                        current_meeting.meeting_id = meeting["id"].stringValue
                        current_meeting.meeting_title = meeting["meeting_title"].stringValue
                        current_meeting.meeting_venue = meeting["venue"].stringValue
                        current_meeting.start_time = meeting["start_time"].stringValue
                        current_meeting.end_time = meeting["end_time"].stringValue
                        saveContext()
                    }
                }
            }
        }
        
        getCachedMeetings()
    }
    
    
    func getCachedMeetings(){
        let request : NSFetchRequest<Meeting> = Meeting.fetchRequest()
        
        do{
            meetings = try context.fetch(request)
        }catch{
            print("Error fetching meetings: \(error)")
        }
        calendarView.reloadData()

    }
    
    
    
    func saveContext(){
        do{
            try context.save();
        }catch{
            print("Error saving context \(error)")
        }
    }
    
 
    func handleCellTextColor(cell: JTAppleCell?, cellState: CellState){
        
    }
    
}
//MARK:- JTAppleCalendarView Data Source
extension MeetingScheduleController : JTAppleCalendarViewDataSource{
    public func configureCalendar(_ calendar: JTAppleCalendarView) -> ConfigurationParameters {
        dateFormatter.dateFormat = "yyyy MM dd"
        dateFormatter.locale = Calendar.current.locale
        dateFormatter.timeZone = Calendar.current.timeZone
        let startDate = dateFormatter.date(from: "2018 01 01")
        let endDate = dateFormatter.date(from: "2018 12 31")
        let parameters = ConfigurationParameters(startDate: startDate!, endDate: endDate!)
        return parameters
    }
    
    
}
//MARK:- JTAppleCalendarView Data Delegate
extension MeetingScheduleController: JTAppleCalendarViewDelegate{
    public func calendar(_ calendar: JTAppleCalendarView, willDisplay cell: JTAppleCell, forItemAt date: Date, cellState: CellState, indexPath: IndexPath) {
        
    }
    
    public func calendar(_ calendar: JTAppleCalendarView, cellForItemAt date: Date, cellState: CellState, indexPath: IndexPath) -> JTAppleCell{
 
      let cell = calendar.dequeueReusableJTAppleCell(withReuseIdentifier: "CalendarViewCell", for: indexPath) as! CalendarViewCell
        print(cellState.date)
        cell.dateLabel.text = cellState.text
        return cell
    }
    
    public func calendar(_ calendar: JTAppleCalendarView, didScrollToDateSegmentWith visibleDates: DateSegmentInfo) {
        let date = visibleDates.monthDates.first!
        dateFormatter.dateFormat = "yyyy MM"
        
        
    }
    
    
    
    public func calendar(_ calendar: JTAppleCalendarView, didSelectDate date: Date, cell: JTAppleCell?, cellState: CellState) {
        /*
        guard let validCell = cell as? CalendarViewCell else {return}
        
        validCell.selectedView.isHidden = false
        validCell.selectedView.backgroundColor = UIColor.flatRed
        calendar.reloadData()
      */
    }
    
    public func calendar(_ calendar: JTAppleCalendarView, didDeselectDate date: Date, cell: JTAppleCell?, cellState: CellState) {
        /*
        guard let validCell = cell as? CalendarViewCell else {return}
        validCell.selectedView.isHidden = true
        calendar.reloadData()
        */
        
    }
    
    
}



