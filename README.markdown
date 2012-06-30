# Challenge for Software Engineer - Big Data

## Project overview

This is a Sinatra app that uses Sequel as the ORM to connect to a Postgres database.

The app uses OpenID to authenticate the user before allowing them to upload a purchase history
file to be loaded to the database.

## To setup:

1. Have Postgres running somewhere and create the database.  You'll also need a database.yml config file (like in Rails). You can use the example file to get started.
1. bundle install
1. rackup -E production
