# Daily Purchase Rate (DPR) Service

## Overview

The Daily Purchase Rate (DPR) is a financial metric designed to help users manage their daily spending by providing a recommended maximum daily spending amount. Unlike a fixed budget, the DPR dynamically adjusts based on:

1. How much of the monthly budget has already been spent
2. Upcoming recurring expenses that still need to be paid
3. Number of days remaining in the financial month

## Formula

The DPR is calculated using the following formula:

```
DPR = (Remaining Budget - Upcoming Recurring Expenses) / Days Remaining in Month
```

Where:
- **Remaining Budget** = Monthly Budget Goal - Total Already Spent
- **Upcoming Recurring Expenses** = Sum of all recurring expenses yet to occur in the current month
- **Days Remaining** = Number of days left until the end of the financial month

## Purpose

The DPR serves several important purposes:

1. **Prevents Overspending**: By dynamically adjusting based on actual spending patterns, it helps prevent users from overspending early in the month.

2. **Accounts for Recurring Expenses**: Unlike simple budget division (Budget ÷ Days in Month), the DPR reserves money for upcoming recurring expenses like rent, subscriptions, and bills.

3. **Adapts to Reality**: If a user makes a large unplanned purchase, the DPR immediately adjusts downward to compensate, helping the user stay within their overall budget.

4. **Simplifies Decision Making**: Instead of constantly recalculating how much they can spend, users have a simple daily target to guide purchasing decisions.

## Implementation Details

### Key Components

1. **BudgetDataService**: Provides the monthly budget goal and current spending data.
2. **DatabaseHelper**: Retrieves transaction data and recurring expense information.
3. **MonthSettings**: Determines the custom financial month start date.

### Process Flow

1. **Calculate Current Month Range**: Based on the user's custom financial month settings.
2. **Determine Total Spent**: Sum all expenses in the current month period.
3. **Calculate Remaining Budget**: Subtract total spent from the monthly budget goal.
4. **Identify Upcoming Recurring Expenses**: 
   - Get all recurring expense definitions
   - Determine how many instances should occur in the current month
   - Subtract instances that have already occurred
   - Calculate the total cost of remaining instances
5. **Calculate Available Funds**: Subtract upcoming recurring expenses from remaining budget.
6. **Divide by Days Remaining**: Determine the daily allocation.

### Handling Edge Cases

- **Zero or Negative Remaining Budget**: If the user has spent their entire budget (or overspent), the DPR returns 0.
- **End of Month**: As the month progresses, the denominator decreases, potentially increasing the DPR if spending has been below budget.
- **Custom Month Start Date**: The service respects custom financial month start dates (e.g., if your "month" runs from the 15th to the 14th).

## Usage Examples

### Conservative Spending

Let's say a user has:
- Monthly Budget: $3000
- Already Spent: $1500
- Upcoming Rent: $1000
- Days Remaining: 15

Their DPR would be: ($3000 - $1500 - $1000) / 15 = $33.33 per day

### Early Month Planning

At the beginning of the month:
- Monthly Budget: $3000
- Already Spent: $0
- Upcoming Recurring Expenses: $1200 (rent + utilities + subscriptions)
- Days Remaining: 30

Their DPR would be: ($3000 - $0 - $1200) / 30 = $60 per day

### Overspending Scenario

If a user makes a large unplanned purchase:
- Monthly Budget: $3000
- Already Spent: $2800 (including a $2000 emergency repair)
- Upcoming Recurring Expenses: $300
- Days Remaining: 10

Their DPR would drop to: ($3000 - $2800 - $300) / 10 = -$10 per day (displayed as $0)

This indicates they need to avoid all discretionary spending for the remainder of the month.

## Caching and Performance

The DPR service includes caching to optimize performance:
- Results are cached for 5 seconds before recalculating
- Force refresh can be triggered when needed (e.g., after adding new transactions)

## Future Enhancements

Potential improvements to consider:
1. Personalized spending categories with category-specific DPRs
2. Weekly rather than daily rate for some users
3. Machine learning to predict variable recurring expenses
4. Different DPR calculations for weekdays vs. weekends
5. Savings goal integration to gradually increase savings rate

## Technical Notes

The DPR calculation uses a multi-step approach to ensure accuracy:
1. Careful identification of recurring transactions already paid vs upcoming
2. Precise calculation of days remaining considering month length variations
3. Error handling to ensure graceful degradation if data is unavailable