/**
 * Copyright (c) 2009, 2014, Pecunia Project. All rights reserved.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; version 2 of the
 * License.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
 * 02110-1301  USA
 */

#import "MessageLog.h"

#import "BSSelectWindowController.h"
#import "BankAccount.h"
#import "BankingController.h"
#import "MOAssistant.h"
#import "BankStatement.h"
#import "StatusBarController.h"

@implementation BSSelectWindowController

- (id)init
{
    self = [super initWithWindowNibName: @"BSSelectWindow"];
    resultList = [[NSMutableArray alloc] initWithCapacity:20];
    return self;
}

- (void)addResults: (NSArray*)list
{
    [resultList addObjectsFromArray:list];
}

- (void)awakeFromNib
{
    // green color for statements view
    NSTableColumn *tc = [statementsView tableColumnWithIdentifier: @"value"];
    if (tc) {
        NSCell            *cell = [tc dataCell];
        NSNumberFormatter *form = [cell formatter];
        if (form) {
            NSDictionary *newAttrs = @{@"NSColor": [NSColor colorWithDeviceRed: 0.09 green: 0.7 blue: 0 alpha: 100]};
            [form setTextAttributesForPositiveValues: newAttrs];
        }
    }

    // sort descriptor for statements view
    NSSortDescriptor *sd1 = [[NSSortDescriptor alloc] initWithKey: @"localAccount" ascending: YES];
    NSSortDescriptor *sd2 = [[NSSortDescriptor alloc] initWithKey: @"date" ascending: NO];
    NSArray          *sds = @[sd1, sd2];
    [statementsView setSortDescriptors: sds];
}

- (void)windowDidLoad
{
    NSMutableArray  *statements = [NSMutableArray arrayWithCapacity: 100];
    BankQueryResult *result;

    for (result in resultList) {
        [statements addObjectsFromArray: result.statements];
    }
    [statController setContent: statements];
    [[self window] center];
    [[self window] makeKeyAndOrderFront: self];
    [[self window] setDelegate:self];

}

- (BOOL)windowShouldClose: (id)sender
{
    if ([NSApp modalWindow] == self.window)
        [NSApp stopModal];
    
    return YES;
}

- (IBAction)ok: (id)sender
{
    int count = 0;

    BankQueryResult *result;

    @try {
        for (result in resultList) {
            count += [result.account updateFromQueryResult: result];
        }
    }
    @catch (NSException *error) {
        LogError(@"%@", error.debugDescription);
    }
    [[BankingController controller] requestFinished: resultList];

    // status message
    StatusBarController *sc = [StatusBarController controller];
    [sc setMessage: [NSString stringWithFormat: NSLocalizedString(@"AP218", nil), count] removeAfter: 120];

    [self.window close];
    [NSApp stopModal];
}

- (IBAction)cancel: (id)sender
{
    [[BankingController controller] requestFinished: nil];
    [self.window close];
    [NSApp stopModal];
}

@end
