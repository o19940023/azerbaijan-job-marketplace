# Bugfix Requirements Document

## Introduction

When an employer edits a job listing and attempts to make it urgent (acil ilan) by clicking the "complete" button (tamamaa basiyor), the application enters an infinite reload loop instead of completing the payment flow. This prevents employers from successfully upgrading their job listings to urgent status through the Epoint payment gateway.

The bug occurs in the payment flow which should follow this sequence:
1. Employer initiates urgent payment → Backend creates payment via `/api/createUrgentPayment`
2. User redirected to Epoint payment page in WebView
3. User completes payment → Epoint redirects to success/error URL
4. Epoint webhook calls `/api/urgentPaymentCallback` to update Firestore
5. App checks payment status via `/api/checkPaymentStatus`
6. WebView closes and user sees confirmation

The infinite reload suggests the WebView navigation logic is not properly detecting payment completion, causing the payment page to reload continuously.

## Bug Analysis

### Current Behavior (Defect)

1.1 WHEN employer completes payment on Epoint payment page THEN the WebView enters an infinite reload loop instead of closing

1.2 WHEN Epoint redirects to success URL (payment-success.html) THEN the WebView navigation delegate fails to detect the redirect and prevent navigation

1.3 WHEN Epoint redirects through intermediate pages (e.g., ClientHandler) THEN the WebView continues navigating without detecting payment completion

1.4 WHEN payment status check is triggered THEN the app may repeatedly call `/api/checkPaymentStatus` without proper completion handling

### Expected Behavior (Correct)

2.1 WHEN employer completes payment on Epoint payment page THEN the WebView SHALL detect the success redirect and close with result `true`

2.2 WHEN Epoint redirects to success URL (payment-success.html) THEN the WebView navigation delegate SHALL prevent further navigation and return success to the calling screen

2.3 WHEN Epoint redirects through intermediate pages (e.g., ClientHandler) THEN the WebView SHALL continue monitoring for final success/error URLs without causing infinite reloads

2.4 WHEN payment is successful THEN the app SHALL call `/api/checkPaymentStatus` once with proper timeout handling and update the job listing accordingly

2.5 WHEN WebView closes with success result THEN the app SHALL display success message and navigate back to the previous screen without additional reloads

### Unchanged Behavior (Regression Prevention)

3.1 WHEN payment is cancelled by user THEN the WebView SHALL CONTINUE TO close with result `false` and display cancellation message

3.2 WHEN payment fails due to card issues THEN the WebView SHALL CONTINUE TO detect error redirect and close with result `false`

3.3 WHEN network errors occur during payment THEN the app SHALL CONTINUE TO handle errors gracefully with appropriate error messages

3.4 WHEN backend webhook receives payment callback THEN Firestore SHALL CONTINUE TO be updated with `isUrgent: true` and `urgentUntil` timestamp

3.5 WHEN non-urgent job listings are created THEN the payment flow SHALL CONTINUE TO be bypassed and jobs created normally
