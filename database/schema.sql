create database ngomanagement 

create table users
(
  user_id int primary key,
  name varchar(30) not null,
  Email varchar(30)  not null,
  phoneNumber int not null,
  role varchar(30) null
  )
 ALTER TABLE users ALTER COLUMN phoneNumber BIGINT;

create table volunteer(
    volunteer_id int primary key,
	name varchar(20) not null,
	contact_information bigint not null,
	skills varchar(20) not null,
	availability varchar(20) not null,
	assigned_projects varchar(20) not null
)
drop table volunteer;

create table donor(
	  donor_id int primary key,
	  name varchar(15) not null,
	  contact_information int not null,
	  donation_history varchar(20) not null,
	  preferred_cuses varchar(30) not null
)
 ALTER TABLE donor ALTER COLUMN contact_information BIGINT;
drop table donor;

	   create table beneficiary(
	     beneficiary_id bigint primary key,
		 name varchar(30) not null,
		 contact_information bigint not null,
		 type_of_support_received varchar(20) not null,
		 support_history varchar(20) not null
		 )
		 drop table beneficiary;

create table donation(
		 donation_id int primary key,
		 donor_id int foreign key references donor(donor_id),
		 amount bigint not null,
		 Date_ date not null,
		 payment_method varchar not null,
		 purpose varchar not null
		 )
		 drop table donation;
		 ALTER TABLE donation ALTER COLUMN purpose VARCHAR(100);
		 DELETE FROM donation WHERE LEN(payment_method) > 1;
		 SELECT * FROM donation;



CREATE TABLE expense (
    expense_id INT PRIMARY KEY,
    project_id INT FOREIGN KEY REFERENCES project(project_id),
    amount INT NOT NULL,
    date_ DATE NOT NULL,
    category VARCHAR(20) NOT NULL,
    paid_by VARCHAR(20) NOT NULL
);
		 ALTER TABLE expense ALTER COLUMN paid_by VARCHAR(100);
		 SELECT paid_by, LEN(paid_by) FROM expense;
		 DELETE FROM expense WHERE LEN(paid_by) > 1;
		 SELECT * FROM project WHERE project_id = 1;
		 drop table expense;
		 SELECT project_id FROM project;
		 SELECT COUNT(*) FROM project;

		  
create table resource(
		resource_id int primary key,
		name varchar(20) not null,
		type varchar(10) not null,
		quantity int not null,
		assigned_project varchar(20) not null
		)
		EXEC sp_help 'resource';
		ALTER TABLE resource ALTER COLUMN type VARCHAR(30);
		ALTER TABLE resource ALTER COLUMN name VARCHAR(50);
		ALTER TABLE resource ALTER COLUMN assigned_project VARCHAR(50);


 
create table project(
		 project_id int primary key,
		 name varchar(20) not null,
		 description varchar(20) not null,
		 start_date date not null,
		 end_date date not null,
		 budget int not null,
		 assigned_volunteer varchar(20) not null
		 )
		 ALTER TABLE project ALTER COLUMN name VARCHAR(50);
		 EXEC sp_help 'project';




create table campaign(
		 campaign_id int primary key,
		 name varchar(80) not null,
		 goal varchar(80) not null,
		 start_date date not null,
		 end_date date not null,
		 target_audience varchar(80) not null,
		 associated_project varchar(20) not null
		 )
		 drop table campaign;
		 EXEC sp_help 'campaign';
		 ALTER TABLE campaign ALTER COLUMN associated_project VARCHAR(50);



create table event(
		 event_id int primary key,
		 name varchar(80) not null,
		 date_ date not null,
		 location varchar(80) not null,
		 purpose varchar(80) not null,
		 associated_campaign  varchar(80) not null,
		 )
		 drop table event;

create table report(
		 report_id int primary key,
		 title varchar(100) not null,
		 date_ date not null,
		 associated_project varchar(100) not null,
		 summary varchar(100) not null,
		 prepared_by varchar(100) not null
		 )
		 drop table report;

create table newsletter(
		  newsletter_id int primary key,
		  title varchar(100) not null,
		  date_ date not null,
		  content varchar(100) not null,
		  sent_to varchar(100) not null
		  )
		  drop table newsletter;

        CREATE TABLE membership (
        membership_id INT PRIMARY KEY,
        user_id INT FOREIGN KEY REFERENCES users(user_id),
        type VARCHAR(100) NOT NULL,
        expiry_date DATE NOT NULL,
        benefits VARCHAR(100) NOT NULL
        );
        INSERT INTO users (user_id, name) VALUES
        (101, 'User1'), (102, 'User2'), .., (150, 'User50');

		   SELECT * FROM users WHERE user_id BETWEEN 101 AND 150;
		   SELECT name, object_name(parent_object_id) AS table_name, 
          object_name(referenced_object_id) AS referenced_table 
          FROM sys.foreign_keys 
          WHERE object_name(parent_object_id) = 'membership';
		  ALTER TABLE membership NOCHECK CONSTRAINT ALL;

		   EXEC sp_help 'task';

		   drop table membership;

create table task
		   (
		   task_id int primary key,
		   assigned_to varchar(100) not null,
		   description varchar(100) not null,
		   deadline varchar(100) not null,
		   status varchar(100) not null
		   )
		   drop table task;
