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
import iProgressHUD
import JTAppleCalendar


class MeetingScheduleController: UIViewController {
    //MARK:- Properties
    
    @IBOutlet weak var yearMonthLabel: UILabel!
    @IBOutlet weak var calendarView: JTAppleCalendarView!
    var organization_id = ""
    let base_url = "http://iboard.dev"
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    let dateFormatter = DateFormatter()
    var cachedMeetings = [Meeting]()
    var selectedMeeting : Meeting?
    var todaysMeetings = [Meeting]()
    
    

    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Get User Organization
        getUserOrganizationId()
        
        //Custom setup
        setupCalendar()
        
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Global.showProgressView(view)
        //Scroll to the present month
        //self.calendarView.scrollToHeaderForDate(Date())
    
        self.calendarView.scrollToDate(Date())
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //If meetings get only the ones not saved
        
        //Saved on users phone for offline access

        getCachedMeetings()
        
        var saved_meeting_ids = [String]()
        
        if !cachedMeetings.isEmpty {
            for meeting : Meeting in cachedMeetings{
                if let id = meeting.meeting_id{
                    saved_meeting_ids.append(id)
                }
            }
        }
        fetchFromServer(saved_ids: saved_meeting_ids)
    }
    
    
    //MARK: - Custom code
    func setupCalendar(){
        self.navigationItem.setHidesBackButton(true, animated: true)
        
        //Set up Year Month Label for the first year
        calendarView.minimumInteritemSpacing = 2
        calendarView.minimumLineSpacing = 2
        
        
        //Change month year
        self.calendarView.visibleDates {[unowned self] (visibleDates: DateSegmentInfo) in
            self.monthYearLabel(from: visibleDates)
        }
        
        //Change month year
        //calendarView.visibleDates { (visibleDates) in
        // self.monthYearLabel(from: visibleDates)
        //}
        
    }
    

    func getUserOrganizationId(){
        
        do{
            let result : NSFetchRequest<User> = User.fetchRequest();
            let user : [User] = try context.fetch(result)
            
            if(user.count > 0){
                if let org_id = user.first?.organization_id!{
                self.organization_id = org_id
                }
                
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
            cachedMeetings = try context.fetch(request)
        }catch{
            print("Error fetching meetings: \(error)")
        }
        
        view.dismissProgress()
        
    }
    
    
    
    func saveContext(){
        do{
            try context.save();
        }catch{
            print("Error saving context \(error)")
        }
    }
    
    
    
    //Dispalay month Year
    func monthYearLabel(from visibleDates: DateSegmentInfo) {
        guard let startDate = visibleDates.monthDates.first?.date else {return}
        let month = Calendar.current.dateComponents([.month], from: startDate).month!
        let monthName = DateFormatter().monthSymbols[(month-1) % 12]
        // 0 indexed array
        let year = Calendar.current.component(.year, from: startDate)
        yearMonthLabel.text = monthName + " " + String(year)
    }
    
    //Check if the current date has meetings if so return the
    //meetings in as an array of meeting objects
    func getTodaysMeetings (date: Date) -> Array<Meeting> {
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let dateString = dateFormatter.string(from: date)
        
        let predicate : NSPredicate = NSPredicate(format: "start_time CONTAINS[c] %@", dateString)
        
        let request : NSFetchRequest<Meeting> = Meeting.fetchRequest()
        
        request.predicate = predicate
        
        var todaysMeetings = [Meeting]()
        
        do{
            todaysMeetings = try context.fetch(request)
        }catch{
            print("Error fetching meetings: \(error)")
        }
        return todaysMeetings
    }
    
    //Change the background of the cell
    func handleCellDisplay(cell: CalendarViewCell, cellState: CellState, date: Date){
        
        cell.dateLabel.text = cellState.text
        
        let todaysMeetings = getTodaysMeetings(date: date)
        
        if(todaysMeetings.count>0 && cellState.dateBelongsTo == . thisMonth){
            cell.selectedView.isHidden = false
        }else{
            cell.selectedView.isHidden = true
        }

        //Cell text color
        if cellState.dateBelongsTo == .thisMonth{
            cell.dateLabel.textColor = UIColor.black
        }else{
            cell.dateLabel.textColor = UIColor.lightGray
        }
        
        view.dismissProgress()
        
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDocs"{
            let meetingDocsViewController : MeetingDocsViewController = segue.destination as! MeetingDocsViewController
            meetingDocsViewController.meeting = selectedMeeting
        }
    }
}
//MARK:- JTAppleCalendarView Data Source
extension MeetingScheduleController : JTAppleCalendarViewDataSource{
    public func configureCalendar(_ calendar: JTAppleCalendarView) -> ConfigurationParameters {
        dateFormatter.dateFormat = "yyyy MM dd"
        dateFormatter.locale = Calendar.current.locale
        dateFormatter.timeZone = Calendar.current.timeZone
        //Get Current year
        let currentDate = Date()
        let yearDateFormmatter = DateFormatter()
        yearDateFormmatter.dateFormat = "yyyy"
        let currentYear = yearDateFormmatter.string(from: currentDate)
        
        //default calendar to this year
        let startDate = dateFormatter.date(from: "\(currentYear) 01 01")
        let endDate = dateFormatter.date(from: "\(currentYear) 12 31")
        //let params = ConfigurationParameters(startDate: startDate!, endDate: endDate!)
        let params = ConfigurationParameters(startDate: startDate!, endDate: endDate!, numberOfRows: 5, calendar: Calendar.current, generateInDates:.forAllMonths , generateOutDates:.tillEndOfGrid, firstDayOfWeek: .sunday, hasStrictBoundaries: true)
        return params
    }
}


//MARK:- JTAppleCalendarView Data Delegate
extension MeetingScheduleController: JTAppleCalendarViewDelegate{
    public func calendar(_ calendar: JTAppleCalendarView, cellForItemAt date: Date, cellState: CellState, indexPath: IndexPath) -> JTAppleCell{
        let cell = calendar.dequeueReusableJTAppleCell(withReuseIdentifier: "CalendarViewCell", for: indexPath) as! CalendarViewCell
        
        handleCellDisplay(cell: cell, cellState: cellState, date: date)

        return cell
    }
    
    public func calendar(_ calendar: JTAppleCalendarView, willDisplay cell: JTAppleCell, forItemAt date: Date, cellState: CellState, indexPath: IndexPath) {
        let customCell = cell as! CalendarViewCell
        handleCellDisplay(cell: customCell, cellState: cellState, date: date)
    }
    

    public func calendar(_ calendar: JTAppleCalendarView, didScrollToDateSegmentWith visibleDates: DateSegmentInfo) {
        monthYearLabel(from: visibleDates)
        todaysMeetings = [Meeting]()
        self.tableView.reloadData()
    }
    

    
    func handleCellSelection(date: Date){
        todaysMeetings = getTodaysMeetings(date: date)
        
        if(todaysMeetings.count>0) {
            //We have meetings scheduled for today
            tableView.reloadData()
        }else{
            todaysMeetings = [Meeting]()
            
        }
        
        tableView.reloadData()
    }
    
    public func calendar(_ calendar: JTAppleCalendarView, didSelectDate date: Date, cell: JTAppleCell?, cellState: CellState) {
        handleCellSelection(date: date)
    }
    
    
    func calendar(_ calendar: JTAppleCalendarView, didDeselectDate date: Date, cell: JTAppleCell?, cellState: CellState) {
        handleCellSelection(date: date)
    }
    
   
    
}

//MARK:- TableView Delegate
extension MeetingScheduleController : UITableViewDelegate{
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "meetings_cell", for: indexPath)
        // Configure the cell...
        let titleLabel : UILabel = cell.viewWithTag(100) as! UILabel
        let meetingTimeLabel : UILabel = cell.viewWithTag(101) as! UILabel
        let meetingVenueLabel : UILabel = cell.viewWithTag(102) as! UILabel
        
        let meeting : Meeting = todaysMeetings[indexPath.row]
        titleLabel.text = "Title: \(meeting.meeting_title ?? "")"
    
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        if let start = meeting.start_time , let end = meeting.end_time{
            //print(meeting.start_time)
            var meeting_time = ""
            let startDate : Date = formatter.date(from: start)!
            let endDate : Date = formatter.date(from: end)!
            formatter.dateFormat = "dd/MM/yyyy"
            meeting_time += formatter.string(from: startDate)
            formatter.dateFormat = "HH:mm a"
            let start_time = formatter.string(from: startDate)
            let end_time = formatter.string(from: endDate)
            meetingTimeLabel.text = "Date: \(meeting_time) From: \(start_time) To: \(end_time)"
        }
        meetingVenueLabel.text = "Venue: \(meeting.meeting_venue ?? "")"
        
        //tableView.reloadRows(at: [indexPath], with:UITableViewRowAnimation.fade)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedMeeting = todaysMeetings[indexPath.row]
        self.performSegue(withIdentifier: "showDocs", sender: self)
    }
}
//MARK:- TableView Data Source
extension MeetingScheduleController : UITableViewDataSource{
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return todaysMeetings.count
    }
    
}


