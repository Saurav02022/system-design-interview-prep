# Chat Messaging System

## Problem

Design the database part of a simple one-to-one chat messaging system.

## Features

- Users can create one-to-one conversations.
- Users can send messages inside a conversation.
- Users can read latest messages in a conversation.
- Users can see their conversation list.
- Users can see the latest message preview.
- Users can mark a conversation as read.

## Scale

- 5 million users
- 50 million one-to-one conversations
- 500 million messages per month
- High write traffic during peak hours
- Most users open recent conversations more than old conversations

## Common Reads

- Conversation list for one user
- Latest messages inside one conversation
- Latest message preview for a conversation
- Unread count for one conversation
- Read position for one user inside one conversation

## Out of Scope

- Group chat
- Voice and video calls
- Media file storage
- End-to-end encryption
- Push notification system
- Online and offline presence
- Blocking users

## What This Problem Tests

- SQL vs NoSQL thinking
- Modeling one-to-one conversations
- Message table design
- Read/unread design
- Indexes for latest messages
- Transactions for sending a message
- Cache and read replica decisions
- Partitioning a fast-growing table
- Sharding decision at high scale
