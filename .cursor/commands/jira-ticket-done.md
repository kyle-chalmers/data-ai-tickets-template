# Mark Ticket Done

Transitions a Jira ticket to Done status.

**Argument**: The ticket key. If the user types text after `/jira-ticket-done`, that is the ticket key (e.g., `/jira-ticket-done DATA-123`).

## Instructions

Delegate to @jira-ticket-transitioner to transition the specified ticket to Done status. Extract the ticket key from the user's input (text after the command). If no ticket key is provided, ask the user for it.
