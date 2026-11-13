# FloodGuard: An Iot-Enabled Monitoring and Response Management System for Spillway Bridge in Barangay San Isidro, Rodriguez, Rizal
### IoT-Based Bridge Flood Monitoring, Public Safety, and Emergency Response System

FloodGuard is an integrated **IoT-based bridge flood monitoring, public safety, and emergency response system** designed to improve flood monitoring, public awareness, and emergency coordination at Spillway Bridge in Barangay San Isidro, Rodriguez (Montalban), Rizal, Philippines.

The system combines an ESP32-based IoT monitoring station, a web-based administrative platform, and mobile applications for residents and emergency responders. It allows environmental conditions and bridge status to be monitored, provides public safety notifications, and supports the reporting, assignment, and management of emergency incidents.

---

## Project Background

Flooding and changing weather conditions can create dangerous situations for motorists and residents who use bridges and nearby waterways. Traditional monitoring methods often rely on manual water-level observation, visual assessment of weather conditions, and communication through personnel and public announcements.

These processes may cause delays in identifying potentially hazardous conditions and communicating important information to affected individuals.

To address these challenges, FloodGuard was developed as an integrated monitoring and emergency response solution. Through IoT sensors, the system gathers environmental data and provides bridge condition information through a centralized web dashboard and mobile applications.

Aside from monitoring bridge conditions, FloodGuard provides a communication and coordination platform where residents can receive push notifications, submit incident reports, publish community updates subject to staff approval, and track assigned responders during emergency situations.

The system also allows authorized administrators to configure the platform, manage users, and maintain sensor settings, while staff members handle incident report validation, newsfeed moderation, and responder assignments.


## Project Location

**Spillway Bridge, Barangay San Isidro, Rodriguez (Montalban), Rizal, Philippines**

Spillway Bridge connects Barangay San Isidro and Barangay San Rafael. It serves as an important passage for residents, motorists, and other individuals traveling between the two communities.

Due to the possibility of rising water levels and unfavorable weather conditions, the bridge is the designated location for FloodGuard's IoT monitoring and public safety implementation.

## 🎥 Video Walkthrough
Watch the full prototype walkthrough here: https://drive.google.com/file/d/1x1p8Uutf_DPeyS9BdGuWP6NwHH-Cy3aD/view?usp=sharing

## 📄 Prototype Screenshots
View the full PDF documentation of the prototype screens: [Prototype Screenshots (PDF)](./interface/interfaces.pdf)

## 📄 Prototype Device Picture
View the Pictures of the Prototype Device: [Device Picture] (./interface/Device Picture)



## Key Features

### 1. IoT-Based Bridge Monitoring

- ESP32-based monitoring station.
- Waterproof ultrasonic sensor for water-level monitoring.
- Rain sensor for detecting rainfall conditions.
- Wind speed sensor for monitoring wind conditions.
- Environmental data transmission to the backend server.
- Automatic bridge condition assessment based on configured thresholds.
- Monitoring station and device status monitoring.

### 2. Automated Warning Mechanisms

- Automated warning activation based on predefined monitoring conditions.
- Siren and voice announcement mechanisms for local warnings.
- Configurable monitoring thresholds.
- Northbound and southbound barrier control through the monitoring system.

### 3. Resident Mobile Application

- Resident account registration and login.
- View sensor readings and current bridge status.
- Receive push notifications about bridge conditions and public safety advisories.
- View public announcements and approved community newsfeed posts.
- Submit newsfeed posts for staff review and approval.
- Submit incident and emergency reports.
- Track the GPS location of assigned responders during emergency response.

### 4. Responder Mobile Application

- Responder account access.
- Receive and review incident assignments.
- Accept assigned incident reports.
- View the location of residents who submitted incident reports.
- Share GPS location during emergency response.
- Allow residents and authorized personnel to monitor responder locations.

### 5. Web-Based Administrative Dashboard

The web-based platform provides separate administrative and staff functions.

**Administrator Module**

- Configure overall system settings.
- Manage user accounts and user roles.
- Configure and manage IoT sensors.
- Set and maintain sensor monitoring parameters and thresholds.
- Monitor sensor readings and monitoring station status.
- Manage system configurations.

**Staff Module**

- Review, approve, or reject incident reports submitted by residents.
- Review, approve, or reject resident-submitted newsfeed posts.
- Assign approved incident reports to responders.
- Monitor incident assignments and response progress.
- Monitor responder GPS locations during emergency operations.
- Manage public announcements and community information.

### 6. GPS-Based Emergency Coordination

- GPS location sharing between residents and responders.
- Location visibility for authorized incident coordination.
- Responder location tracking during assigned emergency operations.
- Improved coordination between reporting residents and assigned responders.

### 7. Community Newsfeed and Public Announcements

- Residents can submit community newsfeed posts.
- Staff review submitted posts before publication.
- Only approved posts are displayed on the public newsfeed.
- The platform supports the dissemination of relevant public information and announcements.

## User Roles and Responsibilities

FloodGuard provides different access levels to ensure that each user can perform functions appropriate to their responsibilities.

| User Role | Responsibilities |
|---|---|
| **Administrator** | Configures system settings, manages users and roles, configures IoT sensors and monitoring parameters, and oversees system operations. |
| **Staff** | Reviews and approves or rejects resident incident reports and newsfeed posts, assigns incidents to responders, and monitors emergency response activities. |
| **Resident** | Views bridge conditions, receives push notifications, submits incident reports and newsfeed posts, and tracks assigned responders. |
| **Responder** | Receives and reviews assigned incidents, accepts assignments, views reporting residents' locations, and shares GPS location during emergency response. |

## System Architecture

FloodGuard consists of three major components that work together:

| Component | Description |
|---|---|
| **IoT Monitoring Station** | Uses ESP32 and connected sensors to collect environmental readings and activate local warning mechanisms. |
| **Web-Based Platform** | Provides system administration, user and sensor configuration, monitoring, incident management, newsfeed moderation, and responder coordination. |
| **Mobile Applications** | Provides residents and responders with mobile access to monitoring information, notifications, incident reporting, and GPS-based emergency coordination. |

### System Workflow

1. **Environmental Data Collection** – The ESP32 monitoring station collects readings from the connected water-level, rain, and wind sensors.
2. **Data Transmission** – The monitoring station transmits collected readings to the backend server.
3. **Data Processing and Storage** – The backend validates and processes the incoming data before storing it in the MySQL database.
4. **Bridge Condition Assessment** – The system evaluates sensor readings using configured thresholds to determine the current bridge condition.
5. **System Configuration** – The Administrator manages system settings, user accounts, sensor configurations, and monitoring parameters.
6. **Public Monitoring and Notifications** – Residents can view bridge conditions and receive push notifications about relevant alerts and announcements.
7. **Incident and Post Submission** – Residents can submit incident reports and community newsfeed posts through the mobile application.
8. **Staff Review and Moderation** – Staff review submitted incident reports and newsfeed posts, then approve or reject them.
9. **Incident Assignment** – Staff assign approved incident reports to appropriate responders.
10. **Emergency Response and GPS Coordination** – Responders receive and accept assignments, view the reporting resident's location, and share their own GPS location for response coordination.

## Technologies Used

### Hardware

- ESP32 Microcontroller
- Waterproof Ultrasonic Water-Level Sensor
- Rain Sensor
- Wind Speed Sensor
- Obstacle Sensors
- A7670E 4G LTE Cat-1 Module
- DFPlayer Mini Audio Module
- Relay Module
- Siren and Speaker
- Servo Motors
- Rechargeable Battery System

### Web Application and Backend

- PHP
- MySQL
- HTML5
- CSS3
- JavaScript
- REST API

### Mobile Application

- Flutter
- Dart
- GPS and Location Services
- Push Notification Technology
- REST API Integration

### Development Tools and Platforms

- Visual Studio Code
- XAMPP
- phpMyAdmin
- Git
- GitHub
- Arduino IDE

## Database

FloodGuard uses **MySQL** as its relational database management system.

The database stores information required by the web platform, IoT monitoring station, and mobile applications, including system users, sensor readings, bridge monitoring data, incident reports, newsfeed submissions, responder assignments, and other application records.

**Database Name:** `floodguard_db`

**SQL Database File:** `database/u597559795_floodguard_db.sql`

### Importing the Database

1. Install and run XAMPP.
2. Start Apache and MySQL.
3. Open phpMyAdmin at `http://localhost/phpmyadmin`.
4. Create a database named `floodguard_db`.
5. Select the newly created database.
6. Open the **Import** tab.
7. Choose `database/u597559795_floodguard_db.sql`.
8. Click **Import** or **Go** to execute the SQL file.

## Installation and Setup

### 1. Clone the Repository

```bash
git clone https://github.com/jerichooo1/FloodGuard.git
```

Navigate to the project directory:

```bash
cd FloodGuard
```

### 2. Set Up the Web Application

1. Install XAMPP.
2. Copy the web application files into your XAMPP `htdocs` directory.
3. Start Apache and MySQL from the XAMPP Control Panel.
4. Create and import the `floodguard_db` database using phpMyAdmin.
5. Configure the database connection settings in the appropriate backend configuration file.
6. Update the API and application configuration to match your local environment.
7. Open the web application through your local server.

### 3. Set Up the Flutter Mobile Application

Navigate to the mobile application directory:

```bash
cd mobile
```

Install the required Flutter dependencies:

```bash
flutter pub get
```

Configure the application's API base URL to point to your backend server.

Run the application:

```bash
flutter run
```

**Note:** The actual API base URL and device configuration depend on the development or deployment environment. A mobile device or emulator must be able to reach the backend server.

### 4. Set Up the IoT Monitoring Station

1. Prepare the ESP32 monitoring station and required sensors.
2. Connect the sensors and warning components according to the hardware configuration.
3. Configure the Wi-Fi or network connectivity and backend API settings.
4. Configure the required monitoring thresholds.
5. Upload the appropriate firmware to the ESP32.
6. Verify that the monitoring station can transmit sensor readings to the backend.
7. Test the sensor readings and local warning mechanisms.

## Repository Structure

The repository contains the web application, mobile application, database resources, and related project files.

```text
FloodGuard/
│
├── database/
│   └── u597559795_floodguard_db.sql
│
├── mobile/
│   └── Flutter mobile application source code
│
├── Web Application/
│   └── PHP, HTML, CSS, JavaScript, and backend files
│
└── README.md
```

*Note: The directory names above provide a simplified overview. Actual web application folders and files may vary depending on the project structure.*

## Project Significance

FloodGuard aims to support Barangay San Isidro in improving bridge monitoring, public safety communication, and emergency response coordination.

By integrating IoT technology, a centralized web platform, and mobile applications, the system provides a more accessible way to monitor environmental conditions, inform residents, manage incident reports, and coordinate responders.

It also promotes community participation by allowing residents to submit reports and newsfeed updates while maintaining staff review and approval to help ensure that published information is properly moderated.

## Disclaimer

FloodGuard is an academic project developed to support bridge monitoring, public safety communication, and emergency response coordination.

The system is intended as a supplementary monitoring and communication solution. It does not replace official disaster risk reduction procedures, professional emergency services, authorized bridge closure decisions, or official government advisories.

Actual emergency decisions and response operations should remain under the authority of the appropriate local government offices and emergency response personnel.

## Repository

**GitHub:** https://github.com/jerichooo1/FloodGuard

---

**FloodGuard – Monitoring Conditions. Informing Communities. Supporting Emergency Response.**
