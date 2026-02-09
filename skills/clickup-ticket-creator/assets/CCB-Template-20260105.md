# Title:

*Please don't forget to set the expected due date and the priority according to the following base rule. Don't assign anyone in the 'assignee' section and don't change the already set 'triage' status.*
*Low - 2 weeks; Normal or High - 5 business days; Urgent - the same business day*

# **Description**

What should be done in this task.



# **Rationale**

Why the change is needed.

**Production change**

YES [ ]
NO [ ]

# **Impact**

How much of a trouble we are in if we were to fail.
HIGH May impact the business.
MEDIUM May impact the office (we can't work). Some sub-systems may fail.
LOW Very minor things may fail.
Write a value and a justification.



# **Risk**

How confident we are in the change (or rather the opposite).
HIGH The change is long, hard to test in UAT. We are not sure of the change. This is our first time doing it.
MEDIUM We have good confidence in the change. It was tested in UAT. The implementer in UAT is the same as prod.
LOW We have strong confidence in the change. We could reproduce in SIT/UAT easily. Production is an exact copy of UAT. This is a Business-As-Usual change.
Write a value and a justification.



# **UAT implementation**

A proof of a successful implementation in UAT (if possible). Proof could be: screenshot of console, screenshot of browser, copy-paste of command and result.
OK UAT implementation is done
In SIT There is not UAT, but there is a SIT, and the change was tested there.
No UAT There is no UAT, nor SIT, nor anything comparable to test the change.
N/A The request is such that UAT implementation doesn't make sense.



# **Procedure**

Commands/procedure used to implement the change.

- Action: <Commands>
    - Expect:


# **Verification**

Commands/procedure used to validate the change. Also explain what to look for in the output.
Example: `du -sh /var/log` . Expect: usage less than 20G.
An eyeballer should be able to execute this plan. The implementer should update the ticket with the output of the verification.



# **Rollback**

Commands/procedures used to rollback the change.
**Estimated rollback time**: x minutes, y hours
