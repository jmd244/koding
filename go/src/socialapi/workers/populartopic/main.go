package main

import (
	"flag"
	"fmt"

	"socialapi/config"
	"socialapi/workers/helper"
	"socialapi/workers/populartopic/populartopic"
	"github.com/koding/worker"
)

var (
	flagConfFile = flag.String("c", "", "Configuration profile from file")
	flagDebug    = flag.Bool("d", false, "Debug mode")
	Name         = "PopularTopicsWorker"
)

func main() {
	flag.Parse()
	if *flagConfFile == "" {
		fmt.Println("Please define config file with -c", "Exiting...")
		return
	}

	conf := config.MustRead(*flagConfFile)

	// create logger for our package
	log := helper.CreateLogger(Name, *flagDebug)

	// panics if not successful
	bongo := helper.MustInitBongo(Name, conf, log)
	// do not forgot to close the bongo connection
	defer bongo.Close()

	redis := helper.MustInitRedisConn(conf.Redis)

	// create message handler
	handler := populartopic.NewPopularTopicsController(log, redis)

	listener := worker.NewListener("PopularTopicsFeed", conf.EventExchangeName, log)
	// blocking
	// listen for events
	listener.Listen(helper.NewRabbitMQ(conf, log), handler)
	// close consumer
	defer listener.Close()
}
