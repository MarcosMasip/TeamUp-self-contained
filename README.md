# Team Up! :partying_face:

## Self-Contained Edition (2025 Refresh)

This repository has been upgraded to be fully reproducible and offline‑capable: one command to prepare, one to run. All previous documentation follows below; this section summarizes the new operational model.

### Quick Start (TL;DR)

```bash
git clone https://github.com/MarcosMasip/TeamUp-self-contained.git
cd TeamUp-self-contained
chmod +x scripts/*.sh   # only needed if execute bits were stripped
./scripts/prepare.sh    # builds images OR prepares local fallback
./scripts/start.sh      # launches stack
```

Windows PowerShell (analog):
```powershell
git clone https://github.com/MarcosMasip/TeamUp-self-contained.git
cd TeamUp-self-contained
pwsh ./scripts/prepare.ps1
pwsh ./scripts/start.ps1
```

If you prefer a single chained command (Unix-like):
```bash
git clone https://github.com/MarcosMasip/TeamUp-self-contained.git && cd TeamUp-self-contained && chmod +x scripts/*.sh && ./scripts/prepare.sh && ./scripts/start.sh
```

### First-Time Clone Checklist (Recommended)
1. Clone & cd into directory.
2. (Optional) Ensure shell scripts are executable:
  ```bash
  chmod +x scripts/*.sh
  ```
3. (Optional) Inspect platform prerequisites & versions:
  ```bash
  ./scripts/check-platform.sh
  # or: pwsh ./scripts/check-platform.ps1
  ```
4. Run prepare (downloads deps / builds images):
  ```bash
  ./scripts/prepare.sh
  # or: pwsh ./scripts/prepare.ps1
  ```
5. Start the stack:
  ```bash
  ./scripts/start.sh
  # or: pwsh ./scripts/start.ps1
  ```
6. Verify (optional but fast):
  ```bash
  ./scripts/health.sh
  ```
7. Log in via browser (admin creds below in Step-by-Step section).

### Permission Denied? (macOS/Linux)
Example:
```bash
./scripts/prepare.sh
zsh: permission denied: ./scripts/prepare.sh
```
Cause: File execute bits lost (often due to downloading a ZIP or certain SCM settings).
Fix:
```bash
chmod +x scripts/*.sh
./scripts/prepare.sh
```
Alternative (without changing bits) you can invoke explicitly:
```bash
bash scripts/prepare.sh
```

---

Then visit:
- Frontend (Docker mode): http://localhost:${APP_FRONTEND_PORT:-4200}
- Backend API: https://localhost:${APP_BACKEND_PORT:-8443}/api
- Mail (mock inbox – Mailpit): http://localhost:8025

Fallback (no Docker detected):
- Backend (H2 in‑memory profile) runs with `local-h2` Spring profile.
- Angular dev server (HTTPS) runs locally.

Stop services:
- Docker mode: `docker compose down`
- Fallback: Ctrl+C in terminal.

### Step-by-Step First Run (With Expected Output)

The examples below show a typical first clone on a machine that DOES have Docker running. Lines starting with `#` are comments; `→` indicates truncated example output.

#### 1. Clone & Enter
```bash
git clone https://github.com/MarcosMasip/TeamUp-self-contained.git
cd TeamUp-self-contained
```

#### 2. (Optional) Verify Tooling
```bash
./scripts/check-platform.sh
# Java: openjdk version "1.8.0_..."
# Node: v14.21.3
# Docker: Docker version 26.x.x, build ...
# Docker Compose: plugin available
```

Windows PowerShell equivalent:
```powershell
pwsh ./scripts/check-platform.ps1
```

#### 3. Prepare
```bash
./scripts/prepare.sh
# [prepare] Mode: docker
# Building backend image...
# Sending build context to Docker daemon  →
# Step 1/.. FROM eclipse-temurin:8-jdk
#  ... (Maven dependency:go-offline) ...
#  ... (Packaging jar) ...
# Building frontend image...
#  ... (npm ci) ...
#  ... (Angular production build) ...
# Pulling dependent images (postgres, mailpit)...
# Running offline verification...
# [offline-verify] PASS: No external URL references detected.
# Done. Run ./scripts/start.sh
```

If Docker is NOT available you will instead see:
```
[prepare] Mode: fallback
Fallback mode (no Docker). Ensuring Java & Node present.
... (Maven dependency:go-offline) ...
... (npm ci) ...
Running offline verification (advisory)...
Offline verification passed.
Fallback prepare complete. Run ./scripts/start.sh
```

PowerShell (Windows) version:
```powershell
pwsh ./scripts/prepare.ps1
```
Or double‑click `scripts/prepare.cmd`.

#### 4. Start
```bash
./scripts/start.sh
# Starting services (docker compose)...
# Creating network ... →
# Creating volume  ... →
# Creating container db ...
# Waiting for database port...
# [retry] Attempt 1 failed, retrying in 2s... (if slow)
# Waiting for backend health...
# Application started.
# Frontend: http://localhost:4200
# Backend API: https://localhost:8443/api
# Mail UI: http://localhost:8025 (if using mail)
# Admin login: admin@admin.com / adminadmin
```

Fallback (no Docker) output example:
```
Starting fallback local mode...
Backend PID 12345
Frontend PID 12346
Press Ctrl+C to stop.
```

PowerShell (Windows):
```powershell
pwsh ./scripts/start.ps1
```
Or double‑click `scripts/start.cmd`.

#### 5. Verify Health
```bash
./scripts/health.sh
# Checking backend...
# Backend OK
# Checking frontend...
# Frontend OK
# All healthy.
```
PowerShell:
```powershell
pwsh ./scripts/health.ps1
```

Manual curl check:
```bash
curl -k https://localhost:8443/api/health
{"status":"UP"}
```

#### 6. Log In (Browser)
Visit `http://localhost:4200` and use:
- Email: `admin@admin.com`
- Password: `adminadmin`

#### 7. Stop
```bash
docker compose down  # Docker mode
# OR (fallback) use Ctrl+C in the terminal running the processes
```

#### 8. One-Liner (Unix-Like)
```bash
git clone https://github.com/MarcosMasip/TeamUp-self-contained.git \
&& cd TeamUp-self-contained \
&& ./scripts/prepare.sh \
&& ./scripts/start.sh
```

#### 9. Common First-Run Issues
| Symptom | Example Log Snippet | Action |
|---------|---------------------|--------|
| Permission denied | `zsh: permission denied: ./scripts/prepare.sh` | `chmod +x scripts/*.sh` then retry |
| Docker engine not running | `Cannot connect to the Docker daemon` | Start Docker Desktop or run fallback mode (leave as-is) |
| Slow backend start | Repeated health poll | Wait; Postgres init on first run can take ~5–15s |
| Port in use (fallback) | `Port 4200 already in use. Abort.` | Change `APP_FRONTEND_PORT` in `.env` or free the port |
| Cert warning | Browser HTTPS warning | Accept self-signed cert locally |

---

### Architecture Overview

| Layer        | Technology | Notes |
|--------------|------------|-------|
| Backend API  | Spring Boot (Java 8) | JWT auth, health endpoint `/api/health`, optional mock mail |
| Database     | PostgreSQL 13 | Volume persisted in Docker; H2 in fallback profile |
| Frontend SPA | Angular 12 + Bootstrap 4 | Served by Nginx in production container |
| Mail Testing | Mailpit | Captures outgoing mails (currently mocked/logged) |
| Reverse Proxy| Nginx (frontend container) | Static SPA + asset serving |

### Run Modes

| Mode | Trigger | DB | Mail | TLS | Notes |
|------|---------|----|------|-----|-------|
| Docker (default) | Docker present & usable | Postgres | Mailpit | Backend HTTPS (self-signed) | Recommended for parity |
| Fallback Local   | Docker missing/unavailable | H2 in‑memory | Logging mock | Self-signed frontend, backend HTTPS | Dev convenience |

### Environment Variables (`.env`)
Create `.env` from `.env.example` (done automatically by `prepare.sh` if absent). Key variables:

| Variable | Purpose | Example | Fallback Default |
|----------|---------|---------|------------------|
| APP_BACKEND_PORT | Exposed backend HTTPS port | 8443 | 8443 |
| APP_FRONTEND_PORT | Exposed frontend HTTP port (Nginx / dev) | 4200 | 4200 |
| POSTGRES_PORT | Host Postgres port | 5432 | 5432 |
| POSTGRES_DB | Database name | app | app |
| POSTGRES_USER | DB user | appuser | appuser |
| POSTGRES_PASSWORD | DB password | apppass | apppass |
| CORS_ALLOWED_ORIGINS | Comma list for CORS | https://localhost:4200 | Injected into Spring |
| JWT_SECRET | Signing key (change in prod) | change-me-please | fallback profile has a dev value |
| FILE_UPLOAD_DIR | Host directory for uploaded files | ./uploads | Mounted volume |

### Offline Guarantee

- All 3rd-party CSS/JS previously loaded via CDN (Bootstrap, Font Awesome, jQuery, Popper, Google Fonts) are now bundled locally.
- Custom font usage uses local `@font-face` declarations (place actual font files under `socialnetworkingapp-front/src/assets/fonts/`).
- Verification: `./scripts/offline-verify.sh` (automatically run inside `prepare.sh`). Script fails the Docker build path if external URLs are detected (excluding localhost/mailpit).

### Health & Verification

| Command | What it checks |
|---------|----------------|
| `./scripts/health.sh` | Backend `/api/health` returns UP, frontend root loads |
| `./scripts/offline-verify.sh` | Scans source for `http(s)://` references outside allowed list |

### Dev Mode (Hybrid)

Run backend locally (Hot reload via Spring dev tools if added later) and Dockerized infra for db & mail:
```
./scripts/dev.sh
```

### Security Notes
* Never commit a real production `JWT_SECRET`.
* Self-signed certificate used for local HTTPS; trust manually if browser warns.
* CORS origins now centrally controlled by `CORS_ALLOWED_ORIGINS`.

### Cross-Platform Usage (macOS / Linux / Windows)

All automation now ships with both POSIX shell (`.sh`) and PowerShell (`.ps1`) variants plus simple `.cmd` launchers for Windows double‑click usage.

Prerequisites (all platforms):
- Git
- Java 8 (Temurin / OpenJDK) available on PATH (fallback & dev modes)
- Node.js 14.x (as per `.nvmrc`) for fallback & dev modes (Docker mode builds inside containers)
- Docker Desktop / Engine (if you want full Docker mode; otherwise fallback engages automatically)

Windows specifics:
- Open a PowerShell terminal (v5+ or PowerShell 7+ recommended).
- If scripts are blocked, temporarily allow: `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass`.
- Use either: `pwsh ./scripts/prepare.ps1` then `pwsh ./scripts/start.ps1` OR just double‑click `scripts/prepare.cmd` then `scripts/start.cmd` in Explorer.

macOS / Linux:
- Ensure scripts are executable: `chmod +x scripts/*.sh` (already committed with +x if cloned on a Unix filesystem).
- Run: `./scripts/prepare.sh` then `./scripts/start.sh`.
 - If you see `permission denied: ./scripts/prepare.sh`, your clone lost execute bits (e.g. due to ZIP download or filesystem). Fix with: `chmod +x scripts/*.sh` then re-run.

Ports & Conflicts:
- Backend: `${APP_BACKEND_PORT:-8443}` (HTTPS)
- Frontend: `${APP_FRONTEND_PORT:-4200}` (HTTP in Docker / Angular dev server in fallback)
- Postgres: `${POSTGRES_PORT:-5432}`
- Mailpit: `8025`
If a port is taken in fallback mode, the shell/PowerShell scripts abort with a clear message.

Line Endings:
- All committed scripts use LF. If you clone on Windows with core.autocrlf=true and encounter execution issues, run: `git config core.autocrlf false` and re‑checkout, or convert with: `dos2unix scripts/*.sh`.

Environment File:
- If `.env` is absent, `prepare` scripts copy `.env.example` automatically. Customize values there before `start` if you need different ports or secrets.

Docker Compose Variants:
- Scripts auto‑detect `docker compose` (plugin) vs legacy `docker-compose` binary; no user action needed.

Troubleshooting Quick Reference:
| Symptom | Likely Cause | Fix |
|---------|--------------|-----|
| PowerShell script blocked | Execution policy | Run temporary bypass command above |
| Backend health fails in Docker start | Slow Postgres init | Re-run `./scripts/start.sh`; readiness retry already built-in |
| Frontend 404 in browser (Docker mode) | Angular build not yet served / container not up | Wait a few seconds or check `docker compose ps` |
| Port already in use (fallback) | Another service occupying 4200/8443 | Stop conflicting process or change port in `.env` |

### Platform Validation (Optional)
You can add (or we may later include) a `scripts/check-platform.sh` / `.ps1` to print detected versions. For now, quickly check:
```
java -version
node -v
docker --version
```
If any are missing (and you rely on fallback/local), install them before proceeding.

### Future Enhancements (Preview)
Roadmap ideas (see full backlog section to be added below):
- Migrate to Bootstrap 5 (remove jQuery dependency)
- WebSocket or SSE chat (replace polling)
- Actuator endpoints & metrics
- Automated E2E tests (Cypress / Playwright)
- SBOM & security scanning (Trivy, OWASP Dependency Check)

---
#### A professional networking application for the course *Web Development Technologies* in collaboration with [Christos Laspias](https://github.com/ChrisLaspias).

## 0. Abstract
### 0.1. Main goal
The purpose of this project is multidimensional. First of all, TeamUp is designed to provide all
the necessary services of a modern professional networking application. The main features
which were taken into account during the design are:
- Minimalism.
- Ease of use.
- Simple and clean design.
- Security.

TeamUp smoothly combines the functionalities of a **social networking application** and a
**job recruiting site**, so that everyone can:
- Publish posts (including photos, videos and sound clips!) and react to them.
- Chat with teammates.
- Make new connections.
- Seek and apply for a job position.
- Maintain a CV-like profile and have the chance to hide sections of it without having to
display every information publicly.
- Have **100% control** over their personal data with the option to fully delete their
account, if requested.

### 0.2. What follows
The documentation is separated into **5 main sections**:
1. Usage.
2. Backend.
3. Frontend.
4. Database Management.
5. Filtering algorithms applied.
6. Gallery.

Each of the **Backend** and **Frontend** sections:
- Starts with the presentation of the **framework** used to develop the respective end.
- Continues by analysing the **security features** added in order to shield the app.
- Ends with a detailed description of the **components** and their functional
contribution to the app, along with some **business logic**.

**Database Management** section, refers to the object-relational database system used to
store application’s data and to the automated script that loads sample information during
app’s startup.

The **5th section** offers a thorough description of the logic between **job** and **post filtering**.
The aforementioned filtering is being implemented with the use of Matrix Factorization, a
collaborative filtering algorithm used in Recommendation Systems.

## 1. Usage
> NOTE: The legacy usage section below predates the self-contained scripting workflow. Prefer the Quick Start at the top for current instructions.
### 1.1. SSL Certificate
Before launching the application, there may be need to trust the app’s
self-signed certificate ```server.crt```, which is located under:
```socialnetworkingapp-front/src/ssl/```

### 1.2. Compose & Run
In order to deal with environment disparity across different machines and
platforms, the project is deployed using **Docker**. 
- In project's root directory, run ```install.sh``` with **root privileges**. The script creates a docker image for the backend and the database and runs them in different containers. **In case it fails, you should install PostgreSQL to your system, create an empty database named ```app``` and change ```spring.datasource.username``` and ```spring.datasource.password``` which are located under ```src/main/resources/application.properties``` according to your credentials.**

- For the front-end, run ```install.sh```, located under ```/socialnetworkingapp-front``` directory.
- Backend runs on https://localhost:8443.
- Front end runs on https://localhost:4200.
- PostgreSQL runs on localhost:5432.

## 2. Backend

### 2.1. Framework
The framework used to develop TeamUp’s back end is Spring Boot. Spring Boot is
an open source Java-based framework which provides a **RESTful API** and allows you to
create stand-alone, production-grade Spring based Applications.

### 2.2. Security
In order to ensure that TeamUp is secure, spring security was used in the backend.
After a successful login, every user gets a json web token and can therefore use the web application.
A non-registered/ non-logged-in user can either register or log into the application. In the backend, every
http request should have a token attached to its headers in order for every user to be authenticated. The
validity of the token is ensured with the assist of spring security and jwt library. Some requests
require admin privileges to be performed. This check is also performed with the help of json
web tokens. The application runs over https with the help of a self-signed certificate. The
backend redirects all http traffic to https. Finally, in order to authorize requests from the
frontend and get access to the api, we implemented a CORS filter, in order to allow all traffic from the
frontend.

### 2.3 Model
#### 2.3.1 Entities
The entities that make up the application are the following:
- **Account**: Every registered user has an account that stores their basic
information.
- **Bio**: Abbreviation for *Biography*. An account can either have a bio associated
with it, or not. If a user has a bio, he/she can edit or delete it at any time. On
the other hand, if a user does not have a bio, he/she can create a new one.
- **Like**: A user can add a like to a post. If already liked, he/she can remove the
like at any time.
- **Comment**: A user can add one or more comments to a post. Also, the user has
the freedom to edit or delete his/her comment.
- **Connection Request**: When a user A visits the profile of another user B that is
not present in his network of connected users, A can send a connection
request to B, in order to form a connection. User B can either accept or reject
incoming connection requests.
- **Education**: Entity that holds all basic information of education, such as School
or University that someone studied, GPA, starting and ending date (if the user
has already graduated) etc.
- **Experience**: Entity that holds all basic information of working experience,
such as the Company’s name that someone worked in, workplace,
employment type, starting and ending date (if exists) etc.
- **Job**: Represents an article about a job in which users can apply.
- **Job Application**: Via this entity, a user can apply to a job and if necessary,
cancel an already existing job application.
- **Job View**: When users click to a job article, their views are being collected in
order for the recommendation system to work properly and tailor the job
articles to each user’s taste. The job creator’s views are not being counted in
the system.
- **Message**: A user can chat with his/her available connections at any time.
- **Post**: A user can publish a post that may contain text, image, video or even a
sound clip. Also, a user can edit a post’s caption, if needed.
- **Post View**: When users click to a post, their views are being collected in order
for the recommendation system to work properly and tailor the posts to each
user’s taste. The post creator’s views are not being counted in the system.
- **Tags**: Tags (or Interests) are a few keywords that represent different object
fields and are associated with accounts and jobs. For example, a user that may
be interested in Machine Learning and Software Engineering, will pick the
tags MACHINE LEARNING and SOFTWARE ENGINEERING to be appended to
his/her profile. Similarly, if a job article is e.g hardware-oriented, the job’s
creator will append the proper tags to the article. Tags are of major
importance when it comes to recommending job articles to users (See section
5.).

#### 2.3.2 Mappers
There’s a significant difference between the internal entities of the
application and the external objects that are being published back to the client. There are
loads of fields that are completely unnecessary for the client to see, for both data integrity
and security reasons. That’s why mappers have been implemented in this application. For
example, if a class A has 10 fields but there’s only need for the 3 of them to be published
back to the client, a mapper converts class A to another defined class B, which contains only
the essential info. Mappers can be found under the ```/mapper``` folder in backend’s source
files.

## 3. Frontend
### 3.1. Web Framework
The framework used to develop TeamUp’s front end is Angular. Angular is a
TypeScript-based free and open-source web application framework and one of the most
popular platforms for building mobile and desktop web applications.

### 3.2. Security
Security in the front-end was achieved with the help of Angular’s Authentication
Guard and Local Storage. Every end-point of our application requires a user to be
logged in. After every successful login, local storage saves the token provided by the backend and
user’s unique email address. That way, we can identify the current logged-in users by
looking up the local storage. Frontend also runs over https with the help of a self-signed
certificate. Last but not least, we implemented a token interceptor that attaches the token
from local storage to every request. That way, every request that has a token attached to it’s
headers can be authenticated from the backend. Also, the interceptor attaches another
header in order to make the backend capable of recognizing the frontend.

### 3.3 Model
#### 3.3.1 Usage and functionality of pages
A brief description of the frontend’s functionality is as follows:
- **Landing page**: Welcome page, where a guest can either sign in (if he/she
already has an account) or register a new account.
- **Home page**: Page where a user can create a new post, or browse other user’s
posts and react to them. The user can see his/her full name and profile
picture on the left part of the page and also visit his/her profile or his/her
network with a single click.
- **Profile**: Overview of a user’s information summed up in a page. The user can
modify his/her profile information by adding, editing and deleting them, or
by changing their visibility.
- **Settings**: Section where a user can change his personal information, including
his/her email and password. Also, in this section the user has the freedom to
completely delete his/her account.
- **Network**: Page where all user’s contacts are being displayed in the form of
animated cards. Each card shows the picture, the full name, the email and the
current working position of the respective contact (if exists). By clicking to
any of the contact cards, the user is being redirected to the corresponding
contact’s profile. The search bar on the top right, is implemented to support
live search, in order for the user to seek registered users that are not present
to his/her network.
- **Jobs**: Section dedicated to job browsing. Every user can unfold a job article,
read its information and apply to the indicated job position. Job creators can
also edit and delete their job articles and furthermore see a list of the
viewers and the applicants for each one of their articles.
- **Notifications**: Dropdown consisting of three (3) pop-ups. A logged user can
review his/her received connection requests, the likes and the comments on
his/her posts.
- **Chat**: Place where a user can chat with anyone from his/her network. The user
can either continue a discussion that has already begun, or create a new one
by clicking the appropriate button on top left. Chatting has been
implemented using Polling technique.
- **Log out**: Sign out button.
- When a user A visits another user’s B account, there may be differences in the
page’s appearance:
  - If user A is connected with B, then A can directly chat with B by clicking
the corresponding button, or remove B from his/her network.
  - If user A is **not** connected with B, he/she can send a connection
request to user B. Then, A can either wait for B to accept the request,
or cancel it. When user B logs into the application, he/she can accept
the connection request by checking his/her notifications, or by visiting
A’s profile, where an indicative button appears.
- **Admin** has access to admin’s page, where he/she can:
  - View a list of all the registered users in the application.
  - Visit any user’s profile, by clicking on his/her full name.
  - View a brief overview of any user by clicking the button with the
question mark on the right side.
  - Delete any user by clicking the button with the X mark on the right
side.
  - Search for users by their full name.
  - Reload the user list.
  - Add a new account.
  - Export in XML and JSON format user data by selecting one or more of
them.

## 4. DBMS
The database management system used to store TeamUp’s data is PostgreSQL.
Postgres is a free and open-source relational database management system (RDBMS)
emphasizing extensibility and SQL compliance.

### 4.1. File System
In TeamUp, users can upload images, videos and sound clips. Therefore, in order for
them to be properly stored in the database, a service has been implemented under
```/filesystem``` directory, in project’s source files. Whenever a file is successfully
uploaded in app’s database, it can be retrieved by visiting the link:
```{backend server’s address:port number}/api/files/{file_id}```
e.g: ```https://localhost:8443/api/files/e52fb3dd-19d0-4e7c-84bd-0f756a962bfb```

*(if the backend server is running on localhost, in port 8443)*

### 4.2 Sample data
In order for TeamUp to provide sample data right out of the box, there is a file
located in ```/src/main/resources``` called ```import.sql```. The aforementioned file
inserts accounts, network connections, biographies, posts, likes, comments, education,
experience events, jobs, views and tags into the app’s database.
**Notes**:

1. All of the sample users have the same password “12345678”.
2. **Admin** initially has the following credentials: 
    1. **email**: admin@admin.com
    2. **password**: adminadmin

Admin’s credentials can then be changed by the admin, by visiting “Settings” page.


## 5. Matrix Factorization Collaborative Filtering
Both job and post filterings have been implemented with the use of Matrix
Factorization technique, in order to tailor both job articles and posts to each individual user’s
preferences. Matrix-factorization based approaches prove to be highly accurate and scalable
in addressing collaborative filtering problems.

M.F implementation in Java is present under the ```/util``` folder, in the project's
source files. The recommendation algorithm for jobs can be found in:
```src/main/java/com/example/socialnetworkingapp/model/job/JobService.java```
in ```getJobs()``` function, while the recommendation algorithm for posts can be found in:
```src/main/java/com/example/socialnetworkingapp/model/post/PostService.java```
in “findAllPosts()” function.

The business logic behind each filtering is fully developed below.

### 5.1. Job filtering
1. Collect all jobs and every user’s contact.
2. If the current authenticated user has seen every available job article, proceed to *Tag
Filtering*. For every Job, see how many tags the job and the user have **in common** and
for every matching tag, add one (1) view.
3. If current authenticated user has not seen all the available jobs:
    1. Run Matrix Factorization. The filter will take advantage of the jobs’ views, in
order to construct the vectors that represent users in the jobs space.
    2. Proceed to *Tag Filtering*. For every Job, see how many tags the job and the
user have in **common** and for every matching tag, add +10% of the previous
value of views.
4. Finally, sort by the largest value of views and return the resulting jobs.

### 5.2. Post filtering
1. Gather all posts (P), that:
    1. A user has made.
    2. A user's friend has made.
    3. A user's friend has liked.
2. Sort (P) by creation date (latest first!).
3. If (P) have no likes and no comments:
    1. If (P) have no views or the current user has seen all of (P):
        1. Sort and return a list (L) based on the degree of relationship of the
current user with the publishers of the posts (P). Initially, show the
posts that connected users have posted (network first), then show the
posts that connected users have liked (non-network posts) and finally
present the posts that the current authenticated user has published.
    1. If (P)'s views are non-empty:
        1. Run Matrix Factorization to (P). The filter will take advantage of the
posts’ views, in order to construct the vectors that represent users in
the posts space.
4. If (P) have some likes or/and comments:
    1. If current user has not seen all of (P):
        1. Run Matrix Factorization to (P) the same way as above.
    2. Parse the current user’s vector of views in posts and:
        1. For each liked post add 100% of the already existing views in that
post.
        2. For each comment in a post add 50% of the already existing views in
that post.
5. Sort by most viewed posts.
6. Sort and return the resulting list the same way as (3.a.i).

## 6. Gallery
![landing](https://github.com/spChalk/TeamUp/blob/main/Gallery/landing.png)
![register](https://github.com/spChalk/TeamUp/blob/main/Gallery/register.png)
![admin](https://github.com/spChalk/TeamUp/blob/main/Gallery/admin.png)
![homepage](https://github.com/spChalk/TeamUp/blob/main/Gallery/homepage.png)
![post](https://github.com/spChalk/TeamUp/blob/main/Gallery/post.png)
![jobs](https://github.com/spChalk/TeamUp/blob/main/Gallery/jobs.png)
![network](https://github.com/spChalk/TeamUp/blob/main/Gallery/network.png)
![profile](https://github.com/spChalk/TeamUp/blob/main/Gallery/profile.png)
![notifications](https://github.com/spChalk/TeamUp/blob/main/Gallery/comments.png)
![settings](https://github.com/spChalk/TeamUp/blob/main/Gallery/settings.png)
![chat](https://github.com/spChalk/TeamUp/blob/main/Gallery/chat.png)

## 7. Sources
- https://stackoverflow.com/
- https://www.baeldung.com/
- https://www.gitmemory.com/
- https://www.bezkoder.com/
- https://www.bootdey.com/
- https://getbootstrap.com/
- https://amigoscode.com/
- https://newbedev.com/
- https://codecraft.tv/
- https://roytuts.com/

---

## Future Enhancements Backlog (Operational Refresh)

| Area | Idea | Rationale |
|------|------|-----------|
| Frontend UI | Migrate to Bootstrap 5 / remove jQuery | Smaller bundle, modern components |
| Realtime | Replace polling chat with WebSocket (STOMP) or SSE | Lower latency, efficiency |
| Observability | Add Spring Boot Actuator + Prometheus/OpenTelemetry | Production metrics & tracing |
| Security | Integrate vulnerability scanning (Trivy, OWASP Dependency Check) | Supply chain safety |
| Auth | Rotate JWT secret via KMS/Secrets Manager abstraction | Secure secret lifecycle |
| Testing | Add API tests (REST Assured) + E2E (Playwright/Cypress) | Confidence & regression safety |
| Performance | Add lazy loading routes & code splitting | Faster initial paint |
| Packaging | Multi-arch Docker images (buildx) | Wider deployment targets |
| Accessibility | ARIA audits & semantic improvements | Inclusive UX |
| DB | Flyway or Liquibase baseline migration | Controlled schema evolution |

## Fonts
Local `@font-face` declarations reference placeholder Montserrat files under `socialnetworkingapp-front/src/assets/fonts/`. Supply actual `.woff2` / `.woff` files (only needed weights) to avoid licensing surprises and reduce bundle size.

### Node & NPM Fallback Strategy (NEW 2025 Refresh)
The project targets Node.js 14.x for local *fallback* and *dev* modes (see `.nvmrc`). If you have a newer Node (18+ / 20+ / 22+ / 24+), strict peer dependency resolution and an outdated `package-lock.json` could otherwise break first install.

Our `prepare` scripts now implement an adaptive strategy:
1. Attempt `npm ci` (fast, reproducible) when a lock file exists.  
2. If it fails due to lock mismatch / peer conflicts / engine warnings, the script automatically:  
   - Removes the stale `package-lock.json`.  
   - Runs `npm install --legacy-peer-deps` to generate a fresh lock aligned with the current `package.json`.  
3. Subsequent runs will succeed with `npm ci` using the regenerated lock.

Implications:
- You may see a large `package-lock.json` change on the first run after updating to this self-contained refresh. Commit it once in feature branches; the main branch will carry the canonical lock.
- For the **most deterministic** local experience (and for CI), use Node 14.x (`nvm install 14 && nvm use 14`).
- The fallback uses `--legacy-peer-deps` only when necessary (it does **not** mask other errors—if the second step fails, you will see a clear error suggesting Node 14).

Verify your Node version quickly:
```bash
node -v   # Expect v14.x for a clean reproducible path
```
If it prints a much higher major version and you want fully strict installs, switch with `nvm` or similar.

### Generated .env Handling
If `.env` is missing, `prepare` copies `.env.example` -> `.env`. The root `.gitignore` now ignores `.env` so your local edits (ports, secrets) never appear as untracked noise.
