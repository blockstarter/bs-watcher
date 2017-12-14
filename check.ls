require! {
    \superagent : { get, post } 
    \./package.json : pack
    \prelude-ls : { each, map, concat }
    \require-ls
    \./notify.ls
    \ip-address : ip
    \dns-lookup : lookup
    \ipaddr.js
    \fs : { write-file-sync, readdir-sync, read-file-sync }
}


addresses = 
     \./addresses |> readdir-sync 
                  |> map (-> read-file-sync("./addresses/#{it}", "utf8").split('\n') )
                  |> concat


init-users = {}

check-address = (user, address)-->
    notify("Address #{address} is not found for `#{user.email}`") if addresses.index-of(address) is -1
    

check-addresses = (user)->
    user.addresses |> Object.keys |> check-address user

check-user = (user)->
    init-users[user._id] = init-users[user._id] ? user
    oldaddr = init-users[user._id].address
    newaddr = user.address
    notify("ETH Address is changed for `#{user.email}` #{oldaddr} => #{newaddr}") if oldaddr isnt newaddr and oldaddr?length > 0
    check-addresses user

check-users = (cb)->
    { password } = pack.config
    err, data <-! post "#{pack.config.host}/admin/users" .send({ password }).end 
    data.text |> JSON.parse 
              |> each check-user
    cb!
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
       write-file-sync("./diff/#{name}-before.html", hashes[name])
       write-file-sync("./diff/#{name}-after.html", text)
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
  <-! check-users
  <-! check-ip
  <-! check-pages pages
  set-timeout check-all, 10000
  
check-all!

