// segman CLI. Reads a manuscript from stdin (or the file given as the
// last argument) and writes one sentence per line to stdout, by default.
//
// Flags:
//   --json      Emit a JSON array instead of one sentence per line.
//   --version   Print the segman version and exit.
//
// Exit codes: 0 on success, 1 on any error (read, parse, write).
package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"os"
	"strings"

	"github.com/slackwing/segman/go"
)

func main() {
	asJSON := flag.Bool("json", false, "emit JSON array instead of one sentence per line")
	showVersion := flag.Bool("version", false, "print version and exit")
	flag.Parse()

	if *showVersion {
		fmt.Println(segman.Version)
		return
	}

	var input []byte
	var err error
	if flag.NArg() > 0 {
		input, err = os.ReadFile(flag.Arg(0))
		if err != nil {
			fmt.Fprintf(os.Stderr, "segman: read %s: %v\n", flag.Arg(0), err)
			os.Exit(1)
		}
	} else {
		input, err = io.ReadAll(os.Stdin)
		if err != nil {
			fmt.Fprintf(os.Stderr, "segman: read stdin: %v\n", err)
			os.Exit(1)
		}
	}

	sentences := segman.Segment(string(input))

	if *asJSON {
		out, err := json.MarshalIndent(sentences, "", "  ")
		if err != nil {
			fmt.Fprintf(os.Stderr, "segman: encode json: %v\n", err)
			os.Exit(1)
		}
		fmt.Println(string(out))
		return
	}

	// One sentence per line. Sentences should not contain literal newlines
	// from segman, but normalize defensively so a single sentence can never
	// span multiple output lines (which would break diff readability — the
	// whole point of the file format).
	for _, s := range sentences {
		fmt.Println(strings.ReplaceAll(s, "\n", " "))
	}
}
