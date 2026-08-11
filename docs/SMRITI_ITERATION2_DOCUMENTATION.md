# Smriti Lama - Iteration 2 Documentation

This document covers the documentation tasks assigned to Smriti in the TAC while keeping production-code ownership separate from teammates' responsibilities.

## D5 (M4) - Listing-management functionality

The listing-management workflow allows a donor to view active listings, select one, edit its information, or remove it. The user interface should be pre-filled with the current listing data. Only active listings should be editable. When a backend update or removal succeeds, the UI must immediately refresh so stale listing information is not shown. Error messages should be shown when an expired or otherwise invalid listing cannot be edited.

Expected flow: Donor Home -> My Listings -> Select active listing -> Edit/Remove -> Backend operation -> Refresh current listing data -> Show success/error feedback.

## R7 (S6) - Recipient messaging functionality

The recipient messaging flow displays messages sent by donors, preserves conversation history, and distinguishes unread/read messages. Conversation data is supplied by the messaging API/database components owned by the relevant teammates; Smriti's UI support displays the resulting history and can be reused inside an inbox/message-details screen.

Expected flow: Recipient Dashboard -> Inbox -> Select conversation -> Display conversation history -> Read message -> Existing unread-state logic marks it read.

## A2 (S9) - Incident-reporting functionality

The incident-report flow allows an administrator to submit a technical issue for the development team. The screen/validation/backend/database components are split across team members. Smriti's incident-report coordinator handles the final submission result and user feedback while avoiding duplication of teammates' API and database tasks.

Expected flow: Admin Dashboard -> Incident Report -> Enter incident details -> Validate -> Submit to backend -> Save to database -> Show success/error feedback.

## Merge-conflict rule

All Smriti Iteration 2 production files are placed under `frontend/lib/smriti_iteration2/`. This avoids editing shared screens until the owning developer is ready to integrate them. Tests are under `frontend/test/smriti_iteration2/`.
