
# ets2server-playerswebhook


A shell for send connected and disconnected players for discord



## Run Locally

Clone the project

```bash
  git clone https://github.com/ararasstudio/ets2server-playerswebhook.git
```

Go to the project directory

```bash
  cd ets2server-playerswebhook
```

Edit the lines:

```bash
   WEBHOOK_URL="WEBHOOK HERE" # Insert the webhook link here
   LOGFILE_NAME="/home/ets2server/.local/share/Euro Truck Simulator 2/server.log.txt" # Log File Path
```

Start the script running in background

```bash
  nohup bash monitor.sh &
```

