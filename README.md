Encryption for ActiveResource
====================================================

This is just a proof-of-concept hack project.
Not intended for production deployment and use.
If you, however, do decide to use this in production code,
I am not responsible or liable for lost data.
USE AT YOUR OWN RISK.

### Demo

Create a RESTful rails local server so that ActiveResource can connect to 

`$ rails new demo`

scaffold a story resource

`$ rails generate scaffold Story first_name:string middle_name:string last_name:string`

prep the db

`rake db:migrate`

now run the server

`$ rails server'

the resource will be located at
 
http://localhost:3000/stories

run the acts_with_encryption.rb file on the console

now with a browser, go to http://localhost:3000/stories

you will see encrypted values for peoples names

while on the console, retrieved names using Story.find(:id)

will show decrypted and readable values. 