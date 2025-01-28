# Contents of `/poker-blinds-service/poker-blinds-service/README.md`

# Poker Blinds Service

This project provides a simple web service for calculating poker blind structures based on various parameters. It is implemented in PowerShell and can be run in a containerized environment on an Ubuntu virtual machine.

## Project Structure

- `src/PokerBlindsService.ps1`: Main entry point that sets up the web server and handles requests.
- `src/modules/BlindCalculator/BlindCalculator.psm1`: Module containing the `Calculate-BlindStructure` function.
- `src/modules/BlindCalculator/BlindCalculator.psd1`: Module manifest for the `BlindCalculator`.
- `tests/BlindCalculator.Tests.ps1`: Unit tests for the `BlindCalculator` module.
- `Dockerfile`: Instructions to build the Docker image.
- `docker-compose.yml`: Configuration for running the application in containers.
- `install-modules.ps1`: Script to install required PowerShell modules.

## Setup Instructions

1. Clone the repository:
   ```
   git clone <repository-url>
   cd poker-blinds-service
   ```

2. Run the installation script to install required modules:
   ```
   ./install-modules.ps1
   ```

3. Build the Docker image:
   ```
   docker build -t poker-blinds-service .
   ```

4. Run the application using Docker Compose:
   ```
   docker-compose up
   ```

## Usage

Once the service is running, you can access the poker blind calculations by sending a GET request to:
```
http://localhost:8080/blinds?players=<number>&roundLength=<minutes>&smallBlind=<amount>&bigBlind=<amount>&chips=<amount>
```

Replace `<number>`, `<minutes>`, `<amount>` with your desired values.

## License

This project is licensed under the MIT License. See the LICENSE file for details.