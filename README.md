## S3 AR Server Kitura

This is an example of **Swift Kitura** backend for **AR server**

### Requirements

* [Swift 5](https://swift.org/download/)

### Run

To build and run the application:

1. `.start.sh`          # run server (wait a few seconds) on http://localhost:9000
2. `tail -f nohup.out`  # start real time event logging
3. `.stop.sh`           # stop server
4. `rm nohup.out`       # delete nohup.out log file