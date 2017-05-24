//
//  iPhoneDeviceViewController.m
//  iFixit
//
//  Created by David Patierno on 9/15/11.
//  Copyright (c) 2011 iFixit. All rights reserved.
//

#import "iPhoneDeviceViewController.h"
#import "iFixitAPI.h"
#import "DictionaryHelper.h"
#import "GuideCell.h"
#import "UIImageView+WebCache.h"
#import "iFixitAppDelegate.h"
#import "GuideViewController.h"
#import "Config.h"
#import "ListViewController.h"
#import "GuideLib.h"
#import "WikiCell.h"
#import "WikiVC.h"

@implementation iPhoneDeviceViewController

@synthesize topic=_topic;
@synthesize guides=_guides;
@synthesize wikis=_wikis;

- (id)initWithTopic:(NSString *)topic {
    if ((self = [super initWithNibName:nil bundle:nil])) {
        self.topic = topic;
         self.guides = [NSArray array];
         self.wikis = [NSArray array];
        
        if (!topic)
            self.title = NSLocalizedString(@"Guides", nil);
        
        [self getGuides];
    }
    return self;
}

#pragma mark - View lifecycle

- (void)viewWillAppear:(BOOL)animated {
    if (self.currentCategory)
        self.navigationItem.title = self.currentCategory;
}

- (void)showRefreshButton {
    // Show a refresh button in the navBar.
    UIBarButtonItem *refreshButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                                                                                   target:self
                                                                                   action:@selector(getGuides)];
    self.navigationItem.rightBarButtonItem = refreshButton;
    [refreshButton release];   
}

- (void)showLoading {
    loading = YES;
    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 28.0f, 20.0f)];
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 20.0f, 20.0f)];
    spinner.activityIndicatorViewStyle = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) ?
    UIActivityIndicatorViewStyleGray : UIActivityIndicatorViewStyleWhite;
    [container addSubview:spinner];
    [spinner startAnimating];
    [spinner release];
    
    UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithCustomView:container];
    self.navigationItem.rightBarButtonItem = button;
    [container release];
    [button release];
}
- (void)hideLoading {
    loading = NO;
    self.navigationItem.rightBarButtonItem = nil;
    [self.listViewController showFavoritesButton:self];
}

- (void)getGuides {
    if (!loading) {
        loading = YES;
        [self showLoading];
        
        if (self.topic)
            [[iFixitAPI sharedInstance] getCategory:self.topic forObject:self withSelector:@selector(gotCategory:)];
        else
            [[iFixitAPI sharedInstance] getGuides:nil forObject:self withSelector:@selector(gotGuides:)];
    }
}

- (void)gotGuides:(NSArray *)guides {
    
    if (!guides) {
        [iFixitAPI displayConnectionErrorAlert];
        [self showRefreshButton];
    }
    
    self.guides = guides;
    [self.tableView reloadData];
    [self hideLoading];
}
- (void)gotCategory:(NSDictionary *)data {
    if (!data) {
        [iFixitAPI displayConnectionErrorAlert];
        [self showRefreshButton];
        return;
    }
    
    
     self.guides = [data arrayForKey:@"guides"];
     self.wikis = [data arrayForKey:@"related_wikis"];
    [self.tableView reloadData];
    [self hideLoading];
    
    if (!self.guides)
        [self showRefreshButton];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Grab reference to listViewController
    self.listViewController = (ListViewController*)self.navigationController;
    
    // Make room for the toolbar
    [self willRotateToInterfaceOrientation:self.interfaceOrientation duration:0];

    if (loading)
        [self showLoading];
    
    // Show the Dozuki sites select button if needed.
    if ([Config currentConfig].dozuki && !self.topic) {
        UIImage *icon = [UIImage imageNamed:@"backtosites.png"];
        UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithImage:icon style:UIBarButtonItemStyleBordered
                                                                  target:[[UIApplication sharedApplication] delegate]
                                                                  action:@selector(showDozukiSplash)];
        self.navigationItem.leftBarButtonItem = button;
        [button release];
    }
     
     [self.tableView registerNib:[UINib nibWithNibName:@"WikiCell" bundle:nil] forCellReuseIdentifier:@"WikiCell"];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    // Make room for the toolbar
    if (UIInterfaceOrientationIsPortrait(toInterfaceOrientation)) {
        self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 44, 0);
        self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, 44, 0);
    }
    else {
        self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 32, 0);
        self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, 32, 0);
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
     if (self.wikis != nil && [self.wikis count] > 0) {
          return 2;
     }
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
     if (section == 0) {
          return [self.guides count];
     } else if (section == 1) {
          return [self.wikis count];
     }
     return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"GuideCell";
    
     if (indexPath.section == 0) {
     
    GuideCell *cell = (GuideCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[GuideCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    // Configure the cell...
    NSString *title = [self.guides[indexPath.row][@"title"] isEqual:@""] ? NSLocalizedString(@"Untitled", nil) : self.guides[indexPath.row][@"title"];
    

    title = [title stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];
    title = [title stringByReplacingOccurrencesOfString:@"&quot;" withString:@"\""];
    title = [title stringByReplacingOccurrencesOfString:@"<wbr />" withString:@""];
    
    cell.textLabel.text = title;
    
    NSDictionary *imageData = self.guides[indexPath.row][@"image"];
    NSString *thumbnailURL = [imageData isEqual:[NSNull null]] ? nil : imageData[@"thumbnail"];
    
    [cell.imageView setImageWithURL:[NSURL URLWithString:thumbnailURL] placeholderImage:[UIImage imageNamed:@"WaitImage.png"]];
    
    return cell;
     } else {
          WikiCell *cell = (WikiCell*)[tableView dequeueReusableCellWithIdentifier:@"WikiCell"];
          if (cell == nil) {
               cell = [[WikiCell alloc] initWithStyle:UITableViewStylePlain reuseIdentifier:@"WikiCell"];
          }
          NSString *title = [self.wikis[indexPath.row][@"title"] isEqual:@""] ? NSLocalizedString(@"Untitled", nil) : self.wikis[indexPath.row][@"title"];
          [cell.wikiTitle setText:title];
          NSDictionary *imageData = self.wikis[indexPath.row][@"image"];
          NSString *thumbnailURL = [imageData isEqual:[NSNull null]] ? nil : imageData[@"medium"];
          [cell.wikiImage setImageWithURL:[NSURL URLWithString:thumbnailURL] placeholderImage:[UIImage imageNamed:@"WaitImage.png"]];
          [cell setNeedsLayout];
         return cell;
     }
     return nil;
}

#pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
     if (indexPath.section == 1) {
          return 200.0f;
     }
     return 44.0f;
}

- (CGFloat)tableView:(UITableView *)tableView
heightForHeaderInSection:(NSInteger)section {
     return 40.0;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
     UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 40)];
     /* Create custom view to display section header... */
     [view setBackgroundColor:[UIColor redColor]];
     UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(50, 5, tableView.frame.size.width, 40)];
     label.font = [UIFont fontWithName:@"MuseoSans-500" size:20.0];
     //[label setFont:[UIFont boldSystemFontOfSize:14]];
     [label setTextColor:[UIColor whiteColor]];
     NSString *string =(section==0)?@"Categories":@"Wikis";//[list objectAtIndex:section];
     /* Section header is in 0th index... */
     [label setText:string];
     [view addSubview:label];
     [view setBackgroundColor:[UIColor colorWithRed:240/255.0 green:28/255.0 blue:0/255.0 alpha:1.0]]; //your background color...
     
     UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
     imageView.image = [UIImage imageNamed:(section==0)?@"GuidesSection":@"WikisSection"];
     [view addSubview:imageView];
     return view;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
     if (indexPath.section == 0) {
          [GuideLib loadAndPresentGuideForGuideid:self.guides[indexPath.row][@"guideid"]];
          [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
     } else {
          [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
          NSString *url = [self.wikis[indexPath.row][@"url"] isEqual:@""] ? @"http://www.dozuki.com" : self.wikis[indexPath.row][@"url"];
          WikiVC *viewController = [[WikiVC alloc] initWithNibName:@"WikiVC" bundle:nil];
          viewController.url = url;
          [self.navigationController pushViewController:viewController animated:true];
     }
}

- (void)dealloc {
    [_topic release];
    [_guides release];
    [super dealloc];
}

@end
