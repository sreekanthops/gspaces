#!/bin/bash

# Test script for quotation feedback API
# Share token: Ms0jiVaHB-8b-muRFOe4TQ

echo "=========================================="
echo "Testing Quotation Feedback API"
echo "=========================================="

# First, get the lead_id from the share token
echo ""
echo "Step 1: Getting lead_id from share token..."
LEAD_ID=$(psql -U sri -d gspaces -t -c "SELECT id FROM leads WHERE share_token = 'Ms0jiVaHB-8b-muRFOe4TQ';")
LEAD_ID=$(echo $LEAD_ID | xargs)  # Trim whitespace

if [ -z "$LEAD_ID" ]; then
    echo "ERROR: Could not find lead with share token Ms0jiVaHB-8b-muRFOe4TQ"
    exit 1
fi

echo "Found lead_id: $LEAD_ID"

# Test submitting feedback
echo ""
echo "Step 2: Testing feedback submission..."
echo "Submitting: Rating=5, Message='Test feedback from curl'"

RESPONSE=$(curl -s -X POST https://gspaces.in/api/submit-quotation-feedback \
  -F "lead_id=$LEAD_ID" \
  -F "rating=5" \
  -F "message=Test feedback from curl command")

echo "Response: $RESPONSE"

# Check if it was successful
if echo "$RESPONSE" | grep -q '"success":true'; then
    echo "✓ Feedback submitted successfully!"
else
    echo "✗ Feedback submission failed"
fi

# Verify in database
echo ""
echo "Step 3: Verifying in database..."
psql -U sri -d gspaces -c "SELECT id, customer_name, customer_rating, customer_feedback, feedback_submitted_at FROM leads WHERE id = $LEAD_ID;"

echo ""
echo "=========================================="
echo "Test Complete"
echo "=========================================="

# Made with Bob
