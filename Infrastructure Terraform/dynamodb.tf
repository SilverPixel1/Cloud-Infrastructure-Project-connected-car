#######################################################################################################################
#Build the Infrastructure for the Project: DynamoDB, um die Sensordaten zu speichern
#######################################################################################################################

# DynamoDB ist die NoSQL Datenbank von AWS (schnell, skalierbar, serverless)
# daten sind hochfrequent, da die Sensoren kontinuierlich Daten senden, daher ist DynamoDB eine gute Wahl
# unregelmäßige Schreiblast, da die Sensoren nicht immer gleichmäßig Daten senden, DynamoDB passt sich automatisch an die Last an
# unterschiedlich große Daten, da die Sensoren verschiedene Arten von Daten senden können, DynamoDB ist flexibel und kann mit verschiedenen Datentypen umgehen
# on demand billing, serverless, unendlich Skalierbar, hohe Verfügbarkeit, integrierte Sicherheit, einfache Verwaltung
# passt perfekt zu Kinesis und ECS

resource "aws_dynamodb_table" "road_conditions" {
  name           = "${var.project_name}-road-conditions-table"
  billing_mode   = "PAY_PER_REQUEST" # On-Demand Abrechnung

  hash_key       = "region"        # Primärschlüssel
  range_key      = "timestamp"        # Sortierschlüssel

  attribute {
    name = "region"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "N"
  }

  tags = {
    Name        = "${var.project_name}-road-conditions-table"
    Environment = "Development"
    Project     = var.project_name
  }
}

# output the table name for use in other resources
output "dynamodb_table_name" {
  value = aws_dynamodb_table.road_conditions.name
}

