# Connected Car – Cloud Infrastructure Project
 
 ## Motivation & Origin
 
 Die Idee zu diesem Projekt entstand durch die Analyse einer Stellenanzeige im Bereich Cloud Engineering,
 in der ein Kunde aus dem Umfeld **Connected Car Services** beschrieben wurde.
 
 Die Aufgabe bestand darin, Sensordaten aus Fahrzeugen zu sammeln, zu vernetzen und auszuwerten,
 um sicherheitsrelevante Informationen wie Glätte oder Nässe in nahezu Echtzeit anderen Verkehrsteilnehmern
 zur Verfügung zu stellen.
 
 Ziel dieses Projekts ist es, diese Anforderungen in einer **praxisnahen, aber reduzierten Cloud-Architektur**
 nachzubilden und dabei gängige Cloud- und DevOps-Technologien einzusetzen.
 
 ---
 
 ## Projektziel
 
 Dieses Projekt implementiert eine Cloud-basierte Mini-Version einer Connected-Car-Plattform:
 
 - Fahrzeuge senden anonymisierte Sensordaten (Position, Temperatur, Fahrbahnglätte)
 - Die Daten werden über eine skalierbare AWS-Architektur verarbeitet
 - Gefahrenlagen werden zusammengeführt und anderen Fahrzeugen bereitgestellt
 - Die Infrastruktur ist vollständig als **Infrastructure as Code (Terraform)** definiert
 - Anwendungen laufen containerisiert mit **Docker**
 - Deployments erfolgen automatisiert über **GitHub Actions (CI/CD)**
 
 ---
 
 ## Architektur-Überblick
 
 Die Lösung basiert auf einer eventgetriebenen Architektur:
 
 - Fahrzeugsimulatoren senden Sensordaten an eine API
 - Die API schreibt die Daten in einen Streaming-Dienst
 - Eine Verarbeitungskomponente führt relevante Ereignisse zusammen
 - Ergebnisse werden in Datenbanken und Storage-Systemen gespeichert
 - Andere Fahrzeuge können Warnungen abrufen
 
 Die Architektur ist hochverfügbar, skalierbar und orientiert sich an typischen AWS-Best-Practices.
 
 ---
 
 ## Technologie-Stack
 
 **Cloud & Infrastruktur**
 - AWS (VPC, ECS, S3, DynamoDB, Kinesis, IAM, CloudWatch)
 - Terraform (Infrastructure as Code)
 
 **Container & Runtime**
 - Docker
 - Amazon ECS (Fargate/EC2-backed)
 
 **CI/CD**
 - GitHub Actions
 
 **Application Layer**
 - Linux-basierte Container
 - REST APIs (z. B. FastAPI)
 - Event-basierte Datenverarbeitung
 
 ---
 
## 🏗️ Connected Car Cloud Plattform – Architektur

Dieses Diagramm zeigt den End-to-End Datenfluss und die Infrastruktur:

![Architektur Diagramm](Docs/architecture.png)
