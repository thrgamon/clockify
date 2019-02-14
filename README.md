# Clockify Timer
Start and stop your clockify timer from the command line. 

## Setup
The utility is mainly controller through a .env.local file.

Make a copy of the .env file and populate it with the following values

* API_KEY - This can be found in your Clockify personal settings
* WORKSPACE_ID - This can be found by running the following command which will show you a list of all workspaces with their ID's.

```
curl -H "content-type: application/json" -H "X-Api-Key: YOUR_API_KEY" -X GET https://api.clockify.me/api/workspaces/
```
There are also two additional commands
* DEBUG = This will result in some additional output for debugging, and start a pry session on exceptions.
* INLINE_TIMER = The default mode when using in the command line is to start a timer that will show the project that you are working on and the time elapsed. If you opt out of this feature you will have to start and stop the timer seperately. 

## Usage

## Starting a timer

Starting timers is easy, just run the start timer script like so.

`ruby start_timer.rb`

You will need to pass in at least one of these arguments:

* description - This will appear as the description of the time log
* project (optional) - this will be the project assosciated to the time log.

`ruby start_timer.rb 'This is a test' 'DOT: Initial launch'`

### Project Matching

If you are anything like me, you are probably thing, that seems like a lot of effort to add a project. Fear not, I have your back.
You can use any unique abbreviation of the project name in order to match it. To see a full list of examples, you can look at the `abbrevs` part of the `projects.store`

To use the example above, you could use any of these to link to the same project

```
ruby start_timer.rb 'This is a test' 'DOT: Initial'
ruby start_timer.rb 'This is a test' 'DOT: I'
ruby start_timer.rb 'This is a test' 'DOT'
ruby start_timer.rb 'This is a test' 'D'
```

You have to be more careful if there are projects that are name similarly. For example, given these two project names:

```
DOT: Initial Launch
DOT: Interesting Launch
```
It will get confused if you give it just `DOT` but it will know what you are talking about if you pass it `DOT: Ini`.

## Stopping timers

Stopping timers is easy, just run the stop timer script. Note, this will stop any running timer on Clockify, not necessarily just timers that you started through the script.

## Pro Tips

I have two shortcuts set up for me to make things easier.

```
ts='ruby ~/path/to/project/clockify/start_timer.rb'
tst='ruby ~/path/to/project/clockify/stop_timer.rb'
```

### Future Developments
* Less ambigous project matching
* Nicer user interface, maybe set it up as an executable or using `thor`
* Rewrite it in some fancy language
