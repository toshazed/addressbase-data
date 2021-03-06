package main

// Convert AddressBase records to address entries

import (
	"encoding/csv"
	"fmt"
	"io"
	"os"
	"sort"
	"strings"
)

var (
	fdAddresses = os.NewFile(3, "FDAddresses")
	fdFixes     = os.NewFile(4, "FDFixes")
)

const (
	BLPU_RECORD_IDENTIFIER = 0 + iota
	BLPU_CHANGE_TYPE
	BLPU_PRO_ORDER
	BLPU_UPRN
	BLPU_LOGICAL_STATUS
	BLPU_STATE
	BLPU_STATE_DATE
	BLPU_PARENT_UPRN
	BLPU_X_COORDINATE
	BLPU_Y_COORDINATE
	BLPU_LATITUDE
	BLPU_LONGITUDE
	BLPU_RPC
	BLPU_LOCAL_CUSTODIAN_CODE
	BLPU_COUNTRY
	BLPU_START_DATE
	BLPU_END_DATE
	BLPU_LAST_UPDATE_DATE
	BLPU_ENTRY_DATE
	BLPU_ADDRESSBASE_POSTAL
	BLPU_POSTCODE_LOCATOR
	BLPU_MULTI_OCC_COUNT
)

const (
	LPI_RECORD_IDENTIFIER = 0 + iota
	LPI_CHANGE_TYPE
	LPI_PRO_ORDER
	LPI_UPRN
	LPI_KEY
	LPI_LANGUAGE
	LPI_LOGICAL_STATUS
	LPI_START_DATE
	LPI_END_DATE
	LPI_LAST_UPDATE_DATE
	LPI_ENTRY_DATE
	LPI_SAO_START_NUMBER
	LPI_SAO_START_SUFFIX
	LPI_SAO_END_NUMBER
	LPI_SAO_END_SUFFIX
	LPI_SAO_TEXT
	LPI_PAO_START_NUMBER
	LPI_PAO_START_SUFFIX
	LPI_PAO_END_NUMBER
	LPI_PAO_END_SUFFIX
	LPI_PAO_TEXT
	LPI_USRN
	LPI_USRN_MATCH_INDICATOR
	LPI_AREA_NAME
	LPI_LEVEL
	LPI_OFFICIAL_FLAG
)

type Address struct {
	entry_date       string
	address          string
	parent_address   string
	street           string
	name             string
	name_cy          string
	primary_name     string
	primary_name_cy  string
	point            string
	street_custodian string
	end_date         string
	has_lpi          bool
	property_type    string
	postcode         string
}

const sep = "\t"

var issue_header bool = false

func issue(street_custodian string, uprn string, level string, field string, value string, text string) {
	if !issue_header {
		fmt.Fprintln(fdFixes, strings.Join([]string{"street-custodian", "uprn", "level", "field", "value", "text"}, sep))
		issue_header = true
	}
	fmt.Fprintln(fdFixes, strings.Join([]string{street_custodian, uprn, level, field, value, text}, sep))
}

func Name(sn string, ss string, en string, es string, t string) string {
	s := sn + ss
	if en != "" || es != "" {
		s = s + "-" + en + es
	}
	s = s + "/" + t
	s = strings.TrimSpace(strings.Join(strings.Fields(s), " "))
	s = strings.Trim(s, "/")
	return s
}

func Number(n string) string {
	// missing leading 0 on decimal number is invalid JSON
	if n[0] == '.' {
		return "0" + n
	} else if n[0:2] == "-." {
		return "-0" + n[1:]
	}
	return n
}

func Point(long string, lat string) string {
	return "[" + Number(long) + "," + Number(lat) + "]"
}

func Timestamp(date string) string {
	return date + "T00:00:00Z"
}

var entries = map[string]Address{}
var records = map[string]string{}

func AddBLPU(row []string) {
	uprn := row[BLPU_UPRN]
	key := records[uprn]
	address := entries[key]

	address.address = uprn
	address.entry_date = row[BLPU_ENTRY_DATE]
	address.parent_address = row[BLPU_PARENT_UPRN]
	address.point = Point(row[BLPU_LONGITUDE], row[BLPU_LATITUDE])
	address.street_custodian = row[BLPU_LOCAL_CUSTODIAN_CODE]
	address.end_date = row[BLPU_END_DATE]
	address.postcode = row[BLPU_POSTCODE_LOCATOR]
	address.property_type = row[BLPU_ADDRESSBASE_POSTAL]

	key = row[BLPU_ENTRY_DATE] + ":" + row[BLPU_UPRN]
	entries[key] = address
	records[address.address] = key
}

func AddLPI(row []string) {
	uprn := row[LPI_UPRN]
	key := records[uprn]
	address := entries[key]

	address.has_lpi = true
	address.entry_date = row[LPI_ENTRY_DATE]
	address.address = row[LPI_UPRN]
	address.street = row[LPI_USRN]

	name := Name(row[LPI_SAO_START_NUMBER],
		row[LPI_SAO_START_SUFFIX],
		row[LPI_SAO_END_NUMBER],
		row[LPI_SAO_END_SUFFIX],
		row[LPI_SAO_TEXT])

	primary_name := Name(row[LPI_PAO_START_NUMBER],
		row[LPI_PAO_START_SUFFIX],
		row[LPI_PAO_END_NUMBER],
		row[LPI_PAO_END_SUFFIX],
		row[LPI_PAO_TEXT])

	if name == "" {
		name = primary_name
		primary_name = ""
	}

	if row[LPI_LANGUAGE] == "ENG" {
		address.name = name
		address.primary_name = primary_name
	} else if row[LPI_LANGUAGE] == "CYM" {
		address.name_cy = name
		address.primary_name_cy = primary_name
	} else {
		issue(address.street_custodian, address.address, "error", "language", row[LPI_LANGUAGE], "unknown")
	}

	address.end_date = row[LPI_END_DATE]

	key = row[LPI_ENTRY_DATE] + ":" + row[LPI_UPRN]
	entries[key] = address
	records[address.address] = key
}

func PrimaryAddress(street_custodian string, address string, parent_address string, primary_name string, depth int) string {

	if depth > 32 {
		issue(street_custodian, address, "error", "parent_address", parent_address, "*probably looping*")
		return ""
	}

	if primary_name == "" {
		return ""
	}

	if parent_address == "" {
		return ""
	}

	parent_key, ok := records[parent_address]
	if !ok {
		// it's possible that the parent isn't in the same grid square
		issue(street_custodian, address, "error", "parent_address", parent_address, "unknown")
		return ""
	}
	parent := entries[parent_key]

	if primary_name == parent.name {
		return parent_address
	}

	primary_address := PrimaryAddress(street_custodian, address, parent.parent_address, primary_name, depth+1)

	if primary_address == "" {
		issue(street_custodian, address, "note", "primary_name", primary_name, "doesn't match parent.name ["+parent.name+"]")
	}

	return ""
}

func PrintAddress(address Address) {

	// skip bare BLPU entries
	if !address.has_lpi {
		return
	}

	if address.street == "" {
		issue(address.street_custodian, address.address, "skipped", "entry", address.entry_date, "missing street")
	}

	if address.name == "STREET RECORD" {
		issue(address.street_custodian, address.address, "skipped", "record", "STREET RECORD", "dummy")
		return
	}
	if address.street_custodian == "7655" {
		// skip OS injected OWPA (object without postal address) records
		issue(address.street_custodian, address.address, "skipped", "record", address.street_custodian, "OWPA")
		return
	}

	// search for the primary address which matches the PAO
	primary_address := ""

	if address.primary_name != "" {
		if address.parent_address == "" {
			issue(address.street_custodian, address.address, "error", "parent_address", address.primary_name, "missing parent_address")
		} else {
			primary_address = PrimaryAddress(address.street_custodian, address.address, address.parent_address, address.primary_name, 0)
			if primary_address == "" {
				issue(address.street_custodian, address.address, "error", "primary_name", address.primary_name, "not found")
			}
		}
	}

	fmt.Fprintln(fdAddresses, strings.Join([]string{
		Timestamp(address.entry_date),
		address.address,
		address.parent_address,
		primary_address,
		address.street,
		address.name,
		address.name_cy,
		address.point,
		address.end_date,
		address.street_custodian,
		address.postcode,
		address.property_type}, sep))
}

func PrintHeaders() {
	fmt.Fprintln(fdAddresses, strings.Join([]string{
		"entry-timestamp",
		"address",
		"parent-address",
		"primary-address",
		"street",
		"name",
		"name-cy",
		"point",
		"end-date",
		"street-custodian",
		"postcode",
		"property-type"}, sep))
}

func main() {
	// read CSV records
	reader := csv.NewReader(os.Stdin)

	// write TSV entries
	PrintHeaders()

	for {
		row, err := reader.Read()
		if err == io.EOF {
			break
		}
		if row[0] == "21" {
			AddBLPU(row)
		} else if row[0] == "24" {
			AddLPI(row)
		}
	}

	var keys []string
	for key := range entries {
		keys = append(keys, key)
	}
	sort.Strings(keys)

	for _, key := range keys {
		PrintAddress(entries[key])
	}
}
