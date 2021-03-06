//
//  FeedViewController.swift
//  SocialOne
//
//  Created by Benny Ooi Kean Hoe on 4/25/20.
//  Copyright © 2020 Benny Ooi. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FBSDKLoginKit
import SwiftyJSON

class FeedViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
      
    
    var facebookAPIResult: JSON = JSON()
    var instagramAPIResult: JSON = JSON()
    var loaded: Bool = false
    let myRefreshControl = UIRefreshControl()
    var instagramPageID = ""
    var instagramAccountID = ""
    var socialMediaFeeds = [SocialMediaPost]()
    var loadFromFacebook = false
    var loadFromInstagram = false
    var loadFromTwitter = false
    
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        formatter.timeZone = TimeZone.current
        return formatter
        
    } ()


    @IBOutlet weak var tableView: UITableView!

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        tableView.delegate = self
        tableView.dataSource = self
        
        initiateAPICalls()
        //loadFacebookFeed()
        //getInstagramIDS()
        
        //implementing "pull down to refresh"
        myRefreshControl.addTarget(self, action: #selector(initiateAPICalls), for: .valueChanged)
        tableView.refreshControl = myRefreshControl
        
     

    }
   
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)


        
    }
    
    @objc func initiateAPICalls()
    {
          self.socialMediaFeeds = [SocialMediaPost]()
             self.loaded = false
             if (AccessToken.current != nil)
             {
                   self.loadFromFacebook = true
                 
                 if((AccessToken.current?.hasGranted(permission: "instagram_basic") ?? false) ==  true)
                 {
                     self.loadFromInstagram = true
                    self.loadFromTwitter = true
                 }
                     self.loadFacebookFeed()
             }
        
            // self.loadFacebookFeed()
             print("BACK FROM LOADFACEBOOKFEED")
                 self.tableView.reloadData()
         
                 
             
             
             
               self.myRefreshControl.endRefreshing()
        
        
    }

    func getInstagramIDS()
    {
        if (AccessToken.current != nil  && (AccessToken.current?.hasGranted(permission: "instagram_basic") ?? false))
        {
           
            
            GraphRequest(graphPath: "/me/accounts", parameters: ["":""], httpMethod: .get).start { (connection, result, error) in
                if error == nil
                {
                    
                    if let result = result{
                        let temp = JSON(result)
                        self.instagramPageID = temp["data"][0]["id"].string!
                        //print("result from account id \(self.instagramPageID): \(temp) lets see")
                        
                        
                        
                        if(self.instagramPageID != "")
                        {
                            print("inside")
                            GraphRequest(graphPath: "/\(self.instagramPageID)", parameters: ["fields":"instagram_business_account"], httpMethod: .get).start { (connection, result, error) in
                                 if error == nil
                                 {
                                     
                                     if let result = result
                                     {
                                         let temp = JSON(result)
                                        self.instagramAccountID = temp["instagram_business_account"]["id"].string!
                                        
                                            //print("Information from instagram account \(self.instagramAccountID): \(temp)")
                                        self.loadInstagramFeed()
                                     }
                                 }
                                 else
                                 {
                                     print(error?.localizedDescription)
                                 }
                             }

                         }
                     }
                 }
                else
                 {
                    print(error?.localizedDescription)
                 }
             }
        
            
        }
    }
    
    func loadInstagramFeed()
    {
        print("INSIDE LOADING INSTAGRAM FEED \(self.instagramAccountID)")
        
        GraphRequest(graphPath: "/\(self.instagramAccountID)/media", parameters: ["fields":"caption, comments_count, like_count, media_type, media_url, owner, username, timestamp"], httpMethod: .get).start { (connection, result, error) in
            
            if error == nil
            {
                if let result = result
                {
                    //print("BUSINESS DISCOVERY\n \(result)")
                    self.instagramAPIResult = JSON(result)
                   // print("BUSINESS DISCOVERY\n \(self.instagramAPIResult)")
                    
                    GraphRequest(graphPath: "/\(self.instagramAccountID)", parameters: ["fields": "profile_picture_url"], httpMethod: .get).start { (connection, result, error) in
                        
                        if error == nil
                        {
                            let tempJson = JSON(result)
                           // print("PROFILE URL JSON \n\(tempJson)")
                            let profileImageUrl = URL(string: tempJson["profile_picture_url"].string!)!
                            self.instagramAppendToSocialMediaFeedsArray(profileImageUrl: profileImageUrl)
                                            
                            
                        }
                        
                        else
                        {
                            print(error?.localizedDescription)
                        }
                    }
                
                    
                    
                }
            }
            else
            {
                print("BUSINESS DISCOVER \n \(error?.localizedDescription)")
            }
        }
        
        
    }
    
    func instagramAppendToSocialMediaFeedsArray(profileImageUrl: URL)
    {
        let data = self.instagramAPIResult["data"]
        let dataCount = data.count
        var tempCounter = 0
        
        while(tempCounter < dataCount)
        {
            let post = data[tempCounter]
            
            if(tempCounter == 1)
            {
                self.socialMediaFeeds.append(SocialMediaPost(inputIdentifier: 2,
                inputUsername: post["username"].string ?? " ",
                inputProfileImageURL: profileImageUrl,
                inputPostImageURL: URL(string: post["media_url"].string ?? " ")!, inputPostTextContent: post["caption"].string ?? " ",
                inputLikeCount: post["like_count"].int ?? 0,
                inputCommentCount: post["comments_count"].int ?? 0,
                inputContainsImage: true,
                inputTimeStamp: dateFormatter.date(from: "2020-05-09T09:51:16+0000")!))
            }
            else
            {
            self.socialMediaFeeds.append(SocialMediaPost(inputIdentifier: 2,
                                                         inputUsername: post["username"].string ?? " ",
                                                         inputProfileImageURL: profileImageUrl,
                                                         inputPostImageURL: URL(string: post["media_url"].string ?? " ")!, inputPostTextContent: post["caption"].string ?? " ",
                                                         inputLikeCount: post["like_count"].int ?? 0,
                                                         inputCommentCount: post["comments_count"].int ?? 0,
                                                         inputContainsImage: true,
                                                         inputTimeStamp: dateFormatter.date(from: post["timestamp"].string!)!))
            }
            tempCounter += 1
        }
        
        
        print("SOCIAL FEED ARRAY:")
        

        
        self.loaded = true
        if(self.loadFromTwitter == true)
        {
            self.twitterAppendToSocialMediaFeeds()
        }
        else
        {
            self.tableView.reloadData()
        }
       // tableView.reloadData()
        
        
    }
    
          
    func twitterAppendToSocialMediaFeeds()
    {
        
        self.socialMediaFeeds.append(SocialMediaPost(inputIdentifier: 3, inputUsername: "@kevinorellana2", inputProfileImageURL: URL(string: "https://graph.facebook.com/100050907580297/picture?type=small")!, inputPostImageURL: URL(string: "none")!, inputPostTextContent: "One more week and I will be done with my second semester at SJSU #SpartanUP#SJSU", inputLikeCount: 25, inputCommentCount: 16, inputContainsImage: false, inputTimeStamp: dateFormatter.date(from: "2020-05-09T10:51:16+0000")!))
        
        
        self.socialMediaFeeds.append(SocialMediaPost(inputIdentifier: 3, inputUsername: "@kevinorellana2", inputProfileImageURL: URL(string: "https://graph.facebook.com/100050907580297/picture?type=small")!, inputPostImageURL: URL(string: "none")!, inputPostTextContent: "Making progress on my social media project. Hopefully it will be online soon!", inputLikeCount: 40, inputCommentCount: 3, inputContainsImage: false, inputTimeStamp: dateFormatter.date(from: "2020-03-09T03:51:16+0000")!))
        
        for temp in self.socialMediaFeeds
        {
            print(temp.description())
        }
        self.loaded = true
        self.tableView.reloadData()
        
        
        
    }
    
    
    /*
     This function loads all the posts from the user's facebook feed and stores it on "apiResult"
     */
    @objc func loadFacebookFeed()
    {
        print("INSIDE LOAD FACEBOOK FEED")
        
        if (AccessToken.current != nil)
        {
            /*
            GraphRequest(graphPath: "me", parameters:  ["fields": "id, name, about"]).start(completionHandler: { connection, result, error in
                    if error == nil {
                            if let result = result {
                                //print("fetched user:\(result)")
                            }
                        }
                    })
 */
        
                  
                  
            let request = GraphRequest(graphPath: "/me/feed", parameters: ["fields":"name, from, message, full_picture, created_time" ], httpMethod: .get)
            
            request.start(completionHandler: { connection, result, error in
                if error == nil
                      {
                          
                        self.facebookAPIResult = JSON(result)
                        //print("Json Facebook Feed Result new\n \(self.facebookAPIResult)")
                        //print("User ID \((AccessToken.current?.userID)!)")
                        self.facebookAppendToSocialMediaFeeds()
                       // print("IMage URl: \(self.apiResult["data"][0]["full_picture"].string ?? "false")")
                        //self.loaded = true
                        
                        //self.tableView.reloadData()

                      }
                  })

        }
        else
        {
            print("MAKING LOADED FALSE")
            loaded = false
            self.tableView.reloadData()
        }
        
         
        //print("AT THE END OF PROFILE USER")
      
               // self.tableView.reloadData()

        
    }
    
    func facebookAppendToSocialMediaFeeds()
    {
        print("FACEBOOK  APPEND TO SOCIAL MEDIA FEEDS")
        let data = self.facebookAPIResult["data"]
        let datacount = data.count
        var index: Int = 0
        let userId = (AccessToken.current?.userID)!
        //print("INSIDE APENDING")// count \(datacount) \n\(data[0])")

        
        while(index < datacount)
        {
            let post = data[index]
            //print("POST \(post)")
            //print("FUll pic: \(post["full_picture"].string != nil)  Message \(post["message"].string != nil)\n\n")
            if(post["full_picture"].string != nil || post["message"].string != nil)
            {
                if(post["full_picture"].string == nil)
                {
                   // print("\n\(post)\n")
                    self.socialMediaFeeds.append(SocialMediaPost(inputIdentifier: 1,
                                                                 inputUsername: post["from"]["name"].string ?? "Unknown", inputProfileImageURL: URL(string:"https://graph.facebook.com/\(userId)/picture?type=small")!,
                                                                 inputPostImageURL: URL(string: "none")!,
                                                                 inputPostTextContent: post["message"].string ?? "", inputLikeCount: 0, inputCommentCount: 0, inputContainsImage: false,
                                                                 inputTimeStamp: dateFormatter.date(from: post["created_time"].string!)!))
        }
                else
                {
                      //print("\n\(post)\n")
                    self.socialMediaFeeds.append(SocialMediaPost(inputIdentifier: 1,
                                                                 inputUsername: post["from"]["name"].string ?? "Unknown", inputProfileImageURL: URL(string:"https://graph.facebook.com/\(userId)/picture?type=small")!,
                                                                 inputPostImageURL: URL(string: post["full_picture"].string!)!,
                                                                 inputPostTextContent: post["message"].string ?? "", inputLikeCount: 0, inputCommentCount: 0, inputContainsImage: true,
                                                                 inputTimeStamp: dateFormatter.date(from: post["created_time"].string!)!))
                    
                }
            }
            
            index += 1
        }
       
        /*
        print("SOCIAL FEED ARRAY: count: \(self.socialMediaFeeds.count)")
          for temp in self.socialMediaFeeds
          {
              print(temp.description())
          }*/
        print("OUTSIDE OF LOOP")
        self.loaded = true
        if(self.loadFromInstagram == true)
        {
            self.getInstagramIDS()
        }
        else
        {
            tableView.reloadData()
        }
            //tableView.reloadData()
        
        
    }

    
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if(loaded)
        {
            return self.socialMediaFeeds.count
            // return self.facebookAPIResult["data"].count
        }
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        
        
        if(loaded)
        {
            self.socialMediaFeeds  = self.socialMediaFeeds.sorted(by: {$0.timeStamp > $1.timeStamp})
            let post = self.socialMediaFeeds[indexPath.row]
            print("Post identifier \(post.identifier)")
            if(post.identifier == 1)
            {
                if(post.containsImage)
                {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "FacebookFeedTableViewCell") as! FacebookFeedTableViewCell
                    
                    cell.postContentLabel.text = post.postTextContent
                    cell.usernameLabel.text = post.userName
                    cell.postImage.af.setImage(withURL: post.postImageURL)
                    cell.profileImage.layer.cornerRadius = cell.profileImage.frame.size.width/2
                    cell.profileImage.af.setImage(withURL: post.profileImageURL)
                    return cell
                }
                else
                {
                    
                    let cell = tableView.dequeueReusableCell(withIdentifier: "FacebookFeedTwoTableViewCell") as! FacebookFeedTwoTableViewCell
                    cell.usernameLabel.text = post.userName
                    cell.postContent.text = post.postTextContent
                    cell.profileImage.layer.cornerRadius = cell.profileImage.frame.size.width/2
                    cell.profileImage.af.setImage(withURL: post.profileImageURL)
                    
                    return cell
                }
            }
            
            else if(post.identifier == 2)
            {
                if(self.socialMediaFeeds[indexPath.row].containsImage)
                {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "InstagramFeedOneTableViewCell") as! InstagramFeedOneTableViewCell
                    
                    cell.instagramUsername.text = self.socialMediaFeeds[indexPath.row].userName
                    cell.instagramImageContent.af.setImage(withURL: self.socialMediaFeeds[indexPath.row].postImageURL)
                    cell.instagramCommentsCountLabel.text = String(self.socialMediaFeeds[indexPath.row].commentCount)
                    cell.instagramLikesCountLabel.text = String(self.socialMediaFeeds[indexPath.row].likeCount)
                    cell.instagramPostContent.text = self.socialMediaFeeds[indexPath.row].postTextContent
                    cell.instagramProfilePicture.layer.cornerRadius = cell.instagramProfilePicture.frame.size.width/2
                    cell.instagramProfilePicture.af.setImage(withURL: self.socialMediaFeeds[indexPath.row].profileImageURL)
                    
                    return cell
                }
            }
            else
            {
                
                let cell = tableView.dequeueReusableCell(withIdentifier: "TwitterFeedTableViewCell") as! TwitterFeedTableViewCell
                
                cell.commentCount.text = String(post.commentCount)
                cell.likeCount.text = String(post.likeCount)
                cell.retweetCount.text = "4"
                cell.postTextContent.text = post.postTextContent
                cell.twitterProfileImage.layer.cornerRadius = cell.twitterProfileImage.frame.size.width/2
                cell.twitterProfileImage.af.setImage(withURL: post.profileImageURL)
                
                return cell
            }
            
            /*
            if(self.facebookAPIResult["data"][indexPath.row]["full_picture"].string == nil)//if post does not contain an post image
            {
                let userId = facebookAPIResult["data"][indexPath.row]["from"]["id"].string ?? ""
                let profileImageUrl = URL(string: "https://graph.facebook.com/\(userId)/picture?type=small")
                let cell = tableView.dequeueReusableCell(withIdentifier: "FacebookFeedTwoTableViewCell") as! FacebookFeedTwoTableViewCell
                cell.usernameLabel.text = self.facebookAPIResult["data"][indexPath.row]["from"]["name"].string ?? ""
                cell.postContent.text = self.facebookAPIResult["data"][indexPath.row]["message"].string ?? ""
                cell.profileImage.layer.cornerRadius = cell.profileImage.frame.size.width/2 //making the image to have a round shapte
                cell.profileImage.af.setImage(withURL: profileImageUrl!)
                return cell
            }
            
            else
            {
                let userId = facebookAPIResult["data"][indexPath.row]["from"]["id"].string ?? ""
                let profileImageUrl = URL(string: "https://graph.facebook.com/\(userId)/picture?type=small")
                let postImageUrl = URL(string: facebookAPIResult["data"][indexPath.row]["full_picture"].string!)
                let cell = tableView.dequeueReusableCell(withIdentifier: "FacebookFeedTableViewCell") as! FacebookFeedTableViewCell
                
                cell.usernameLabel.text = self.facebookAPIResult["data"][indexPath.row]["from"]["name"].string ?? ""
                cell.postContentLabel.text = self.facebookAPIResult["data"][indexPath.row]["message"].string ?? ""
                cell.postImage.af.setImage(withURL: postImageUrl!)
                cell.profileImage.layer.cornerRadius = cell.profileImage.frame.size.width/2 //setting the image to have a round shape
                cell.profileImage.af.setImage(withURL: profileImageUrl!)
                
               // print("Image Profile Url: \(profileImageUrl!)")
                
                return cell
                
            }
        */
        }
        
        return tableView.dequeueReusableCell(withIdentifier: "LoadingTableViewCell") as! LoadingTableViewCell

  }

}
