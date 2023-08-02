# PowerShell Port Monitoring

## Description

This repository contains a PowerShell script that monitors specific ports using the netstat command. It logs the results to a CSV file, includes whitelisting and blacklisting of IP addresses, and provides progress updates.

## Synopsis

This script runs the netstat command with the -ano options to monitor specific ports, and logs the results to a CSV file. It includes whitelisting and blacklisting of IP addresses.

## Prerequisites

* Windows PowerShell 5.1 or higher
* Administrator privileges to change the execution policy if needed

## Installation

1. Download the PowerShell script from the repository.
2. Place the script in a local directory.

## Usage

1. Open a PowerShell session with Administrator privileges.
2. Navigate to the directory where you placed the script.
3. Run the script with the following command:
