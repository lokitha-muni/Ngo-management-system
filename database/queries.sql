-- 1. Volunteers with skills not assigned to any project
SELECT name, skills FROM volunteer
WHERE volunteer_id NOT IN (SELECT DISTINCT volunteer_id FROM volunteer WHERE assigned_projects <> 'None');

-- 2. Donors who donated above the average amount
SELECT name, contact_information FROM donor
WHERE donor_id IN (SELECT donor_id FROM donation 
                  WHERE amount > (SELECT AVG(amount) FROM donation));

-- 3. Projects with expenses exceeding 80% of their budget
SELECT name, budget FROM project
WHERE project_id IN (SELECT project_id FROM expense 
                    GROUP BY project_id 
                    HAVING SUM(amount) > 0.8 * (SELECT budget FROM project p WHERE p.project_id = expense.project_id));

-- 4. Events with no volunteers assigned (through projects)
SELECT name FROM event
WHERE associated_campaign NOT IN (SELECT associated_campaign FROM campaign 
                                 WHERE associated_project IN (SELECT assigned_projects FROM volunteer));

-- 5. Beneficiaries receiving support from high-budget projects
SELECT name FROM beneficiary
WHERE type_of_support_received IN (SELECT name FROM project 
                                  WHERE budget > (SELECT AVG(budget) FROM project));

-- 6. Volunteers skilled in areas with project shortages
SELECT name, skills FROM volunteer
WHERE skills IN (SELECT skills FROM volunteer 
                GROUP BY skills 
                HAVING COUNT(*) < (SELECT AVG(volunteer_count) 
                                  FROM (SELECT COUNT(*) as volunteer_count FROM volunteer GROUP BY skills) as counts));

-- 7. Donors who haven't donated in the last 6 months
SELECT name FROM donor
WHERE donor_id NOT IN (SELECT donor_id FROM donation 
                      WHERE Date_ > DATEADD(MONTH, -6, GETDATE()));

-- 8. Projects with above-average volunteer engagement
SELECT name FROM project
WHERE (SELECT COUNT(*) FROM volunteer WHERE assigned_projects = project.name) > 
      (SELECT AVG(volunteer_count) FROM (SELECT COUNT(*) as volunteer_count FROM volunteer GROUP BY assigned_projects) as counts);

-- 9. Campaigns with no associated events (type-safe NOT IN)
SELECT name FROM campaign
WHERE CAST(campaign_id AS VARCHAR) NOT IN (
    SELECT associated_campaign 
    FROM event 
    WHERE associated_campaign IS NOT NULL
);

-- 10. Expense categories with spending above organization average
SELECT category FROM expense
GROUP BY category
HAVING SUM(amount) > (SELECT AVG(total) FROM (SELECT SUM(amount) as total FROM expense GROUP BY category) as category_totals);

-- 11. Volunteers assigned to projects with above-average budgets
SELECT v.name, v.assigned_projects
FROM volunteer v
WHERE EXISTS (
    SELECT 1 FROM project p 
    WHERE p.name = v.assigned_projects
    AND p.budget > (SELECT AVG(budget) FROM project)
);

-- 12. Donors who contributed to campaigns with high volunteer engagement
SELECT d.name, d.contact_information
FROM donor d
WHERE d.donor_id IN (
    SELECT dn.donor_id FROM donation dn
    WHERE dn.purpose IN (
        SELECT c.name FROM campaign c
        WHERE (SELECT COUNT(*) FROM volunteer v 
              WHERE v.assigned_projects = c.associated_project) > 10
    )
);

-- 13. Projects with expense ratios higher than their category average
SELECT p.name, p.budget
FROM project p
WHERE (
    SELECT SUM(e.amount) FROM expense e 
    WHERE e.project_id = p.project_id
) > (
    SELECT AVG(sum_amount) FROM (
        SELECT SUM(amount) as sum_amount 
        FROM expense 
        WHERE category IN (
            SELECT category FROM expense ex 
            WHERE ex.project_id = p.project_id
        )
        GROUP BY project_id
    ) as category_avgs
);

-- 14. Beneficiaries receiving support from projects with no recent expenses
SELECT b.name, b.type_of_support_received
FROM beneficiary b
WHERE b.type_of_support_received IN (
    SELECT p.name FROM project p
    WHERE NOT EXISTS (
        SELECT 1 FROM expense e
        WHERE e.project_id = p.project_id
        AND e.date_ > DATEADD(MONTH, -3, GETDATE())
    )
);

-- 15. Campaigns with events in all locations where health camps were held
SELECT c.name
FROM campaign c
WHERE NOT EXISTS (
    SELECT DISTINCT location FROM event e1
    WHERE e1.purpose LIKE '%Health Camp%'
    AND location NOT IN (
        SELECT e2.location FROM event e2
        WHERE e2.associated_campaign = c.name
    )
);

-- 16. Volunteers with skills matching all required skills of their assigned projects
SELECT v.name, v.skills
FROM volunteer v
WHERE NOT EXISTS (
    SELECT 1 FROM project p
    WHERE p.name = v.assigned_projects
    AND p.description NOT LIKE '%' + v.skills + '%'
);

-- 17. Donors who always used the same payment method
SELECT d.name
FROM donor d
WHERE 1 = (
    SELECT COUNT(DISTINCT payment_method)
    FROM donation dn
    WHERE dn.donor_id = d.donor_id
);

-- 18. Projects that received donations every month of their duration (SQL Server compatible)
SELECT p.name
FROM project p
WHERE NOT EXISTS (
    SELECT 1 FROM (
        SELECT DATEADD(MONTH, n.number, p.start_date) AS month_date
        FROM master.dbo.spt_values n
        WHERE n.type = 'P' 
        AND n.number BETWEEN 0 AND DATEDIFF(MONTH, p.start_date, p.end_date)
    ) months
    WHERE NOT EXISTS (
        SELECT 1 FROM donation d
        WHERE d.purpose = p.name
        AND YEAR(d.Date_) = YEAR(months.month_date)
        AND MONTH(d.Date_) = MONTH(months.month_date)
    )
);

-- 19. Events with volunteer attendance matching their campaign's target audience
SELECT e.name, e.location
FROM event e
WHERE (
    SELECT COUNT(DISTINCT v.volunteer_id)
    FROM volunteer v
    JOIN project p ON v.assigned_projects = p.name
    JOIN campaign c ON p.name = c.associated_project
    WHERE c.name = e.associated_campaign
) > (
    SELECT COUNT(*) * 0.7 FROM volunteer v
    WHERE v.skills LIKE '%' + (
        SELECT target_audience FROM campaign c 
        WHERE c.name = e.associated_campaign
    ) + '%'
);

-- 20. Beneficiaries who received support from all project types in their category
SELECT b.name
FROM beneficiary b
WHERE NOT EXISTS (
    SELECT 1 FROM project p
    WHERE p.description LIKE '%' + b.type_of_support_received + '%'
    AND NOT EXISTS (
        SELECT 1 FROM beneficiary b2
        WHERE b2.beneficiary_id = b.beneficiary_id
        AND b2.type_of_support_received = p.name
    )
);

-- 21. Find reports prepared by 'Dr. Meera Singh'
SELECT * FROM report WHERE prepared_by = 'Dr. Meera Singh';

-- 22. Find tasks with 'Completed' status
SELECT * FROM task WHERE status = 'Completed';

-- 23. Find membership expiring in 2025
SELECT * FROM membership WHERE expiry_date < '2026-01-01';

-- 24. Donations with donor names
SELECT d.*, dn.name 
FROM donation d
JOIN donor dn ON d.donor_id = dn.donor_id;

-- 25. Expenses with project names
SELECT e.*, p.name 
FROM expense e
JOIN project p ON e.project_id = p.project_id;

-- 26. Events with campaign names
SELECT e.*, c.name 
FROM event e
JOIN campaign c ON e.associated_campaign = c.name;

-- 27. Reports with associated projects
SELECT r.*, p.name 
FROM report r
JOIN project p ON r.associated_project = p.name;

-- 28. Volunteers assigned to projects
SELECT v.*, p.name 
FROM volunteer v
JOIN project p ON v.assigned_projects = p.name;

-- 29. Beneficiaries and type of support received
SELECT b.name, b.type_of_support_received, p.name AS project_name
FROM beneficiary b
JOIN project p ON b.type_of_support_received = p.description;

-- 30. Donations with payment method details
SELECT d.*, dn.name AS donor_name, dn.contact_information 
FROM donation d
JOIN donor dn ON d.donor_id = dn.donor_id
WHERE d.payment_method = 'UPI';

-- 31. Count of volunteers by skill
SELECT skills, COUNT(*) AS volunteer_count
FROM volunteer
GROUP BY skills;

-- 32. Total donations by donor
SELECT dn.name, SUM(d.amount) AS total_donated
FROM donation d
JOIN donor dn ON d.donor_id = dn.donor_id
GROUP BY dn.name
ORDER BY total_donated DESC;

-- 33. Average donation amount
SELECT AVG(amount) AS average_donation
FROM donation;

-- 34. Projects with their total expenses
SELECT p.name, SUM(e.amount) AS total_expenses
FROM project p
JOIN expense e ON p.project_id = e.project_id
GROUP BY p.name;

-- 35. Campaigns with their associated events count
SELECT c.name, COUNT(e.event_id) AS event_count
FROM campaign c
LEFT JOIN event e ON c.name = e.associated_campaign
GROUP BY c.name;

-- 36. Volunteers available on weekends
SELECT * FROM volunteer
WHERE availability = 'Weekends';

-- 37. Donors who prefer 'Education' causes
SELECT * FROM donor
WHERE preferred_cuses LIKE '%Education%';

-- 38. Projects starting in 2024
SELECT * FROM project
WHERE start_date BETWEEN '2024-01-01' AND '2024-12-31';

-- 39. Gold membership users
SELECT u.*, m.type, m.expiry_date
FROM users u
JOIN membership m ON u.user_id = m.user_id
WHERE m.type = 'Gold';

-- 40. Volunteers not assigned to any project
SELECT * FROM volunteer
WHERE assigned_projects = 'None' OR assigned_projects IS NULL;

-- 41. Donations made via credit card
SELECT * FROM donation
WHERE payment_method = 'Credit Card';

-- 42. Expenses paid by 'NGO Funds'
SELECT * FROM expense
WHERE paid_by = 'NGO Funds';

-- 43. Newsletters sent to 'All Subscribers'
SELECT * FROM newsletter
WHERE sent_to = 'All Subscribers';

-- 44. Users with phone numbers starting with '98'
SELECT * FROM users
WHERE phoneNumber LIKE '98%';

-- 45. Volunteers with 'Public Speaking' skills
SELECT * FROM volunteer
WHERE skills = 'Public Speaking';

-- 46. Campaigns targeting 'General Public'
SELECT * FROM campaign
WHERE target_audience = 'General Public';

-- 47. Events with 'Awareness' purpose
SELECT * FROM event
WHERE purpose LIKE '%Awareness%';

-- 48. Top 5 largest donations
SELECT * FROM donation
ORDER BY amount DESC

-- 49. Projects over budget
SELECT p.name, p.budget, SUM(e.amount) AS total_expenses
FROM project p
JOIN expense e ON p.project_id = e.project_id
GROUP BY p.name, p.budget
HAVING SUM(e.amount) > p.budget;

-- 50. Volunteers with multiple skills
SELECT * FROM volunteer
WHERE skills LIKE '%,%';

-- 51. Most active volunteers (assigned to most projects)
SELECT name, COUNT(*) AS project_count
FROM volunteer
GROUP BY name
ORDER BY project_count DESC;

-- 52. Beneficiaries receiving 'Education' support
SELECT * FROM beneficiary
WHERE type_of_support_received LIKE '%Education%';

-- 53. Events happening this month (SQL Server version)
SELECT * FROM event
WHERE MONTH(date_) = MONTH(GETDATE()) 
AND YEAR(date_) = YEAR(GETDATE());

-- 54. Tasks assigned to 'John Doe'
SELECT * FROM task
WHERE assigned_to = 'John Doe';

-- 55. Donations for 'Disaster Relief'
SELECT * FROM donation
WHERE purpose LIKE '%Disaster Relief%';

-- 56. Expenses by category
SELECT category, SUM(amount) AS total_amount
FROM expense
GROUP BY category
ORDER BY total_amount DESC;

-- 57. Volunteers available on weekdays
SELECT * FROM volunteer
WHERE availability = 'Weekdays';

-- 58. Donors from specific area (phone prefix)
SELECT * FROM donor
WHERE contact_information LIKE '98%';

-- 59. Beneficiaries with support history over ₹10,000
SELECT * FROM beneficiary
WHERE support_history LIKE '%10,000%';

-- 60. Pending tasks
SELECT * FROM task
WHERE status = 'Pending';

-- 61. Platinum membership users
SELECT u.name, u.Email, m.expiry_date
FROM users u
JOIN membership m ON u.user_id = m.user_id
WHERE m.type = 'Platinum';

-- 62. Projects with no expenses
SELECT p.*
FROM project p
LEFT JOIN expense e ON p.project_id = e.project_id
WHERE e.expense_id IS NULL;

-- 63. Campaigns without associated events
SELECT c.*
FROM campaign c
LEFT JOIN event e ON c.name = e.associated_campaign
WHERE e.event_id IS NULL;

-- 64. Users who are both volunteers and donors
SELECT u.*
FROM users u
JOIN volunteer v ON u.name = v.name
JOIN donor d ON u.name = d.name;

-- 65. Most common volunteer skills
SELECT skills, COUNT(*) AS count
FROM volunteer
GROUP BY skills
ORDER BY count DESC;

-- 66. Donation frequency by donor
SELECT dn.name, COUNT(d.donation_id) AS donation_count
FROM donor dn
LEFT JOIN donation d ON dn.donor_id = d.donor_id
GROUP BY dn.name
ORDER BY donation_count DESC;

-- 67. Projects with highest expense ratio
SELECT p.name, p.budget, SUM(e.amount) AS total_expenses, 
       (SUM(e.amount)/p.budget*100) AS percentage_used
FROM project p
JOIN expense e ON p.project_id = e.project_id
GROUP BY p.name, p.budget
ORDER BY percentage_used DESC;

-- 68. Volunteers born before 1990 (estimated from names)
SELECT * FROM volunteer
WHERE name IN (SELECT name FROM users WHERE Email LIKE '%19%');

-- 69. Donations by payment method
SELECT payment_method, COUNT(*) AS count, SUM(amount) AS total_amount
FROM donation
GROUP BY payment_method;

-- 70. Projects managed by 'Aarav Sharma'
SELECT p.*
FROM project p
JOIN users u ON p.assigned_volunteer = u.name
WHERE u.name = 'Aarav Sharma';

-- 71. Tasks due today (SQL Server version)
SELECT * FROM task
WHERE deadline = CAST(GETDATE() AS DATE);

-- 72. Membership types distribution
SELECT type, COUNT(*) AS count
FROM membership
GROUP BY type;

-- 73. Events by location
SELECT location, COUNT(*) AS event_count
FROM event
GROUP BY location
ORDER BY event_count DESC;

-- 74. Volunteers with specific contact prefix
SELECT * FROM volunteer
WHERE contact_information LIKE '987%';

-- 75. Projects with no assigned volunteers
SELECT * FROM project
WHERE assigned_volunteer = 'None' OR assigned_volunteer IS NULL;

-- 76. Users without membership
SELECT u.*
FROM users u
LEFT JOIN membership m ON u.user_id = m.user_id
WHERE m.membership_id IS NULL;

-- 77. Volunteers with highest availability
SELECT name, availability, COUNT(*) AS project_count
FROM volunteer
GROUP BY name, availability
ORDER BY project_count DESC;

-- 78. Donations by purpose
SELECT purpose, COUNT(*) AS count, SUM(amount) AS total_amount
FROM donation
GROUP BY purpose
ORDER BY total_amount DESC;

-- 79. Projects with similar budgets (±10%)
SELECT p1.name AS project1, p2.name AS project2, p1.budget
FROM project p1, project p2
WHERE p1.project_id < p2.project_id
AND ABS(p1.budget - p2.budget) < (p1.budget * 0.1);

-- 80. Volunteers assigned to multiple projects
SELECT name, COUNT(*) AS project_count
FROM volunteer
GROUP BY name
HAVING COUNT(*) > 1
ORDER BY project_count DESC;

-- 81. Donors with email addresses
SELECT d.*, u.Email
FROM donor d
JOIN users u ON d.name = u.name;

-- 82. Beneficiaries with recent support
SELECT * FROM beneficiary
WHERE support_history LIKE '%2024%' OR support_history LIKE '%2025%';

-- 83. Tasks grouped by status
SELECT status, COUNT(*) AS task_count
FROM task
GROUP BY status;

-- 84. Projects with highest volunteer engagement
SELECT p.name, COUNT(v.volunteer_id) AS volunteer_count
FROM project p
JOIN volunteer v ON p.name = v.assigned_projects
GROUP BY p.name
ORDER BY volunteer_count DESC;

-- 85. Campaigns with most events
SELECT c.name, COUNT(e.event_id) AS event_count
FROM campaign c
JOIN event e ON c.name = e.associated_campaign
GROUP BY c.name
ORDER BY event_count DESC;

-- 86. Expense outliers (top 5% highest) - TOP PERCENT version
SELECT TOP 5 PERCENT *
FROM expense
ORDER BY amount DESC;

-- 87. Users with multiple roles
SELECT u.name, u.role, v.skills, d.donation_history
FROM users u
LEFT JOIN volunteer v ON u.name = v.name
LEFT JOIN donor d ON u.name = d.name
WHERE v.volunteer_id IS NOT NULL AND d.donor_id IS NOT NULL;

-- 88. Volunteers with specific skills combination
SELECT * FROM volunteer
WHERE skills LIKE '%Teaching%' AND skills LIKE '%Public Speaking%';

-- 89. Donors with increasing donation amounts
SELECT d.name, dn1.amount AS first_donation, dn2.amount AS recent_donation
FROM donor d
JOIN donation dn1 ON d.donor_id = dn1.donor_id
JOIN donation dn2 ON d.donor_id = dn2.donor_id
WHERE dn1.Date_ < dn2.Date_ AND dn1.amount < dn2.amount;

-- 90. Campaigns with similar goals
SELECT c1.name, c2.name, c1.goal
FROM campaign c1, campaign c2
WHERE c1.campaign_id < c2.campaign_id
AND c1.goal = c2.goal;

-- 91. Beneficiaries by type of support
SELECT type_of_support_received, COUNT(*) AS beneficiary_count
FROM beneficiary
GROUP BY type_of_support_received
ORDER BY beneficiary_count DESC;

-- 92. Tasks grouped by assigned person
SELECT assigned_to, COUNT(*) AS task_count
FROM task
GROUP BY assigned_to
ORDER BY task_count DESC;

-- 93. Donation sources analysis
SELECT 
    CASE 
        WHEN payment_method = 'UPI' THEN 'Digital'
        WHEN payment_method = 'Credit Card' THEN 'Digital'
        WHEN payment_method = 'Bank Transfer' THEN 'Bank'
        ELSE 'Other'
    END AS source_type,
    COUNT(*) AS count,
    SUM(amount) AS total_amount
FROM donation
GROUP BY amount;

-- 94. Project budget utilization
SELECT 
    name,
    budget,
    (SELECT SUM(amount) FROM expense WHERE project_id = p.project_id) AS total_expenses,
    ((SELECT SUM(amount) FROM expense WHERE project_id = p.project_id)/budget*100) AS utilization_percentage
FROM project p;

-- 95. Donors with consistent donations
SELECT d.name, COUNT(*) AS donation_count, AVG(dn.amount) AS avg_amount
FROM donor d
JOIN donation dn ON d.donor_id = dn.donor_id
GROUP BY d.name
HAVING COUNT(*) > 3
ORDER BY donation_count DESC;

-- 96. Projects with highest beneficiary impact
SELECT p.name, COUNT(b.beneficiary_id) AS beneficiary_count
FROM project p
JOIN beneficiary b ON p.description = b.type_of_support_received
GROUP BY p.name
ORDER BY beneficiary_count DESC;

-- 97. Campaign effectiveness by event count
SELECT c.name, c.goal, COUNT(e.event_id) AS event_count
FROM campaign c
LEFT JOIN event e ON c.name = e.associated_campaign
GROUP BY c.name, c.goal
ORDER BY event_count DESC;

-- 98. Users with complete profile information
SELECT * FROM users
WHERE name IS NOT NULL 
AND Email IS NOT NULL 
AND phoneNumber IS NOT NULL 
AND role IS NOT NULL;

-- 99. Volunteer engagement by project type
SELECT 
    p.description AS project_type,
    COUNT(v.volunteer_id) AS volunteer_count
FROM project p
JOIN volunteer v ON p.name = v.assigned_projects
GROUP BY p.description
ORDER BY volunteer_count DESC;

-- 100. Donor segmentation by donation amount
SELECT 
    donor_id,
    name,
    CASE 
        WHEN total_donated < 5000 THEN 'Small Donor'
        WHEN total_donated BETWEEN 5000 AND 20000 THEN 'Medium Donor'
        ELSE 'Large Donor'
    END AS donor_segment,
    total_donated
FROM (
    SELECT d.donor_id, d.name, SUM(dn.amount) AS total_donated
    FROM donor d
    JOIN donation dn ON d.donor_id = dn.donor_id
    GROUP BY d.donor_id, d.name
) donor_totals
ORDER BY total_donated DESC;

-- 101. Project volunteer capacity planning
SELECT 
    p.name,
    p.description,
    COUNT(v.volunteer_id) AS current_volunteers,
    CEILING(p.budget / 10000) AS recommended_volunteers,
    CEILING(p.budget / 10000) - COUNT(v.volunteer_id) AS additional_volunteers_needed
FROM project p
LEFT JOIN volunteer v ON p.name = v.assigned_projects
GROUP BY p.name, p.description, p.budget
HAVING CEILING(p.budget / 10000) > COUNT(v.volunteer_id);

-- 102. Find donors who haven't donated in the last 6 months
SELECT d.* FROM donor d
LEFT JOIN donation dn ON d.donor_id = dn.donor_id 
WHERE dn.Date_ < DATEADD(MONTH, -6, GETDATE()) OR dn.donation_id IS NULL;

-- 103. Projects with upcoming deadlines (within 30 days)
SELECT * FROM project 
WHERE end_date BETWEEN GETDATE() AND DATEADD(DAY, 30, GETDATE());

-- 104. Find active volunteers (those assigned to projects)
SELECT v.* 
FROM volunteer v
WHERE v.assigned_projects IS NOT NULL 
AND v.assigned_projects <> 'None';

-- 105. Most active donation months
SELECT MONTH(Date_) AS month, COUNT(*) AS donation_count, SUM(amount) AS total_amount
FROM donation 
GROUP BY MONTH(Date_)
ORDER BY total_amount DESC;

-- 106. Average donation amount by payment method
SELECT payment_method, AVG(amount) AS avg_donation
FROM donation 
GROUP BY payment_method;

-- 107. Donors who donated to multiple campaigns
SELECT d.name, COUNT(DISTINCT dn.purpose) AS campaign_count
FROM donor d
JOIN donation dn ON d.donor_id = dn.donor_id
GROUP BY d.name
HAVING COUNT(DISTINCT dn.purpose) > 1;

-- 108. Projects with no associated reports
SELECT p.* FROM project p
LEFT JOIN report r ON p.name = r.associated_project
WHERE r.report_id IS NULL;

-- 109. Events with low volunteer attendance (alternative)
SELECT e.*
FROM event e
WHERE (
    SELECT COUNT(v.volunteer_id)
    FROM volunteer v
    WHERE v.assigned_projects LIKE '%' + e.name + '%'
) < 5;

-- 110. Beneficiaries who received multiple types of support
SELECT name, COUNT(DISTINCT type_of_support_received) AS support_types
FROM beneficiary
GROUP BY name
HAVING COUNT(DISTINCT type_of_support_received) > 1;

-- 111. Year-over-year donation growth
SELECT YEAR(Date_) AS year, SUM(amount) AS total_donations
FROM donation
GROUP BY YEAR(Date_)
ORDER BY year;

-- 112. Top volunteers by project participation
SELECT TOP 10 v.*, COUNT(p.project_id) AS projects_count
FROM volunteer v
JOIN project p ON CHARINDEX(p.name, v.assigned_projects) > 0
GROUP BY v.volunteer_id, v.name, v.skills, v.availability, v.contact_information, v.assigned_projects
ORDER BY projects_count DESC;

-- 113. Projects with highest expense-to-beneficiary ratio
SELECT p.name, COUNT(b.beneficiary_id)/SUM(e.amount) AS ratio
FROM project p
JOIN expense e ON p.project_id = e.project_id
JOIN beneficiary b ON p.description = b.type_of_support_received
GROUP BY p.name
ORDER BY ratio DESC;

-- 114. Donors from corporate sponsors
SELECT * FROM donor
WHERE name LIKE '%Inc.%' OR name LIKE '%Corp%' OR name LIKE '%LLC%';

-- 115. Campaigns with highest donor participation rate
SELECT c.name, COUNT(DISTINCT dn.donor_id)*1.0/COUNT(DISTINCT d.donor_id) AS participation_rate
FROM campaign c
JOIN donation dn ON c.name = dn.purpose
JOIN donor d ON dn.donor_id = d.donor_id
GROUP BY c.name
ORDER BY participation_rate DESC;

-- 116. Volunteers with specialized certifications
SELECT * FROM volunteer
WHERE skills LIKE '%Certified%' OR skills LIKE '%License%';

-- 117. Projects nearing budget exhaustion (>90% spent)
SELECT p.name, p.budget, SUM(e.amount) AS spent, 
       (SUM(e.amount)/p.budget)*100 AS percent_spent
FROM project p
JOIN expense e ON p.project_id = e.project_id
GROUP BY p.name, p.budget
HAVING (SUM(e.amount)/p.budget)*100 > 90;

-- 118. Most common expense categories by project type
SELECT p.description AS project_type, e.category, COUNT(*) AS expense_count
FROM project p
JOIN expense e ON p.project_id = e.project_id
GROUP BY p.description, e.category
ORDER BY project_type, expense_count DESC;

-- 119. Donors with anniversary coming up (same month as first donation)
SELECT d.name, MONTH(MIN(dn.Date_)) AS anniversary_month
FROM donor d
JOIN donation dn ON d.donor_id = dn.donor_id
GROUP BY d.name
HAVING MONTH(MIN(dn.Date_)) = MONTH(GETDATE());

-- 120. Most reliable volunteers by task completion
SELECT v.*, COUNT(t.task_id) AS completed_tasks
FROM volunteer v
JOIN task t ON t.assigned_to = v.name
WHERE t.status = 'Completed'
GROUP BY v.volunteer_id, v.name, v.skills, v.availability, v.contact_information, v.assigned_projects
ORDER BY completed_tasks DESC;

-- 121. Projects with longest duration
SELECT name, DATEDIFF(day, start_date, end_date) AS duration_days
FROM project
ORDER BY duration_days DESC;

-- 122. Campaigns with highest social media engagement
SELECT c.name AS total_mentions
FROM campaign c
JOIN event e ON c.name = e.associated_campaign
GROUP BY c.name
ORDER BY total_mentions DESC;

-- 123. Donors who increased their donation amount year-over-year
SELECT d.name, YEAR(dn1.Date_) AS year1, dn1.amount AS amount1, 
       YEAR(dn2.Date_) AS year2, dn2.amount AS amount2
FROM donor d
JOIN donation dn1 ON d.donor_id = dn1.donor_id
JOIN donation dn2 ON d.donor_id = dn2.donor_id
WHERE YEAR(dn2.Date_) = YEAR(dn1.Date_) + 1
AND dn2.amount > dn1.amount;

-- 124. Project leaders by volunteer referrals
SELECT 
    v1.name AS project_leader,
    COUNT(v2.volunteer_id) AS team_members
FROM volunteer v1
JOIN volunteer v2 ON v2.assigned_projects = v1.assigned_projects
WHERE v1.skills LIKE '%Leadership%'
AND v1.volunteer_id <> v2.volunteer_id
GROUP BY v1.name
ORDER BY team_members DESC;

-- 125. Projects with most diverse funding sources
SELECT p.name, COUNT(DISTINCT dn.payment_method) AS payment_methods
FROM project p
JOIN expense e ON p.project_id = e.project_id
JOIN donation dn ON e.paid_by = dn.purpose
GROUP BY p.name
ORDER BY payment_methods DESC;

-- 126. Events with highest beneficiary attendance
SELECT e.name, COUNT(b.beneficiary_id) AS beneficiary_count
FROM event e
JOIN beneficiary b ON e.event_id = b.beneficiary_id
GROUP BY e.name
ORDER BY beneficiary_count DESC;

-- 127. Most effective campaign channels
SELECT purpose, COUNT(*) AS donor_count, SUM(amount) AS total_raised
FROM donation
GROUP BY purpose
ORDER BY total_raised DESC;

-- 128. Volunteers with matching professional skills
SELECT v1.name AS volunteer1, v2.name AS volunteer2, v1.skills
FROM volunteer v1
JOIN volunteer v2 ON v1.skills = v2.skills AND v1.volunteer_id < v2.volunteer_id;

-- 129. Projects with most volunteer hours logged
SELECT 
    p.name AS project_name,
    COUNT(v.volunteer_id) AS volunteer_count,
    COUNT(v.volunteer_id) * 8 AS estimated_hours -- Assuming 8 hours per volunteer
FROM project p
JOIN volunteer v ON p.name = v.assigned_projects
GROUP BY p.name
ORDER BY volunteer_count DESC;

-- 130. Donors who give recurring donations
SELECT d.name, COUNT(*) AS donation_count, 
       AVG(DATEDIFF(day, dn1.Date_, dn2.Date_)) AS avg_days_between
FROM donor d
JOIN donation dn1 ON d.donor_id = dn1.donor_id
JOIN donation dn2 ON d.donor_id = dn2.donor_id 
    AND dn2.Date_ > dn1.Date_
GROUP BY d.name
HAVING COUNT(*) > 3
ORDER BY avg_days_between;

-- 131. Campaigns with highest return on investment
SELECT c.name, (SUM(dn.amount) - SUM(e.amount)) / SUM(e.amount) AS ROI
FROM campaign c
LEFT JOIN donation dn ON c.name = dn.purpose
LEFT JOIN expense e ON c.name = e.category
GROUP BY c.name
ORDER BY ROI DESC;

-- 132. Volunteers who haven't volunteered in 6 months
SELECT v.* FROM volunteer v
LEFT JOIN event ve ON v.volunteer_id = ve.event_id
LEFT JOIN event e ON ve.event_id = e.event_id
WHERE e.date_ < DATEADD(MONTH, -6, GETDATE()) OR e.event_id IS NULL;

-- 133. Most common beneficiary demographics
SELECT beneficiary_id, COUNT(*) AS count
FROM beneficiary
GROUP BY beneficiary_id;

--134. Donors who support projects that have events
SELECT DISTINCT d.*
FROM donor d
WHERE EXISTS (
    SELECT 1 
    FROM donation dn 
    JOIN project p ON dn.purpose = p.name
    WHERE dn.donor_id = d.donor_id
    AND EXISTS (
        SELECT 1 FROM event WHERE associated_campaign = p.name
    )
);

-- 135.Donors who volunteered at events
SELECT DISTINCT d.*
FROM donor d
JOIN volunteer v ON d.contact_information = v.contact_information
JOIN event e ON v.assigned_projects LIKE '%' + e.name + '%'
WHERE e.date_ > DATEADD(YEAR, -1, GETDATE());

-- 136. Volunteers with language skills
SELECT * FROM volunteer
WHERE skills LIKE '%Spanish%' OR skills LIKE '%French%' OR skills LIKE '%Mandarin%';

-- 137. Most engaging campaigns (alternative using volunteer participation)
SELECT 
    c.name AS campaign_name,
    COUNT(DISTINCT v.volunteer_id) AS volunteer_count
FROM campaign c
LEFT JOIN project p ON c.name = p.description
LEFT JOIN volunteer v ON p.name = v.assigned_projects
GROUP BY c.name
ORDER BY volunteer_count DESC;

-- 138. Projects with greatest community impact
SELECT 
    p.name AS project_name,
    p.description,
    COUNT(DISTINCT v.volunteer_id) AS volunteer_count,
    COUNT(DISTINCT d.donation_id) AS donation_count,
    COUNT(DISTINCT b.beneficiary_id) AS beneficiary_count,
    (COUNT(DISTINCT v.volunteer_id) + 
     COUNT(DISTINCT d.donation_id) + 
     COUNT(DISTINCT b.beneficiary_id)) AS total_impact_score
FROM project p
LEFT JOIN volunteer v ON p.name = v.assigned_projects
LEFT JOIN donation d ON p.name = d.purpose
LEFT JOIN beneficiary b ON p.description = b.type_of_support_received
GROUP BY p.name, p.description
ORDER BY total_impact_score DESC;

-- 139. Supporters who both donate and volunteer
SELECT DISTINCT 
    d.name,
    d.contact_information
FROM donor d
WHERE EXISTS (
    SELECT 1 FROM volunteer v 
    WHERE v.contact_information = d.contact_information
);

-- 140. Events with highest volunteer engagement
SELECT 
    e.name AS event_name,
    e.location,
    e.date_,
    COUNT(DISTINCT v.volunteer_id) AS volunteer_count,
    COUNT(DISTINCT v.volunteer_id) * 100.0 / (
        SELECT COUNT(*) FROM volunteer
    ) AS participation_percentage
FROM event e
LEFT JOIN project p ON e.associated_campaign = p.description
LEFT JOIN volunteer v ON p.name = v.assigned_projects
GROUP BY e.name, e.location, e.date_
ORDER BY volunteer_count DESC;

-- 141. Users managing the most projects
SELECT 
    u.name AS leader_name,
    u.role,
    COUNT(p.project_id) AS active_projects,
    STRING_AGG(p.name, ', ') AS project_list
FROM users u
JOIN project p ON u.name = p.assigned_volunteer  -- Using assigned_volunteer instead of manager_id
WHERE u.role IN ('Project Lead', 'Manager', 'Coordinator')
GROUP BY u.name, u.role
ORDER BY active_projects DESC;

-- 142. Supporters with increased engagement
SELECT 
    d.name,
    COUNT(DISTINCT dn1.donation_id) AS initial_donations,
    COUNT(DISTINCT dn2.donation_id) AS recent_donations
FROM donor d
LEFT JOIN donation dn1 ON d.donor_id = dn1.donor_id AND dn1.Date_ < DATEADD(YEAR, -1, GETDATE())
LEFT JOIN donation dn2 ON d.donor_id = dn2.donor_id AND dn2.Date_ >= DATEADD(YEAR, -1, GETDATE())
GROUP BY d.name
HAVING COUNT(DISTINCT dn2.donation_id) > COUNT(DISTINCT dn1.donation_id)
ORDER BY recent_donations DESC;

-- 143. Active volunteers who also donate
SELECT DISTINCT v.*
FROM volunteer v
WHERE EXISTS (
    SELECT 1 FROM donor d 
    WHERE d.contact_information = v.contact_information
);

-- 144. Projects with most repeat volunteers
SELECT p.name, COUNT(DISTINCT v.volunteer_id) AS repeat_volunteers
FROM project p
JOIN volunteer v ON p.name = v.assigned_projects
GROUP BY p.name
ORDER BY repeat_volunteers DESC;

-- 145. Campaigns with most corporate sponsors
SELECT c.name, COUNT(DISTINCT d.donor_id) AS corporate_sponsors
FROM campaign c
JOIN donation dn ON c.name = dn.purpose
JOIN donor d ON dn.donor_id = d.donor_id
WHERE d.name LIKE '%Inc.%' OR d.name LIKE '%Corp%' OR d.name LIKE '%LLC%'
GROUP BY c.name
ORDER BY corporate_sponsors DESC;

-- 146. Most active fundraising months
SELECT MONTH(Date_) AS month, COUNT(*) AS donation_count
FROM donation
GROUP BY MONTH(Date_)
ORDER BY donation_count DESC;

-- 147. Volunteers with technical skills
SELECT * FROM volunteer
WHERE skills LIKE '%Programming%' OR skills LIKE '%IT%' OR skills LIKE '%Tech%';

-- 148. Projects with most diverse volunteer skills
SELECT p.name, COUNT(DISTINCT v.skills) AS unique_skills
FROM project p
JOIN volunteer v ON p.name = v.assigned_projects
GROUP BY p.name
ORDER BY unique_skills DESC;

-- 149a. Project leaders with largest teams
SELECT 
    v.name AS project_leader,
    COUNT(*) - 1 AS team_size  -- Subtract 1 to exclude the leader
FROM volunteer v
JOIN volunteer v2 ON v.assigned_projects = v2.assigned_projects
WHERE v.skills LIKE '%Team Lead%'
GROUP BY v.name
ORDER BY team_size DESC;

-- 150. Volunteer participation by project activity
SELECT 
    p.name AS project_name,
    YEAR(p.start_date) AS activity_year,
    COUNT(DISTINCT v.volunteer_id) AS active_volunteers,
    COUNT(DISTINCT CASE WHEN v.skills LIKE '%Core Team%' THEN v.volunteer_id END) AS core_members
FROM project p
JOIN volunteer v ON p.name = v.assigned_projects
GROUP BY p.name, YEAR(p.start_date)
ORDER BY activity_year, active_volunteers DESC;
