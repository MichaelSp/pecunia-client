/**
 * Copyright (c) 2010, 2013, Pecunia Project. All rights reserved.
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

#import "PurposeSplitController.h"
#import "MOAssistant.h"
#import "BankAccount.h"
#import "BankStatement.h"
#import "PurposeSplitData.h"

@implementation PurposeSplitController

- (id)initWithAccount: (BankAccount *)acc
{
    self = [super initWithWindowNibName: @"PurposeSplitWindow"];
    context = [[MOAssistant sharedAssistant] context];
    account = acc;
    processConvertedStats = YES;
    
    if (account.splitRule) {
        NSArray *tokens = [account.splitRule componentsSeparatedByString: @":"];
        if ([tokens count] != 2) {
            return nil;
        }
        
        // first part is version info, skip
        NSString *s = tokens[1];
        tokens = [s componentsSeparatedByString: @","];
        if ([tokens count] != 7) {
            return nil;
        }
        ePos = [tokens[0] intValue];
        eLen = [tokens[1] intValue];
        kPos = [tokens[2] intValue];
        kLen = [tokens[3] intValue];
        bPos = [tokens[4] intValue];
        bLen = [tokens[5] intValue];
        vPos = [tokens[6] intValue];
    }
    return self;
}

- (void)awakeFromNib
{
    int     idx = 0;
    NSError *error;
    [accountsController fetchWithRequest: nil merge: NO error: &error];

    if (account) {
        for (BankAccount *acc in [accountsController arrangedObjects]) {
            if (acc == account) {
                [comboBox selectItemAtIndex: idx];
                break;
            } else {idx++; }
        }
        [self getStatements];
    }
}

- (void)windowWillClose: (NSNotification *)aNotification
{
    [NSApp stopModalWithCode: actionResult];
}

- (IBAction)cancel: (id)sender
{
    actionResult = 0;
    [self close];
}

- (IBAction)ok: (id)sender
{
    NSError *error = nil;

    NSInteger res = NSRunAlertPanel(NSLocalizedString(@"AP102", nil),
                                    NSLocalizedString(@"AP103.a", nil),
                                    NSLocalizedString(@"AP4", nil),
                                    NSLocalizedString(@"AP3", nil),
                                    nil);

    if (res == NSAlertAlternateReturn) {
        for (PurposeSplitData *data in [purposeController arrangedObjects]) {
            if (data.statement.additional == nil) {
                data.statement.additional = data.statement.purpose;
            }
            if (data.purposeNew) {
                data.statement.purpose = data.purposeNew;
            }
            if (data.remoteName) {
                data.statement.remoteName = data.remoteName;
            }
            if (data.remoteAccount) {
                data.statement.remoteAccount = data.remoteAccount;
            }
            if (data.remoteBankCode) {
                data.statement.remoteBankCode = data.remoteBankCode;
            }
        }
        // save conversion rule
        account.splitRule = [NSString stringWithFormat: @"%d:%d,%d,%d,%d,%d,%d,%d", 1, ePos, eLen, kPos, kLen, bPos, bLen, vPos];

        // save updates
        if ([context save: &error] == NO) {
            NSAlert *alert = [NSAlert alertWithError: error];
            [alert runModal];
            return;
        }

        actionResult = 0;
        [self close];
    }
}

- (IBAction)comboChanged: (id)sender
{
    NSInteger idx = [comboBox indexOfSelectedItem];
    if (idx < 0) {
        idx = 0;
    }
    BankAccount *acc = [accountsController arrangedObjects][idx];
    if (acc) {
        account = acc;
        // fetch new statements
        [self getStatements];
    }
}

- (void)getStatements
{
    if (account) {
        [purposeController removeObjects: [purposeController arrangedObjects]];
        for (BankStatement *stat in [account mutableSetValueForKey : @"statements"]) {
            PurposeSplitData *data = [[PurposeSplitData alloc] init];
            if (stat.additional) {
                // data already converted
                data.purposeOld = stat.additional;
                data.converted = YES;
            } else {
                data.purposeOld = stat.purpose;
            }

            data.remoteName = stat.remoteName;
            data.remoteAccount = stat.remoteAccount;
            data.remoteBankCode = stat.remoteBankCode;
            data.statement = stat;
            [purposeController addObject: data];
        }
    }
}

- (void)calculate: (id)sender
{
    NSRange eRange;
    NSRange kRange;
    NSRange bRange;

    eRange.location = ePos;
    eRange.length = eLen;
    kRange.location = kPos;
    kRange.length = kLen;
    bRange.location = bPos;
    bRange.length = bLen;

    [[sender window] makeFirstResponder: nil];

    for (PurposeSplitData *data in [purposeController arrangedObjects]) {
        if (eRange.length) {
            data.remoteName = [[data.purposeOld substringWithRange: eRange] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
        }
        if (kRange.length) {
            data.remoteAccount = [[data.purposeOld substringWithRange: kRange] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
        }
        if (bRange.length) {
            data.remoteBankCode = [[data.purposeOld substringWithRange: bRange] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
        }
        if (vPos) {
            data.purposeNew = [[data.purposeOld substringFromIndex: vPos] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
        } else {data.purposeNew = data.purposeOld; }
    }
}

@end
