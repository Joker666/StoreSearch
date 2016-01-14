//
//  ViewController.swift
//  StoreSearch
//
//  Created by Hasan Rafi on 12/29/15.
//  Copyright © 2015 Hasan Rafi. All rights reserved.
//

import UIKit

class SearchViewController: UIViewController {
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    var searchResults = [SearchResult]()
    var hasSearched = false
    var isLoading = false
    
    var dataTask: NSURLSessionDataTask?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        tableView.contentInset = UIEdgeInsets(top: 108, left: 0, bottom: 0, right: 0)
        
        let cellNib1 = UINib(nibName: TableViewCellIdentifiers.searchResultCell, bundle: nil)
        tableView.registerNib(cellNib1, forCellReuseIdentifier: TableViewCellIdentifiers.searchResultCell)
        
        let cellNib2 = UINib(nibName: TableViewCellIdentifiers.nothingFoundCell, bundle: nil)
        tableView.registerNib(cellNib2, forCellReuseIdentifier: TableViewCellIdentifiers.nothingFoundCell)
        
        let cellNib3 = UINib(nibName: TableViewCellIdentifiers.loadingCell, bundle: nil)
        tableView.registerNib(cellNib3, forCellReuseIdentifier: TableViewCellIdentifiers.loadingCell)
        
        tableView.rowHeight = 80
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func urlWithSearchText(searchText: String, category: Int) -> NSURL {
        let esacapedSearchText = searchText.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())!
        
        var entityName: String
        switch category {
        case 1: entityName = "musicTrack"
        case 2: entityName = "software"
        case 3: entityName = "ebook"
        default: entityName = ""
        }
        
        let urlString = String(format: "http://itunes.apple.com/search?term=%@&limit=200&entity=%@", arguments: [esacapedSearchText, entityName])
        let url = NSURL(string: urlString)
        return url!
    }
    
    @IBAction func segmentChanged(sender: UISegmentedControl) {
        performSearch()
    }
    
    func parseJSON(data: NSData) -> [String: AnyObject]? {
        let json : [String: AnyObject]?
        do {
            json = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(rawValue: 0)) as? [String: AnyObject]
            return json
        } catch _ {
            return nil
        }
    }
    
    func parseTrack(dictionary: [String: AnyObject]) -> SearchResult {
        let searchResult = SearchResult()
        
        searchResult.name = dictionary["trackName"] as! String
        searchResult.artistName = dictionary["artistName"] as! String
        searchResult.artworkURL60 = dictionary["artworkUrl60"] as! String
        searchResult.artworkURL100 = dictionary["artworkUrl100"] as! String
        searchResult.storeURL = dictionary["trackViewUrl"] as! String
        searchResult.kind = dictionary["kind"] as! String
        searchResult.currency = dictionary["currency"] as! String
        
        if let price = dictionary["trackPrice"] as? NSNumber {
            searchResult.price = Double(price)
        }
        
        if let genre = dictionary["primaryGenreName"] as? String {
            searchResult.genre = genre
        }
        return searchResult
    }
    
    func parseDictionary(dictionary: [String: AnyObject]) -> [SearchResult] {
        var searchResults = [SearchResult]()
        
        if let array: AnyObject = dictionary["results"] {
            for resultDict in array as! [AnyObject] {
                if let resultDict = resultDict as? [String: AnyObject] {
                    var searchResult: SearchResult?
                    if let wrapperType = resultDict["wrapperType"] as? String {
                        switch wrapperType {
                        case "track":
                            searchResult = parseTrack(resultDict)
                        case "audiobook":
                            searchResult = parseAudioBook(resultDict)
                        case "software":
                            searchResult = parseSoftware(resultDict)
                        default:
                            break
                        }
                    } else if let kind = resultDict["kind"] as? String {
                        if kind == "ebook" {
                            searchResult = parseEBook(resultDict)
                        }
                    }
            
                    if let result = searchResult {
                        searchResults.append(result)
                    }
                } else {
                    print("Expected a dictionary")
                }
            }
        } else {
            print("Expected 'results' array")
        }
        
        return searchResults;
    }
    
    func showNetworkError() {
        let alert = UIAlertController (title: "Whoops...", message: "There was an error reading from itunes store, Please try again", preferredStyle: .Alert)
        
        let action = UIAlertAction(title: "Ok", style: .Default, handler: nil)
        alert.addAction(action)
        
        presentViewController(alert, animated: true, completion: nil)
    }
    
    func parseAudioBook(dictionary: [String: AnyObject]) -> SearchResult {
        let searchResult = SearchResult()
        searchResult.name = dictionary["collectionName"] as! String
        searchResult.artistName = dictionary["artistName"] as! String
        searchResult.artworkURL60 = dictionary["artworkUrl60"] as! String
        searchResult.artworkURL100 = dictionary["artworkUrl100"] as! String
        searchResult.storeURL = dictionary["collectionViewUrl"] as! String
        searchResult.kind = "audiobook"
        searchResult.currency = dictionary["currency"] as! String
            
        if let price = dictionary["collectionPrice"] as? NSNumber {
            searchResult.price = Double(price)
        }
        if let genre = dictionary["primaryGenreName"] as? String {
            searchResult.genre = genre
        }
        return searchResult
    }
    
    func parseEBook(dictionary: [String: AnyObject]) -> SearchResult {
        let searchResult = SearchResult()
        searchResult.name = dictionary["trackName"] as! String
        searchResult.artistName = dictionary["artistName"] as! String
        searchResult.artworkURL60 = dictionary["artworkUrl60"] as! String
        searchResult.artworkURL100 = dictionary["artworkUrl100"] as! String
        searchResult.storeURL = dictionary["trackViewUrl"] as! String
        searchResult.kind = dictionary["kind"] as! String
        searchResult.currency = dictionary["currency"] as! String
            
        if let price = dictionary["price"] as? NSNumber {
            searchResult.price = Double(price)
        }
        if let genres: AnyObject = dictionary["genres"] {
            searchResult.genre = (genres as! [String]).joinWithSeparator(", ")
        }
        return searchResult
    }
    
    func parseSoftware(dictionary: [String: AnyObject]) -> SearchResult {
        let searchResult = SearchResult()
        searchResult.name = dictionary["trackName"] as! String
        searchResult.artistName = dictionary["artistName"] as! String
        searchResult.artworkURL60 = dictionary["artworkUrl60"] as! String
        searchResult.artworkURL100 = dictionary["artworkUrl100"] as! String
        searchResult.storeURL = dictionary["trackViewUrl"] as! String
        searchResult.kind = dictionary["kind"] as! String
        searchResult.currency = dictionary["currency"] as! String
            
        if let price = dictionary["price"] as? NSNumber {
            searchResult.price = Double(price)
        }
        if let genre = dictionary["primaryGenreName"] as? String {
            searchResult.genre = genre
        }
        return searchResult
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "ShowDetail" {
            let detailViewController = segue.destinationViewController as! DetailViewController
            let indexPath = sender as! NSIndexPath
            let searchResult = searchResults[indexPath.row]
            detailViewController.searchResult = searchResult
        }
    }
    
}

extension SearchViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        performSearch()
    }
    
    func performSearch() {
        if !searchBar.text!.isEmpty {
            searchBar.resignFirstResponder()
            searchResults = [SearchResult]()
            
            dataTask?.cancel()
            isLoading = true
            tableView.reloadData()
            
            hasSearched = true
            
            let url = self.urlWithSearchText(searchBar.text!, category: segmentedControl.selectedSegmentIndex)
            
            let session = NSURLSession.sharedSession()
            dataTask = session.dataTaskWithURL(url, completionHandler: {
                data, response, error in
                
                if let error = error {
                    print("Failure! \(error)")
                    if error.code == -999 { return }
                } else if let httpResponse = response as? NSHTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        if let dictionary = self.parseJSON(data!) {
                            self.searchResults = self.parseDictionary(dictionary)
                            self.searchResults.sortInPlace(<)
                            
                            dispatch_async(dispatch_get_main_queue()) {
                                self.isLoading = false
                                self.tableView.reloadData()
                            }
                            return
                        }
                    } else {
                        print("Failure! \(response)")
                    }
                }
                
                dispatch_async(dispatch_get_main_queue()) {
                    self.hasSearched = false
                    self.isLoading = false
                    self.tableView.reloadData()
                    self.showNetworkError()
                }
            })
            
            dataTask?.resume()
        }
    }
    
    func positionForBar(bar: UIBarPositioning) -> UIBarPosition {
        return .TopAttached
    }
}

extension SearchViewController: UITableViewDelegate {

}

extension SearchViewController: UITableViewDataSource {
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        performSegueWithIdentifier("ShowDetail", sender: indexPath)
    }
    
    func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        if searchResults.count == 0 {
            return nil
        } else {
            return indexPath
        }
    }
    
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isLoading {
            return 1
        } else if !hasSearched {
            return 0
        } else if searchResults.count == 0 {
            return 1
        } else {
            return searchResults.count
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if isLoading {
            let cell = tableView.dequeueReusableCellWithIdentifier(TableViewCellIdentifiers.loadingCell, forIndexPath:indexPath) as UITableViewCell
            let spinner = cell.viewWithTag(100) as! UIActivityIndicatorView
            spinner.startAnimating()
            return cell
        } else if searchResults.count == 0 {
            return tableView.dequeueReusableCellWithIdentifier(TableViewCellIdentifiers.nothingFoundCell, forIndexPath: indexPath) 
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier(TableViewCellIdentifiers.searchResultCell, forIndexPath: indexPath) as! SearchResultCell
            let searchResult = searchResults[indexPath.row]
            
            cell.configureForSearchResult(searchResult)
            return cell
        }
    }
}

struct TableViewCellIdentifiers {
    static let searchResultCell = "SearchResultCell"
    static let nothingFoundCell = "NothingFoundCell"
    static let loadingCell = "LoadingCell"
}

