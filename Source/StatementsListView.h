/**
 * Copyright (c) 2011, 2014, Pecunia Project. All rights reserved.
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

#import "StatementsListViewCell.h"
#import "PecuniaListView.h"

@class StatCatAssignment;

@protocol StatementsListViewProtocol
@optional
- (void)activationChanged: (BOOL)active forIndex: (NSUInteger)index;
- (void)actionForCategory: (StatCatAssignment *)assignment action: (StatementMenuAction)action;
@end;

@interface StatementsListView : PecuniaListView <PXListViewDelegate, StatementsListViewNotificationProtocol>

@property (nonatomic, assign) BOOL    showAssignedIndicators;
@property (nonatomic, assign) BOOL    disableSelection;
@property (nonatomic, assign) BOOL    canShowHeaders; // Headers can be switched off temporarily.

- (void)updateVisibleCells;
- (void)activateCells;

@end
