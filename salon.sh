#! /bin/bash

PSQL="psql -X --username=freecodecamp --dbname=salon --no-align --tuples-only -c"

# Print header and welcome message exactly as in the examples
echo "~~~~~ MY SALON ~~~~~"
echo ""
echo "Welcome to My Salon, how can I help you?"
echo ""

# Function to display the services list in the required format
display_services() {
  # Retrieve service_id and name sorted by service_id
  SERVICES_LIST=$($PSQL "select service_id, name from services order by service_id;")
  echo "$SERVICES_LIST" | while IFS='|' read SERVICE_ID SERVICE_NAME
  do
    echo "$SERVICE_ID) $SERVICE_NAME"
  done
}

# Display services and prompt for a service id
display_services
read SERVICE_ID_SELECTED

# Loop until a valid numeric service id is provided AND it exists in the services table
while [[ ! $SERVICE_ID_SELECTED =~ ^[0-9]+$ ]] || [[ $($PSQL "select count(*) from services where service_id = $SERVICE_ID_SELECTED") -eq 0 ]]
do
  echo ""
  echo "I could not find that service. What would you like today?"
  display_services
  read SERVICE_ID_SELECTED
done

# Get the service name for later use
SERVICE_NAME=$($PSQL "select name from services where service_id = $SERVICE_ID_SELECTED" | sed 's/^[ \t]*//;s/[ \t]*$//')

# Ask for phone number
echo ""
echo "What's your phone number?"
read CUSTOMER_PHONE

# Check if the customer exists; if not, ask for the customer's name
if [[ $($PSQL "select count(*) from customers where phone = '$CUSTOMER_PHONE'") -eq 0 ]]
then
  echo ""
  echo "I don't have a record for that phone number, what's your name?"
  read CUSTOMER_NAME
  # Insert the new customer
  INSERT_CUSTOMER_RESULT=$($PSQL "insert into customers (phone, name) values ('$CUSTOMER_PHONE', '$CUSTOMER_NAME');")
else
  # Retrieve the customer's name
  CUSTOMER_NAME=$($PSQL "select name from customers where phone = '$CUSTOMER_PHONE'")
fi

# Prompt for appointment time using the service name and customer's name in the prompt
echo ""
echo "What time would you like your $SERVICE_NAME, $CUSTOMER_NAME?"
read SERVICE_TIME

# Insert the appointment into the appointments table
# (Assuming that the appointments table's time column is VARCHAR)
CUSTOMER_ID=$($PSQL "select customer_id from customers where phone = '$CUSTOMER_PHONE'")
INSERT_APPOINTMENT_RESULT=$($PSQL "insert into appointments (customer_id, service_id, time) values ('$CUSTOMER_ID', '$SERVICE_ID_SELECTED', '$SERVICE_TIME');")

echo ""
echo "I have put you down for a $SERVICE_NAME at $SERVICE_TIME, $CUSTOMER_NAME."
