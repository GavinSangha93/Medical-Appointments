# Medical Appointment No-Show Analysis

An end-to-end healthcare analytics project using MySQL and Tableau to clean appointment data, analyze missed-appointment patterns, and help operations teams prioritize patient outreach.

## Business Question

Which scheduling and patient-history factors are associated with missed appointments, and how can those insights support more focused reminder and follow-up efforts?

## What I Built

- Cleaned and standardized appointment records in MySQL.
- Converted raw timestamps into usable date fields and removed invalid records.
- Engineered appointment lead time from scheduling and appointment dates.
- Analyzed no-show rates by day, lead time, age group, SMS status, and neighborhood.
- Used CTEs and window functions to calculate prior patient attendance history.
- Created a reusable SQL view that groups appointments into operational risk tiers.
- Built an interactive Tableau dashboard with KPI cards, filters, neighborhood rankings, and an appointment-level follow-up table.

## Key Findings

- The cleaned dataset contains **110,519 appointments** with an overall **20.19% no-show rate**.
- Appointments were scheduled an average of **10.18 days** in advance.
- Long-lead appointments had the highest no-show rate; same-day appointments had the lowest.
- Saturday had the highest no-show rate among the appointment days displayed.
- The rule-based segmentation assigned **20.08%** of appointments to High Risk and **56.37%** to New Patient - Monitor.
- Neighborhood and appointment-level views make it easier to focus outreach where missed-appointment rates are highest.

## Technical Approach

1. **Data preparation:** standardized field names and data types, converted dates, and removed invalid ages and negative lead times.
2. **Feature engineering:** calculated scheduling lead time and created analysis-friendly groupings.
3. **Exploratory analysis:** compared no-show behavior across operational and patient dimensions.
4. **Risk segmentation:** used prior attendance history and current lead time to assign practical outreach tiers.
5. **Visualization:** connected the prepared data to Tableau and assembled an interactive operational dashboard.

## Dashboard Preview

![Appointment No-Show Dashboard](images/tableau-dashboard-overview.png)

The dashboard combines headline KPIs with lead-time and weekday comparisons, neighborhood rankings, risk-tier distribution, and an appointment-level High Risk filter.

## SQL Walkthrough

### Data Cleaning and Feature Engineering

![SQL data cleaning and lead-time feature engineering](images/sql-data-cleaning.png)

The workflow standardizes the source data and creates the lead-time measure used throughout the analysis.

### No-Show Pattern Analysis

![SQL no-show analysis by lead time and neighborhood](images/sql-no-show-analysis.png)

CASE expressions and aggregate calculations create meaningful lead-time buckets. A window ranking identifies the 15 neighborhoods with the highest no-show rates while excluding locations with fewer than 100 appointments.

### Patient Risk Segmentation

![SQL patient risk classification view](images/sql-patient-risk-view.png)

A CTE and window functions calculate each patient's history using earlier visits. The resulting SQL view supplies a reusable, appointment-level source for Tableau.

## Business Value

This project demonstrates how scheduling data can be turned into an operational workflow. Healthcare teams could use the dashboard to focus reminder calls, SMS campaigns, scheduling interventions, and follow-up resources on appointments that meet higher-risk criteria.

## Limitations and Next Steps

- The risk tiers are transparent business rules, not a validated predictive model.
- Results show associations in historical data and should not be interpreted as causal effects.
- The neighborhood ranking uses a minimum-volume threshold to reduce noise.
- A production version should validate thresholds on newer data, monitor performance over time, and include relevant operational fields such as appointment type, provider, and estimated cost when available.

## Tools and Skills

**MySQL · MySQL Workbench · Tableau · Data Cleaning · Feature Engineering · CTEs · Window Functions · Views · CASE Statements · Exploratory Analysis · Dashboard Design**

## Project Files

- **Medical Appointments Cleaned.sql** — cleaning, feature engineering, analysis, and risk-view creation.
- **Medical Appointments Project.twbx** — packaged Tableau workbook containing the interactive dashboard.
