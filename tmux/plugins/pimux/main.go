package main

import (
	"context"
	"fmt"
	"os"
	"os/signal"
	"syscall"
)

// Outcomes describe what the popup should do, independently of command errors.
// Their values also preserve the exit codes of the former script entrypoints.
type outcome int

const (
	closePopup       outcome = 0
	closeWithWarning outcome = 2
	backToList       outcome = 130
)

func main() {
	os.Exit(runMain())
}

func runMain() int {
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGHUP, syscall.SIGTERM)
	defer stop()
	dir, err := os.Getwd()
	if err != nil {
		fmt.Fprintln(os.Stderr, "pimux:", err)
		return 1
	}
	exe, err := os.Executable()
	if err != nil {
		fmt.Fprintln(os.Stderr, "pimux:", err)
		return 1
	}
	a := &app{ctx: ctx, dir: dir, exe: exe, out: os.Stdout, errOut: os.Stderr}
	result, err := a.dispatch(os.Args[1:])
	if ctx.Err() != nil {
		return int(backToList)
	}
	if err != nil {
		fmt.Fprintln(a.errOut, "pimux:", err)
		return 1
	}
	return int(result)
}
