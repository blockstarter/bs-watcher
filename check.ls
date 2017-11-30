require! {
    \superagent : { get } 
    \./package.json : pack
    \require-ls
    \./notify.ls
    \ip-address : ip
    \dns-lookup : lookup
    \ipaddr.js
    \fs
}


check-ip = (cb)->
  err, address, family <-! lookup pack.config.host
  #return notify('Cannot get ip address') if err?
  #return notify('IP is not match') if not address is pack.config.checkip
  cb!


hashes = {}

#pack.config.host = \https://ico.covesting.io

check-page = (name, cb)->
    page = "#{pack.config.host}/#{name}/index.html"
    err, data <-! get page .end
    #console.log data.text.match(/\"\/cdn-cgi\/l\/email-protection#[^"]+\"/)?0?length
    text = data.text.replace(/\"\/cdn-cgi\/l\/email-protection#[^"]+\"/, "")
    if hashes[name]? and text isnt hashes[name]
       #console.log name, page, hashes[name]
       fs.write-file-sync("./diff/#{name}-before.html", hashes[name])
       fs.write-file-sync("./diff/#{name}-after.html", text)
       notify "Page `#{page}` was changed"
    hashes[name] = text
    cb!

check-pages = ([page, ...pages], cb)->
    return cb! if not page?
    <-! check-page page
    <-! check-pages pages 
    cb!


pages = <[ members login profile reset-password confirm-email reset restore settings ]>


check-all = ->
  console.log \check-all
  <-! check-ip
  <-! check-pages pages
  set-timeout check-all, 10000
  
check-all!

