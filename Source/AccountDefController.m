/**
 * Copyright (c) 2008, 2015, Pecunia Project. All rights reserved.
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

#import "AccountDefController.h"
#import "BankAccount.h"
#import "MOAssistant.h"
#import "BankUser.h"
#import "BankingController.h"

#import "BWGradientBox.h"

#define HEIGHT_MANUAL   550
#define HEIGHT_STANDARD 530

@implementation AccountDefController

- (id)init
{
    self = [super initWithWindowNibName: @"AccountCreate"];
    moc = [[MOAssistant sharedAssistant] memContext];

    account = [NSEntityDescription insertNewObjectForEntityForName: @"BankAccount" inManagedObjectContext: moc];
    account.currency = @"EUR";
    account.country = @"DE";
    account.name = @"Neues Konto";
    success = NO;
    return self;
}

- (void)setBankCode: (NSString *)code name: (NSString *)name
{
    account.bankCode = code;
    account.bankName = name;
}

- (void)setHeight: (int)h
{
    NSWindow *window = [self window];
    NSRect   frame = [window frame];
    int      pos = frame.origin.y + frame.size.height;
    frame.size.height = h;
    frame.origin.y = pos - h;
    [window setFrame: frame display: YES animate: YES];
}

- (void)awakeFromNib
{
    [[self window] center];

    int            i = 0;
    NSMutableArray *hbciUsers = [NSMutableArray arrayWithArray: [BankUser allUsers]];
    // add special User
    BankUser *noUser  = [NSEntityDescription insertNewObjectForEntityForName: @"BankUser" inManagedObjectContext: moc];
    noUser.name = NSLocalizedString(@"AP813", nil);
    [hbciUsers insertObject: noUser atIndex: 0];

    [users setContent: hbciUsers];
    // now find first user that fits bank code and change selection
    if (account.bankCode) {
        for (BankUser *user in hbciUsers) {
            if ([user.bankCode isEqual: account.bankCode]) {
                [dropDown selectItemAtIndex: i];
                break;
            }
            i++;
        }
    }
    currentAddView = accountAddView;
    [predicateEditor addRow: self];

    // fill proposal values
    [self dropChanged: self];
    
    // Manually set up properties which cannot be set via user defined runtime attributes
    // (Color type is not available pre 10.7).
    topGradient.fillStartingColor = [NSColor colorWithCalibratedWhite: 59 / 255.0 alpha: 1];
    topGradient.fillEndingColor = [NSColor colorWithCalibratedWhite: 99 / 255.0 alpha: 1];
    backgroundGradient.fillColor = [NSColor whiteColor];
}

- (IBAction)dropChanged: (id)sender
{
    NSInteger idx = [dropDown indexOfSelectedItem];
    if (idx < 0) {
        idx = 0;
    }
    BankUser *user = [users arrangedObjects][idx];

    if (idx > 0) {
        account.bankName = user.bankName;
        account.bankCode = user.bankCode;
        InstituteInfo *info = [[HBCIBackend backend] infoForBankCode: user.bankCode];
        if (info) {
            account.bic = info.bic;
            account.bankName = info.name;
        }

        [bankCodeField setEditable: NO];
        //[bankCodeField setBezeled: NO ];

        if (currentAddView != accountAddView) {
            [self setHeight: HEIGHT_STANDARD];
            NSRect frame = [manAccountAddView frame];
            [boxView replaceSubview: manAccountAddView with: accountAddView];
            currentAddView = accountAddView;
            [currentAddView setFrame: frame];
        }
    } else {
        [bankCodeField setEditable: YES];
        //[bankCodeField setBezeled: YES ];

        if (currentAddView != manAccountAddView) {
            [self setHeight: HEIGHT_MANUAL];
            NSRect frame = [accountAddView frame];
            [boxView replaceSubview: accountAddView with: manAccountAddView];
            currentAddView = manAccountAddView;
            [currentAddView setFrame: frame];
        }
        
        // propose account number
        if (account.accountNumber == nil) {
            account.accountNumber = [BankAccount findFreeAccountNumber];
            [accountNumberField setStringValue:account.accountNumber];            
        }
    }
}

- (void)windowWillClose: (NSNotification *)notification
{
    if (success) {
        [NSApp stopModalWithCode: 1];
    } else {
        [NSApp stopModalWithCode: 0];
    }
}

- (IBAction)cancel: (id)sender
{
    if ([NSColorPanel sharedColorPanelExists]) {
        [[NSColorPanel sharedColorPanel] close];
    }

    [moc reset];
    [self close];
}

- (IBAction)ok: (id)sender
{
    if ([NSColorPanel sharedColorPanelExists]) {
        [[NSColorPanel sharedColorPanel] close];
    }

    [accountController commitEditing];
    if (![self check]) {
        return;
    }
    NSManagedObjectContext *context = [[MOAssistant sharedAssistant] context];

    BankUser *user = nil;
    NSInteger idx = [dropDown indexOfSelectedItem];
    if (idx > 0) {
        user = [users arrangedObjects][idx];
    }

    // account is new - create entity in productive context
    BankAccount *bankRoot = [BankAccount bankRootForCode: account.bankCode];
    if (bankRoot == nil) {
        BankingCategory *root = [BankingCategory bankRoot];
        if (root != nil) {
            // create root for bank
            bankRoot = [NSEntityDescription insertNewObjectForEntityForName: @"BankAccount" inManagedObjectContext: context];
            bankRoot.bankName = account.bankName;
            bankRoot.name = account.bankName;
            bankRoot.bankCode = account.bankCode;
            bankRoot.currency = account.currency;
            bankRoot.country = account.country;
            bankRoot.bic = account.bic;
            bankRoot.isBankAcc = @YES;
            // parent
            bankRoot.parent = root;
        } else {bankRoot = nil; }
    }
    // insert account into hierarchy
    if (bankRoot) {
        // account is new - create entity in productive context
        newAccount = [NSEntityDescription insertNewObjectForEntityForName: @"BankAccount" inManagedObjectContext: context];
        newAccount.bankCode = account.bankCode;
        newAccount.bankName = account.bankName;
        if (user) {
            newAccount.isManual = @NO;
            newAccount.userId = user.userId;
            newAccount.customerId = user.customerId;
            newAccount.collTransferMethod = account.collTransferMethod;
            newAccount.isStandingOrderSupported = account.isStandingOrderSupported;
        } else {
            newAccount.isManual = @YES;
            newAccount.balance = account.balance;
            NSPredicate *predicate = [predicateEditor objectValue];
            if (predicate) {
                newAccount.rule = [predicate description];
            }
        }

        newAccount.parent = bankRoot;
        newAccount.isBankAcc = @YES;
    }

    if (newAccount) {
        // update common data
        newAccount.iban = account.iban;
        newAccount.bic = account.bic;
        newAccount.owner = account.owner;
        newAccount.accountNumber = account.accountNumber;         //?
        newAccount.name = account.name;
        newAccount.currency = account.currency;
        newAccount.country = account.country;
        newAccount.catRepColor = account.catRepColor;
        newAccount.isHidden = account.isHidden;
        newAccount.noCatRep = account.noCatRep;
    }

    // save all
    NSError *error = nil;
    if ([context save: &error] == NO) {
        NSAlert *alert = [NSAlert alertWithError: error];
        [alert runModal];
    }

    [moc reset];
    success = YES;
    [self close];
}

- (void)controlTextDidEndEditing: (NSNotification *)aNotification
{
    NSTextField *te = [aNotification object];

    if ([te tag] == 100) {
        BOOL        wasEditable = [bankNameField isEditable];
        BankAccount *bankRoot = [BankAccount bankRootForCode: [te stringValue]];
        [bankNameField setEditable: NO];
        if (bankRoot == nil) {
            NSString *name = [[HBCIBackend backend] bankNameForCode: [te stringValue]];
            if ([name isEqualToString: NSLocalizedString(@"AP13", nil)]) {
                [bankNameField setEditable: YES];
                if (wasEditable == NO || account.bankName == nil) {
                    account.bankName = name;
                }
            } else { account.bankName = name; }
        } else {
            account.bankName = bankRoot.name;
        }
    }
}

- (IBAction)predicateEditorChanged: (id)sender
{
    //	if(awaking) return;
    // check NSApp currentEvent for the return key
    NSEvent *event = [NSApp currentEvent];
    if ([event type] == NSKeyDown) {
        NSString *characters = [event characters];
        if ([characters length] > 0 && [characters characterAtIndex: 0] == 0x0D) {
            /*
             [self calculateCatAssignPredicate ];
             ruleChanged = YES;
             */
        }
    }
    // if the user deleted the first row, then add it again - no sense leaving the user with no rows
    if ([predicateEditor numberOfRows] == 0) {
        [predicateEditor addRow: self];
    }
}

- (BOOL)check
{
    // Default currency.
    if ([account.currency isEqual: @""]) {
        account.currency = @"EUR";
    }

    if (account.accountNumber == nil) {
        NSRunAlertPanel(NSLocalizedString(@"AP50", nil),
                        NSLocalizedString(@"AP55", nil),
                        NSLocalizedString(@"AP1", nil), nil, nil);
        return NO;
    }

    if (account.bankCode == nil) {
        NSRunAlertPanel(NSLocalizedString(@"AP50", nil),
                        NSLocalizedString(@"AP56", nil),
                        NSLocalizedString(@"AP1", nil), nil, nil);
        return NO;
    }

    // For manual accounts we don't need a valid account number, bank code or IBAN.
    if (dropDown.indexOfSelectedItem == 0) {
        return YES;
    }

    if (![IBANtools isValidIBAN: account.iban]) {
        NSRunAlertPanel(NSLocalizedString(@"AP59", nil),
                        NSLocalizedString(@"AP70", nil),
                        NSLocalizedString(@"AP61", nil), nil, nil);
        return NO;
    }

    NSDictionary *checkResult = [IBANtools isValidAccount: account.accountNumber
                                                 bankCode: account.bankCode
                                              countryCode: @"DE"
                                                  forIBAN: NO];
    BOOL valid = checkResult && [[checkResult valueForKey:@"valid"] boolValue];
    if (!valid) {
        NSRunAlertPanel(NSLocalizedString(@"AP59", nil),
                        NSLocalizedString(@"AP60", nil),
                        NSLocalizedString(@"AP61", nil), nil, nil);
        return NO;
    }

    return YES;
}

@end
