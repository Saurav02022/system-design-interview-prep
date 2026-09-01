# Ticket Booking System

## Problem Statement

Design the database part of a simple ticket booking system.

Users can browse events, see available seats for an event, select seats, book tickets, pay for the booking, and see their booking history.

Event organizers can see bookings and sold tickets for their events.

## Features

- Users can browse events.
- Users can see event details and available seats.
- Users can select seats and start a booking.
- Users can pay for a booking.
- Users can see their booking history.
- Organizers can see bookings for their events.

## Scale

- 1 million users
- 10,000 events
- 1 million seats total
- 100,000 bookings per day
- High traffic when booking opens for a popular event

100,000 bookings per day is about 1.2 bookings per second on average.

The real problem is not the average number. The hard part is the spike when many users try to book the same popular event at the same time.

## Common Reads

- Event details
- Available seats for an event
- User booking history
- Booking details
- Organizer event bookings

## Out Of Scope

- Seat map UI
- Payment gateway internals
- Notifications
- Ticket QR code generation
- Refunds
- Waitlist
- Recommendation system

## What This Problem Tests

- SQL schema design
- Primary keys and foreign keys
- Constraints
- Transactions and ACID
- Indexes from real queries
- Seat locking
- Cache and read replicas
- Partitioning
- Sharding

The main thing this problem tests is whether I can prevent two users from successfully booking the same seat.
