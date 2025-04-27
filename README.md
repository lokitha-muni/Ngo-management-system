# NGO Management System

The **NGO Management System** is a database project designed to help NGOs efficiently manage their core activities like volunteer information, donation tracking, event management, and beneficiary records.  
It is built entirely using **SQL** and is structured for easy integration into larger systems if needed.

## 📚 Features
- Manage volunteer registration and information
- Track donations from donors
- Organize and manage events
- Maintain records of beneficiaries

## 🛠️ Technologies Used
- MySQL / PostgreSQL (any SQL database)

## 🗄️ Database Structure
- Volunteers Table
- Donors Table
- Donations Table
- Events Table
- Beneficiaries Table
- Event Participation Table

## 🗺️ ER Diagram
![ER Diagram](ER- Diagram.md)


## 🚀 Setup Instructions
1. Clone the repository.
2. Import the `database/schema.sql` file into your SQL database server.
3. (Optional) Import `database/insert_data.sql` to populate with sample data.
4. You can use `database/queries.sql` for important queries like generating reports.

```bash
git clone https://github.com/lokitha-muni/ngo-management-system.git
