#!/bin/bash

PSQL="psql -X --username=postgres --dbname=salon --tuples-only --no-align -c"

# Display the services before the first prompt.
show_services() {
  SERVICES=$($PSQL "SELECT service_id, name FROM services ORDER BY service_id;")
  echo "$SERVICES" | while IFS='|' read -r SERVICE_ID SERVICE_NAME; do
    if [[ -n "$SERVICE_ID" ]]; then
      echo "$SERVICE_ID) $SERVICE_NAME"
    fi
  done
}

echo "~~~~~ MY SALON ~~~~~"
echo
show_services

echo
printf "Please enter the service ID: "
read SERVICE_ID_SELECTED

# If the service does not exist, show the same service list again and ask again.
while true; do
  SERVICE_NAME=$($PSQL "SELECT name FROM services WHERE service_id = $SERVICE_ID_SELECTED;" 2>/dev/null | xargs)

  if [[ -n "$SERVICE_NAME" ]]; then
    break
  fi

  echo
  show_services
  echo
  printf "Please enter the service ID: "
  read SERVICE_ID_SELECTED
done

echo
printf "Please enter your phone number: "
read CUSTOMER_PHONE

CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone = '$CUSTOMER_PHONE';" | xargs)

if [[ -z "$CUSTOMER_ID" ]]; then
  printf "Please enter your name: "
  read CUSTOMER_NAME

  $PSQL "INSERT INTO customers(name, phone) VALUES('$CUSTOMER_NAME', '$CUSTOMER_PHONE');" >/dev/null
  CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone = '$CUSTOMER_PHONE';" | xargs)
else
  CUSTOMER_NAME=$($PSQL "SELECT name FROM customers WHERE customer_id = $CUSTOMER_ID;" | xargs)
fi

printf "Please enter your appointment time: "
read SERVICE_TIME

$PSQL "INSERT INTO appointments(customer_id, service_id, time) VALUES($CUSTOMER_ID, $SERVICE_ID_SELECTED, '$SERVICE_TIME');" >/dev/null

echo "I have put you down for a $SERVICE_NAME at $SERVICE_TIME, $CUSTOMER_NAME."
