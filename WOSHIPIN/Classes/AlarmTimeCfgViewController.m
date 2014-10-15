//
//  AlarmTimeCfgViewController.m
//  VISS_GX
//
//  Created by Li Xinghua on 12-11-9.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "AlarmTimeCfgViewController.h"



@implementation AlarmTimeCfgViewController

- (id)initWithAlarmTime:(unsigned char*)t
{
    if(self = [super initWithNibName:@"AlarmTimeCfgViewController" bundle:nil])
    {
        alarmtime_i = t;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    atableView.allowsSelection = YES;
    atableView.delegate = self;
    atableView.dataSource = self;
    hmPicker.delegate = self;
    hmPicker.dataSource = self;

    row_selected = 0;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [hmPicker selectRow:alarmtime_i[0+ row_selected*2] inComponent:0 animated:YES];//hour
    [hmPicker selectRow:alarmtime_i[1+ row_selected*2] inComponent:1 animated:YES];
}

- (void)dealloc {
    [hmPicker release];
    [atableView release];
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
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *ACellIdentifier = @"ACell";
    UITableViewCell *cell ;

    cell = [tableView dequeueReusableCellWithIdentifier:ACellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:ACellIdentifier] autorelease];
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        
    }
    
    if (indexPath.row == 0)
    {
        cell.textLabel.text = @"告警起始时间";
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%02d:%02d", alarmtime_i[0], alarmtime_i[1]];

        if (row_selected == 0)
            cell.imageView.image = [UIImage imageNamed:@"tick.png"];
        else
            cell.imageView.image = [UIImage imageNamed:@"unselected.png"];
        //[cell setSelected:(row_selected == 0)] ;
        //cell.accessoryType = (row_selected == 0) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    }
    else
    {
        cell.textLabel.text = @"告警结束时间";
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%02d:%02d", alarmtime_i[2], alarmtime_i[3]];
        
        if (row_selected == 1)
            cell.imageView.image = [UIImage imageNamed:@"tick.png"];
        else
            cell.imageView.image = [UIImage imageNamed:@"unselected.png"];
        //[cell setSelected:(row_selected == 1)]  ;
        //cell.accessoryType = (row_selected == 1) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    }
    
    
    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    row_selected = indexPath.row;
    
    [tableView reloadData];    
    
    [hmPicker selectRow:alarmtime_i[0+ row_selected*2] inComponent:0 animated:YES];//hour
    [hmPicker selectRow:alarmtime_i[1+ row_selected*2] inComponent:1 animated:YES];
}

#pragma mark - Picker view datasource
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 2;
}

// returns the # of rows in each component..
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return  (component == 0) ? 25 : 60; 
}


#pragma mark - Picker view delegate
/*- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component
{
    
}
- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component
{
    
}*/

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return [NSString stringWithFormat:@"%02d", row];
}
/*
- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view
{
    
}*/

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    alarmtime_i[component+row_selected*2] = row;
    [atableView reloadData];
}

@end
