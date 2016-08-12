package main

// count the occurrences of a set of fields in a TSV

import (
	"bufio"
	"errors"
	"fmt"
	"os"
	"strconv"
	"strings"
	"sort"
)

const sep = "\t"

func Pick(row []string, cols []int) (ret []string) {
	for _, c := range cols {
		s := ""
		if c >= 0 && c < len(row) {
			s = row[c]
		}
		ret = append(ret, s)
	}
	return
}

func Search(fields []string, item string) (int, error) {
	for n, field := range fields {
		if field == item {
			return n, nil
		}
	}
	return -1, errors.New("not found")
}

func PickCols(row []string, fields []string) (ret []int) {
	for _, field := range fields {
		col, err := Search(row, field)
		if err == nil {
			ret = append(ret, col)
		}
	}
	return
}

func main() {

	cols := []int{}
	fields := strings.Split(os.Args[1], ",")
	items := make(map[string]int)

	scanner := bufio.NewScanner(os.Stdin)

	for scanner.Scan() {
		line := scanner.Text()
		row := strings.Split(line, sep)

		if len(cols) == 0 {
			cols = PickCols(row, fields)
		} else {
			item := strings.Join(Pick(row, cols), sep)
			c, ok := items[item]
			if !ok {
				c = 0
			}
			items[item] = c + 1
		}
	}

	// print headers
	fmt.Println(strings.Join(append(fields, "count"), sep))

	// sort by count
	counts := map[int][]string{}
	var entries []int

	for key, count := range items {
		counts[count] = append(counts[count], key)
	}

	for key := range counts {
		entries = append(entries, key)
	}

	sort.Sort(sort.Reverse(sort.IntSlice(entries)))

	for _, count := range entries {
		sort.Sort(sort.StringSlice(counts[count]))
		for _, key := range counts[count] {
			row := strings.Split(key, sep)
			row = append(row, strconv.Itoa(count))
			fmt.Println(strings.Join(row, sep))
		}
	}
}
