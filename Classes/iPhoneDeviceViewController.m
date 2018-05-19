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
@synthesize docs=_docs;

- (id)initWithTopic:(NSString *)topic {
     if ((self = [super initWithNibName:nil bundle:nil])) {
          self.topic = topic;
          self.guides = [NSArray array];
          self.wikis = [NSArray array];
          self.cats = [NSArray array];
          self.docs = [NSArray array];

          if (!topic)
               self.title = NSLocalizedString(@"Guides", nil);
          
          [self getGuides];
     }
     return self;
}

#pragma mark - View lifecycle

- (void)viewWillAppear:(BOOL)animated {
     //    if (self.currentCategory)
     //        self.navigationItem.title = self.currentCategory;
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
          [iFixitAPI displayLoggedOutErrorAlert:self];
          [self showRefreshButton];
          return;
     }
     self.guides = [data arrayForKey:@"guides"];
     self.wikis = [data arrayForKey:@"related_wikis"];
     self.cats = [data arrayForKey:@"children"];
     self.docs = [data arrayForKey:@"documents"];
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
     int amount = 1;
     if (self.wikis != nil && [self.wikis count] > 0) {
          amount++;
     }
     if (self.cats != nil && [self.cats count] > 0) {
          amount++;
     }
     if (self.docs != nil && [self.docs count] > 0) {
          amount++;
     }
     return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
     // Return the number of rows in the section.
     if (section == 0) {
          return [self.guides count];
     } else if (section == 1) {
          return [self.cats count];
     } else if (section == 2) {
          return [self.wikis count];
     } else if (section == 3) {
          return [self.docs count];
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
     } else if (indexPath.section == 1) {
          
          GuideCell *cell = (GuideCell*)[tableView dequeueReusableCellWithIdentifier:@"GuideCell"];
          if (cell == nil) {
               cell = [[GuideCell alloc] initWithStyle:UITableViewStylePlain reuseIdentifier:@"GuideCell"];
          }
          NSString *title = [self.cats[indexPath.row][@"title"] isEqual:@""] ? NSLocalizedString(@"Untitled", nil) : self.cats[indexPath.row][@"title"];
          [cell.textLabel setText:title];
          NSDictionary *imageData = self.cats[indexPath.row][@"image"];
          NSString *thumbnailURL = [imageData isEqual:[NSNull null]] ? nil : imageData[@"medium"];
          [cell.imageView setImageWithURL:[NSURL URLWithString:thumbnailURL] placeholderImage:[UIImage imageNamed:@"WaitImage.png"]];
          [cell setNeedsLayout];
          return cell;
     } else if (indexPath.section == 2) {
          
          GuideCell *cell = (GuideCell*)[tableView dequeueReusableCellWithIdentifier:@"GuideCell"];
          if (cell == nil) {
               cell = [[GuideCell alloc] initWithStyle:UITableViewStylePlain reuseIdentifier:@"GuideCell"];
          }
          NSString *title = [self.wikis[indexPath.row][@"title"] isEqual:@""] ? NSLocalizedString(@"Untitled", nil) : self.wikis[indexPath.row][@"title"];
          [cell.textLabel setText:title];
          NSDictionary *imageData = self.wikis[indexPath.row][@"image"];
          NSString *thumbnailURL = [imageData isEqual:[NSNull null]] ? nil : imageData[@"medium"];
          [cell.imageView setImageWithURL:[NSURL URLWithString:thumbnailURL] placeholderImage:[UIImage imageNamed:@"WaitImage.png"]];
          [cell setNeedsLayout];
          return cell;
          
     }  else {
          
          GuideCell *cell = (GuideCell*)[tableView dequeueReusableCellWithIdentifier:@"GuideCell"];
          if (cell == nil) {
               cell = [[GuideCell alloc] initWithStyle:UITableViewStylePlain reuseIdentifier:@"GuideCell"];
          }
          NSString *title = [self.docs[indexPath.row][@"title"] isEqual:@""] ? NSLocalizedString(@"Untitled", nil) : self.docs[indexPath.row][@"title"];
          [cell.textLabel setText:title];
          NSDictionary *imageData = self.docs[indexPath.row][@"image"];
          NSString *thumbnailURL = [imageData isEqual:[NSNull null]] ? nil : imageData[@"medium"];
          [cell.imageView setImageWithURL:[NSURL URLWithString:thumbnailURL] placeholderImage:[UIImage imageNamed:@"WaitImage.png"]];
          [cell setNeedsLayout];
          return cell;
     }
     return nil;
}

#pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
     if (indexPath.section == 1) {
          return 44.0f;
     }
     return 44.0f;
}

- (CGFloat)tableView:(UITableView *)tableView
heightForHeaderInSection:(NSInteger)section {
     NSInteger count = 0;
     if (section == 0) {
          count = [self.guides count];
     } else if (section == 1) {
          count = [self.cats count];
     } else if (section == 2) {
          count = [self.wikis count];
     } else if (section == 3) {
          count = [self.docs count];
     }
     if ([self.guides count] == 0 && [self.cats count] == 0 && [self.wikis count] == 0 && [self.docs count] == 0 && section==0) {
          return 40.0;
     } else if (count == 0) {
          return 0.0;
     }
     return 40.0;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
     NSInteger count = 0;
     if (section == 0) {
          count = [self.guides count];
     } else if (section == 1) {
          count = [self.cats count];
     } else if (section == 2) {
          count = [self.wikis count];
     } else if (section == 3) {
          count = [self.docs count];
     }
     if ([self.guides count] == 0 && [self.cats count] == 0 && [self.wikis count] == 0 && [self.docs count] == 0 && section==0) {
          UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 40)];
          UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 10, tableView.frame.size.width, 20)];
          label.font = [UIFont fontWithName:@"MuseoSans-500" size:18.0];
          [label setTextColor:[UIColor blackColor]];
          [label setText:@"No guides are available."];
          [label setTextAlignment:NSTextAlignmentCenter];
          [view addSubview:label];
          return view;
     } else if (count == 0) {
          UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 0)];
          return view;
     }
     UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 40)];
     /* Create custom view to display section header... */
     [view setBackgroundColor:[UIColor redColor]];
     UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(50, 10, tableView.frame.size.width, 20)];
     label.font = [UIFont fontWithName:@"MuseoSans-500" size:18.0];
     //[label setFont:[UIFont boldSystemFontOfSize:14]];
     [label setTextColor:[UIColor whiteColor]];
     NSString *string=(section==0)?NSLocalizedString(@"Guides", nil):((section==1)?NSLocalizedString(@"Categories", nil):((section==2)?NSLocalizedString(@"Wikis", nil):NSLocalizedString(@"Documents", nil)));//[list objectAtIndex:section];
     /* Section header is in 0th index... */
     [label setText:string];
     [view addSubview:label];
     [view setBackgroundColor:[UIColor colorWithRed:240/255.0 green:28/255.0 blue:0/255.0 alpha:1.0]]; //your background color...
     
     UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
     imageView.image = [UIImage imageNamed:(section==0)?@"GuidesSection":((section==1)?@"CategoriesSection":@"WikisSection")];
     [view addSubview:imageView];
     return view;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
     if (indexPath.section == 0) {
          [GuideLib loadAndPresentGuideForGuideid:self.guides[indexPath.row][@"guideid"]];
          [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
     } else if (indexPath.section == 2) {
          [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
          NSString *url = [self.wikis[indexPath.row][@"url"] isEqual:@""] ? @"http://www.dozuki.com" : self.wikis[indexPath.row][@"url"];
          WikiVC *viewController = [[WikiVC alloc] initWithNibName:@"WikiVC" bundle:nil];
          viewController.url = url;
          [self.navigationController pushViewController:viewController animated:true];
     } else {
          [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
          NSString *list = self.docs[indexPath.row][@"filename"];
          NSArray *listItems = [list componentsSeparatedByString:@"."];
          NSString *urla =
          [[NSString alloc] initWithFormat: @"%@%@.%@", @"https://dozuki-documents.s3.amazonaws.com/",
           [self.docs[indexPath.row][@"guid"] isEqual:@""] ? @"" : self.docs[indexPath.row][@"guid"], listItems[1]];

          NSURL* url = [[NSURL alloc] initWithString:urla];
          NSURL* documentsUrl = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject;
          NSURL* destinationUrl = [documentsUrl URLByAppendingPathComponent:self.docs[indexPath.row][@"filename"]];

          NSError* err = nil;
          NSData* fileData = [[NSData alloc] initWithContentsOfURL:url options:NSDataReadingUncached error:&err];
          if (!err && fileData && fileData.length && [fileData writeToURL:destinationUrl atomically:true]) {

               UIDocumentInteractionController* document = [UIDocumentInteractionController interactionControllerWithURL:destinationUrl];
              // [UINavigationBar appearance].tintColor = [UIColor blueColor];

  //             document.UTI = @"com.adobe.pdf"; //@"public.jpeg";
               document.delegate = self;
               document.name = @"";
               [document presentPreviewAnimated:YES];
          }
     }
}

#pragma mark - UIDocumentInteractionControllerDelegate

- (void)documentInteractionControllerDidDismissOptionsMenu:(UIDocumentInteractionController *)controller {
     //[UINavigationBar appearance].tintColor = [UIColor whiteColor];
}

- (UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)controller {
     return self;
}

- (UIView *)documentInteractionControllerViewForPreview:(UIDocumentInteractionController *)controller {
     return self.view;
}

- (CGRect)documentInteractionControllerRectForPreview:(UIDocumentInteractionController *)controller {
     return self.view.frame;
}

- (void)dealloc {
     [_topic release];
     [_guides release];
     [super dealloc];
}

@end
