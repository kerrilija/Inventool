# Inventool: A user-friendly CNC Tool inventory

Inventool is a cross-platform desktop application ( [macOS](#macos) / [Linux](#linux) / [Windows](#windows) ) made with Flutter, utilizing [PostgreSQL](https://www.postgresql.org/). It's specifically designed to meet the requirements of a CNC machining workshop and replace inefficient Excel spreadsheets.

<table>
  <tr>
    <td><img src="https://github.com/kerrilija/Inventool/assets/82002056/1761a22d-dfa7-4fe9-ad73-595cf3c97f11" alt="Inventol Home"></td>
    <td><img src="https://github.com/kerrilija/Inventool/assets/82002056/195583b1-e38e-4f3f-a7a5-8f1bf4d26abe" alt="Inventool Search"></td>
  </tr>
</table>

## Features

Learn about features more in-depth on [Inventool Wiki](https://github.com/kerrilija/Inventool/wiki)

- Tool Location Tracking: Easily identify which machine each tool is assigned to.
- Quick and Intuitive Search: Autocomplete functionality with straightforward filters, optimized for keyboard use to reduce mouse dependency.
- Tool Management: Issuing, returning, disposing, inserting new and editing existing tools is simple, as well as quantity tracking.
- Daily Activity Log: History overview of all tool-related actions for tracking and reference.
- Advanced Inventory Visualization: Manage inventory with a clear view of cabinets, drawers, and sections, enabling quick assessment of quantities.

# Installation & Requirements

## Requirements: 
- **PostgreSQL server instance** on your localhost (a simple installation method using [Docker](https://www.docker.com/) is also available).
- Use the existing pre-built executables **OR** use [Flutter SDK](https://docs.flutter.dev/tools/sdk) to build the project.
- If you're running a local PostgreSQL server without Docker, create a database called `tooldb`, execute "init.sql" located in inventool/docker/ and make sure you're using the following credentials:

```
host: localhost
port: 5432
database: tooldb
username: postgres
password: postgres123
```

NOTE: If you're using Docker, ensure that virtualization is enabled in your BIOS settings. 

## Windows

1. [Download and install Docker](https://docs.docker.com/desktop/install/windows-install/) if it's not already installed.
2. Start Docker.
3. Open your Command Prompt or Powershell.
4. Navigate to a folder where you would like to clone the repository.
5. Clone the repository:

    `git clone https://github.com/kerrilija/Inventool.git`

6. Start PostgreSQL Server instance in a Docker container: 

    `cd inventool/docker && docker-compose up`

7. Download [Inventool executable](https://github.com/kerrilija/Inventool/releases/download/v1.0.0/inventool_win_build.zip)
8. Extract the zip and start inventool.exe
9. When the application starts, in the top menu, click on "Import to SQL".
10. Click on "Tool CSV".
11. When the file picker shows up, navigate to inventool/docker/data/ and select tool_inventory.csv
12. Application is ready to use. 

## macOS

1. [Download and install Docker](https://docs.docker.com/desktop/install/mac-install/) if it's not already installed.
2. Start Docker.
3. Open your macOS Terminal.
4. Navigate to a folder where you would like to clone the repository.
5. Clone the repository: 

    `git clone https://github.com/kerrilija/Inventool.git`

6. Start PostgreSQL Server instance in a Docker container:

    `cd inventool/docker && docker-compose up`

7. Download [Inventool executable](https://github.com/kerrilija/Inventool/releases/tag/macos_v1.0.0)
8. Extract the zip and start inventool.app
9. When the application starts, in the top menu, click on "Import to SQL".
10. Click on "Tool CSV".
11. When the file picker shows up, navigate to inventool/docker/data/ and select tool_inventory.csv
12. Application is ready to use. 

## Linux

1. [Download and install Docker for Ubuntu](https://docs.docker.com/desktop/install/ubuntu/) if it's not already installed. NOTE: If you're using a Linux distro other than Ubuntu, see [Docker for Linux](https://docs.docker.com/desktop/install/linux-install/).
2. Start Docker.
3. Open your Linux Terminal.
4. Navigate to a folder where you'd like to clone the repo.
5. Clone the repository: 

    `git clone https://github.com/kerrilija/Inventool.git`

6. Start PostgreSQL Server instance in a Docker container:

    `cd inventool/docker && docker-compose up`

7. Start the application: 

    `../build/linux/x64/release/bundle/./inventool`

8. When the application starts, in the top menu, click on "Import to SQL".
9. Click on "Tool CSV".
10. When the file picker shows up, navigate to inventool/docker/data/ and select tool_inventory.csv
11. Application is ready to use. 