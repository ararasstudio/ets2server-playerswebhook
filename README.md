
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

Edit these lines:

```bash
   WEBHOOK_URL="WEBHOOK HERE" # Insert the webhook link here
   LOGFILE_NAME="path/to/server.log.txt" # Log File Path
```

Start the script running in background

```bash
  nohup bash monitor.sh &
```

