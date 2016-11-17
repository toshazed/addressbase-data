package main

// split a TSV into multiple files based on field
// usage: tsvsplit path-prefix path-suffix column-name

import (
	"bufio"
	"errors"
	"fmt"
	"os"
	"strings"
)

/*
 *  tsv parsing
 */
const sep = "\t"

func Search(fields []string, item string) (int, error) {
	for n, field := range fields {
		if field == item {
			return n, nil
		}
	}
	return -1, errors.New("not found")
}

func PickCol(row []string, field string) (ret int) {
	col, err := Search(row, field)
	if err == nil {
		ret = col
	}
	return
}

/*
 *  file management
 */
func main() {

	prefix := os.Args[1]
	suffix := os.Args[2]
	field := os.Args[3]

	titles := ""
	col := 0

	fds := make(map[string]*os.File)

	scanner := bufio.NewScanner(os.Stdin)

	for scanner.Scan() {
		line := scanner.Text()
		row := strings.Split(line, sep)

		if titles == "" {
			titles = line
			col = PickCol(row, field)
		} else if col < len(row) {
			name := row[col]
			fd, ok := fds[name]
			if !ok {
				path := prefix + name + suffix
				fd, err := os.OpenFile(path, os.O_WRONLY|os.O_CREATE|os.O_TRUNC, 0664)
				if err != nil {
					panic(err)
				}
				fds[name] = fd
				fmt.Fprintln(fd, titles)
			}

			fmt.Fprintln(fd, line)
		} else {
			fmt.Println("missing col:" + line)
		}
	}

	for _, fd := range fds {
		fd.Close()
	}
}
