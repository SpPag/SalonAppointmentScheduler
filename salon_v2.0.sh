#! /bin/bash

# Function to check if input is a valid number
isNumber() {
    [[ "$1" =~ ^[0-9]+$ ]]
}

isValidPhone() {
    [[ "$1" =~ ^[0-9]{3}-[0-9]{3}-[0-9]{4}$ ]]
}

echo -e "\n~~~~~ MY SALON ~~~~~\n"
echo -e "Welcome to My Salon, how can I help you?\n"
while true
do
  echo -e "Here's a list of our available services:"
  PSQL="psql -X --username=freecodecamp --dbname=salon --no-align --tuples-only -c"
  echo "$($PSQL "select * from services;")" | while IFS='|' read service_id service_name
  do
    echo "$service_id) $service_name"
  done

  read SERVICE_ID_SELECTED
  while [[ ! $SERVICE_ID_SELECTED =~ ^[0-9]+$ ]]
  do
    echo "Please enter a number to select the respective service: "
    read SERVICE_ID_SELECTED
  done

  if [[ $($PSQL "select count(*) from services where service_id = $SERVICE_ID_SELECTED") -eq 0 ]]
  # can do the following instead, but it unnecessarily retrieves data
  # if [[ -z $($PSQL "select service_id from services where service_id = $SERVICE_ID_SELECTED") ]]
    then
    echo -e "There is no service with that number.\n"
    else
    userService=$($PSQL "select name from services where service_id = $SERVICE_ID_SELECTED" | sed 's/^[ \t]*//;s/[ \t]*$//')
    echo -e "You've opted for a $userService!\n"
    echo -e "What's your phone number?\n"
    read CUSTOMER_PHONE
    while ! isValidPhone "$CUSTOMER_PHONE"
    do
      echo -e "Please enter your phone number, following the format XXX-XXX-XXXX:"
      read CUSTOMER_PHONE
    done
    if [[ $($PSQL "select count(*) from customers where phone = '$CUSTOMER_PHONE'") -eq 0 ]]
      then
      echo -e "I see you're a new customer, welcome! What's your name?"
      read CUSTOMER_NAME
      # checking if the user provided only whitespaces 
      while [[ "$CUSTOMER_NAME" =~ ^[[:space:]]*$ ]]
      do
        echo -e "Please enter your name (just first name is fine):"
        read CUSTOMER_NAME
      done
      CUSTOMER_NAME=$(echo "$CUSTOMER_NAME" | sed 's/^[ \t]*//;s/[ \t]*$//')
      INSERT_CUSTOMER_RESULT=$($PSQL "insert into customers (phone, name) values ('$CUSTOMER_PHONE', '$CUSTOMER_NAME');")
    fi
    CUSTOMER_NAME=$($PSQL "select name from customers where phone = '$CUSTOMER_PHONE'")
    CUSTOMER_ID=$($PSQL "select customer_id from customers where phone = '$CUSTOMER_PHONE'")
    echo -e "\nWhat time should I book your $userService appointment for, $CUSTOMER_NAME? Please use the following format 17:30:\n"
    read SERVICE_TIME
    while [[ ! $SERVICE_TIME =~ ^([01]?[0-9]|2[0-3]):([0-5][0-9])$ ]] 
    do
      echo -e "Please provide a time following the format 17:30:\n"
      read SERVICE_TIME
    done
    INSERT_APPOINTMENT_RESULT=$($PSQL "insert into appointments (customer_id, service_id, time) values ('$CUSTOMER_ID', '$SERVICE_ID_SELECTED', '$SERVICE_TIME')")
    # echo "Your $userService appointment has been booked for $SERVICE_TIME, $CUSTOMER_NAME! See you then!"
    echo "I have put you down for a $userService at $SERVICE_TIME, $CUSTOMER_NAME"
  fi
  echo "Type 'exit' to quit, or press Enter to continue."
  read exitInput
  if [[ "$exitInput" == "exit" ]]
    then
    break
  fi
done
