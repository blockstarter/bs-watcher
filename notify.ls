require! {
    \os : { platform, homedir, totalmem, hostname }
    \./package.json : pack
    \telegram-bot-api : telegram
    \prelude-ls : { each }
}



{ admins, bot } = pack.config

api = new telegram do
    token: bot
    updates:
        enabled: true


username = hostname!

send-message = (text, admin)-->
    <-! api.send-message { chat_id: admin , text }

notify-telegram = (text, cb)->
    admins |> each send-message text
    cb!
<-! notify-telegram "Test"

notify = (text, cb)->
  console.log "NOTIFY #{text}"
  <-! notify-telegram text
  cb?!
  
module.exports = notify

          