FROM mcr.microsoft.com/powershell:ubuntu-20.04

WORKDIR /app
COPY . .


# Install required modules
RUN pwsh ./install-modules.ps1

EXPOSE 80
CMD [ "pwsh", "./src/PokerBlindsService.ps1" ]