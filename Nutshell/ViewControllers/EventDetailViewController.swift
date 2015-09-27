/*
* Copyright (c) 2015, Tidepool Project
*
* This program is free software; you can redistribute it and/or modify it under
* the terms of the associated License, which is identical to the BSD 2-Clause
* License as published by the Open Source Initiative at opensource.org.
*
* This program is distributed in the hope that it will be useful, but WITHOUT
* ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
* FOR A PARTICULAR PURPOSE. See the License for more details.
*
* You should have received a copy of the License along with this program; if
* not, you can obtain one from Tidepool Project at tidepool.org.
*/


import UIKit


class EventDetailViewController: BaseUIViewController {

    var eventItem: NutMeal?
    var graphView: GraphUIView?

    @IBOutlet weak var graphSectionView: UIView!
    @IBOutlet weak var missingDataAdvisoryView: UIView!
    
    @IBOutlet weak var photoUIImageView: UIImageView!

    @IBOutlet weak var missingPhotoView: UIView!
    
    @IBOutlet weak var eventNotes: NutshellUILabel!
    
    @IBOutlet weak var eventDate: NutshellUILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let eventItem = eventItem {
            eventNotes.text = eventItem.notes
            let df = NSDateFormatter()
            df.dateFormat = Styles.uniformDateFormat
            eventDate.text = df.stringFromDate(eventItem.time)
            if eventItem.photo.characters.count > 0 {
                if let image = UIImage(named: eventItem.photo) {
                    missingPhotoView.hidden = true
                    photoUIImageView.hidden = false
                    photoUIImageView.image = image
                }
            } else {
                missingPhotoView.hidden = false
                photoUIImageView.hidden = true
            }
        }
    }

    override func viewDidLayoutSubviews() {
        
        if (graphView != nil) {
            if (graphView!.frame.size != graphSectionView.frame.size) {
                graphView?.removeFromSuperview();
                graphView = nil;
            }
        }
        
        if (graphView == nil) {
            
            // self.view's direct subviews are laid out.
            // force my subview to layout its subviews:
            graphSectionView.setNeedsLayout()
            graphSectionView.layoutIfNeeded()
            
            // here we can get the frame of subviews of mySubView
            // and do useful things with that...
            if let eventTime = eventItem?.time {
                // need about 60 pixels per hour... so divide by 60, and multiply by 60x60
                let interval = NSTimeInterval(graphSectionView.bounds.width*60)
                graphView = GraphUIView.init(frame: graphSectionView.bounds, centerTime: eventTime, timeIntervalForView: interval)
                graphView!.configure()
                graphSectionView.addSubview(graphView!)
                graphSectionView.sendSubviewToBack(graphView!)
                
                missingDataAdvisoryView.hidden = (graphView?.dataFound())!
            }
         }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
