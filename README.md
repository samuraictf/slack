# slack

A fifo that sits on the game box at `/home/ctf/slack`.
Write to it, and data gets forwarded to slack.

The first two space-delimited fields are the channel and username, for example `#ctf` and `funbot`.

The script `./slack.sh` runs on a machine which has a connection both to the game network and the internet.

## Warnings

This code is terrible and is full of command injections.

If an attacker can send data to the FIFO, you're fucked.

## Prerequisites

Requires some Python 2.7 on whatever machine has the internet connection.

```sh
$ pip install -Ur requirements.txt
```

## Setup

There are a few configuration points, which are managed via environment variables.  You can either specify them explicitly, or modify the configuration files.

- `config/00-gamebox`
    + `DEPLOY_SERVER` is the "game server"
    + `DEPLOY_PORT` is the port SSH is running on, on `DEPLOY_SERVER`
    + `DEPLOY_USER` is the user to log in as on `DEPLOY_SERVER`, e.g. `ctf`
- `config/40-slack`
    + `SLACK_URL` is the incoming webhook URL for your Slack team

## Usage

After configuration, just run `./slack.sh`.  It should load the configuration, and automatically connect to `DEPLOY_SERVER` and start monitoring a FIFO at `/home/$DEPLOY_USER/slack`.

To send a message to slack, just write to the FIFO.  For example:

```sh
$ echo 'bot-name #general Hello, world!' > slack
```

## Ideas for Usage

One idea for usage is to hook up an [`inotify` listener to it](https://github.com/samuraictf/inotifyd).
