require! {
    \os : { platform, homedir, totalmem, hostname }
    \./package.json : pack
    \telegram-bot-api : telegram
    \prelude-ls : { each }
    \fs
}



{ admins, bot } = pack.config

api = new telegram do
    token: bot
    updates:
        enabled: true


username = hostname!

get-admins = ->
    JSON.parse fs.read-file-sync(\./admins.json, "utf8")

send-message = (text, admin)-->
    #console.log text, admin
    admins = get-admins!
    <-! api.send-message { chat_id: admins[admin] , text }

notify-telegram = (text, cb)->
    admins |> each send-message text
    cb!


notify = (text, cb)->
  console.log "NOTIFY #{text}"
  <-! notify-telegram text
  cb?!
  
module.exports = notify

<-! notify-telegram "Watcher Start"


api.on \message , (message)->
    index = pack.config.admins.index-of(message.from.username)
    if index > -1
       content = get-admins!
       content[message.from.username] = message.chat.id 
       fs.write-file-sync(\./admins.json, JSON.stringify(content))

          