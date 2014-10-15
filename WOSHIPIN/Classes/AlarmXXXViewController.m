//
//  AlarmXXXViewController.m
//  VISS_GX
//
//  Created by Li Xinghua on 12-11-9.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "AlarmXXXViewController.h"
#import "Common.h"


@implementation AlarmXXXViewController

- (id)initForAlarmOutput: (NSArray *)_alarmxxx 
{
    if(self = [super initWithStyle:UITableViewStyleGrouped])
    {
        all_channelinfos = _alarmxxx;
        //cur_camera = _camdict;
        mode = 0;     
    }
    return self;
}


- (id)initForAlarmRecord:  (NSArray *)_alarmxxx 
{
    if(self = [super initWithStyle:UITableViewStyleGrouped])
    {
        all_channelinfos = _alarmxxx;
        //cur_camera = _camdict;
        mode = 1;        
    }
    return self;
}

- (id)initForAlarmShoot:  (NSArray *)_alarmxxx 
{
    if(self = [super initWithStyle:UITableViewStyleGrouped])
    {
        all_channelinfos = _alarmxxx;
        //cur_camera = _camdict;
        mode = 2;        
    }
    return self;
}



- (void)viewDidLoad
{
    [super viewDidLoad];

}


- (void)dealloc {
    [super dealloc];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (all_channelinfos ) return [all_channelinfos count];
    else return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }

    if (mode == 0)
    {
        NSDictionary * gpio_dict = [all_channelinfos objectAtIndex:indexPath.row];//gpio_out_array
        //cell.textLabel.text = [gpio_dict valueForKey:@"name"];        
        cell.textLabel.text = [NSString stringWithFormat:@"%@(%@)",[gpio_dict valueForKey:@"name"], [gpio_dict valueForKey:@"channelNumber"]];        
        
        if ([gpio_dict valueForKey:@"AlarmOutput"])
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        else
            cell.accessoryType = UITableViewCellAccessoryNone;
    }
    else if (mode == 1)
    {
        NSDictionary * camdict = [all_channelinfos objectAtIndex:indexPath.row];//camera obj array
        cell.textLabel.text = [NSString stringWithFormat:@"%@(%@)",[camdict valueForKey:@"name"], [camdict valueForKey:@"channelNumber"]];
        
        cell.accessoryType = [camdict valueForKey:@"AlarmRecord"] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    }
    else if (mode == 2)
    {
        NSDictionary * camdict = [all_channelinfos objectAtIndex:indexPath.row];//camera obj array
        //cell.textLabel.text = [camdict valueForKey:@"name"];
        cell.textLabel.text = [NSString stringWithFormat:@"%@(%@)",[camdict valueForKey:@"name"], [camdict valueForKey:@"channelNumber"]];
        
        cell.accessoryType = [camdict valueForKey:@"AlarmShoot"] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    }
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (mode == 0)
    {
        NSMutableDictionary * gpio_dict = [all_channelinfos objectAtIndex:indexPath.row];
        if ([gpio_dict valueForKey:@"AlarmOutput"])
            [gpio_dict removeObjectForKey:@"AlarmOutput"];
        else {
            [gpio_dict setValue:@"1" forKey:@"AlarmOutput"];
        }
    }
    else if (mode == 1)
    {
        NSMutableDictionary * dict = [all_channelinfos objectAtIndex:indexPath.row];
        if ([dict valueForKey:@"AlarmRecord"])
            [dict removeObjectForKey:@"AlarmRecord"];
        else {
            [dict setValue:@"1" forKey:@"AlarmRecord"];
        }
    }
    else if (mode == 2)
    {
        NSMutableDictionary * dict = [all_channelinfos objectAtIndex:indexPath.row];
        if ([dict valueForKey:@"AlarmShoot"])
            [dict removeObjectForKey:@"AlarmShoot"];
        else {
            [dict setValue:@"1" forKey:@"AlarmShoot"];
        }
        
    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];	
    [tableView reloadData];    
}

@end
