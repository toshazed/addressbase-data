package main

// convert AddressBase records to street entries

import (
	"encoding/csv"
	"fmt"
	"io"
	"os"
	"sort"
	"strconv"
	"strings"
)

var (
	fdStreets     = os.NewFile(3, "FDStreets")
	fdFixes       = os.NewFile(4, "FDFixes")
	fdLocalities  = os.NewFile(5, "FDLocalities")
)

const (
	STREET_RECORD_IDENTIFIER = 0 + iota
	STREET_CHANGE_TYPE
	STREET_PRO_ORDER
	STREET_USRN
	STREET_RECORD_TYPE
	STREET_SWA_ORG_REF_NAMING
	STREET_STATE
	STREET_STATE_DATE
	STREET_SURFACE
	STREET_CLASSIFICATION
	STREET_VERSION
	STREET_START_DATE
	STREET_END_DATE
	STREET_LAST_UPDATE_DATE
	STREET_RECORD_ENTRY_DATE
	STREET_START_X
	STREET_START_Y
	STREET_START_LAT
	STREET_START_LONG
	STREET_END_X
	STREET_END_Y
	STREET_END_LAT
	STREET_END_LONG
	STREET_TOLERANCE
)

const (
	STREET_DESCRIPTOR_RECORD_IDENTIFIER = 0 + iota
	STREET_DESCRIPTOR_CHANGE_TYPE
	STREET_DESCRIPTOR_PRO_ORDER
	STREET_DESCRIPTOR_USRN
	STREET_DESCRIPTOR_DESCRIPTION
	STREET_DESCRIPTOR_LOCALITY
	STREET_DESCRIPTOR_TOWN_NAME
	STREET_DESCRIPTOR_ADMINISTRATIVE_AREA
	STREET_DESCRIPTOR_LANGUAGE
	STREET_DESCRIPTOR_START_DATE
	STREET_DESCRIPTOR_END_DATE
	STREET_DESCRIPTOR_LAST_UPDATE_DATE
	STREET_DESCRIPTOR_ENTRY_DATE
)

type Street struct {
	street              string
	name                string
	name_cy             string
	place               string
	locality            string
	town                string
	administrative_area string
	street_custodian    string
	point               string
	entry_date          string
	end_date            string
}

const sep = "\t"

var fixed_header bool = false

func fixed(usrn string, level string, field string, value string, text string) {
	if !fixed_header {
		fmt.Fprintln(fdFixes, strings.Join([]string{"usrn", "level", "field", "value", "text"}, sep))
		fixed_header = true
	}
	fmt.Fprintln(fdFixes, strings.Join([]string{usrn, level, field, value, text}, sep))
}

func Timestamp(date string) string {
	return date + "T00:00:00Z"
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

// create mid-point from line
func PointFromLine(lon1s string, lat1s string, lon2s string, lat2s string) string {
	lon1, err := strconv.ParseFloat(Number(lon1s), 64)
	if err != nil {
		return ""
	}

	lat1, err := strconv.ParseFloat(Number(lat1s), 64)
	if err != nil {
		return ""
	}

	lon2, err := strconv.ParseFloat(Number(lon2s), 64)
	if err != nil {
		return ""
	}

	lat2, err := strconv.ParseFloat(Number(lat2s), 64)
	if err != nil {
		return ""
	}

	lon := (lon1 + lon2) / 2.0
	lat := (lat1 + lat2) / 2.0

	return fmt.Sprintf("[%.4f,%.4f]", lon, lat)
}

var entries = map[string]Street{}
var records = map[string]string{}

func AddEntry(entry_date string, usrn string) Street {
	key := records[usrn]
	street := entries[key]
	street.street = usrn
	street.entry_date = entry_date
	return street
}

func UpdateEntry(street Street) {
	key := street.entry_date + ":" + street.street
	entries[key] = street
	records[street.street] = key
}

func AddStreetRecord(row []string) {
	street := AddEntry(row[STREET_RECORD_ENTRY_DATE], row[STREET_USRN])

	street.street_custodian = row[STREET_SWA_ORG_REF_NAMING]
	street.point = PointFromLine(row[STREET_START_LONG], row[STREET_START_LAT], row[STREET_END_LONG], row[STREET_END_LAT])
	street.end_date = row[STREET_END_DATE]

	UpdateEntry(street)
}

func AddStreetDescriptor(row []string) {
	street := AddEntry(row[STREET_DESCRIPTOR_ENTRY_DATE], row[STREET_DESCRIPTOR_USRN])

	if row[STREET_DESCRIPTOR_LANGUAGE] == "ENG" {
		street.name = row[STREET_DESCRIPTOR_DESCRIPTION]
	} else if row[STREET_DESCRIPTOR_LANGUAGE] == "CYM" {
		street.name_cy = row[STREET_DESCRIPTOR_DESCRIPTION]
	} else {
		fixed(street.street, "error", "language", row[STREET_DESCRIPTOR_LANGUAGE], "unknown")
		street.name = row[STREET_DESCRIPTOR_DESCRIPTION]
	}

	// TBD: map to a place ..
	street.locality = row[STREET_DESCRIPTOR_LOCALITY]
	street.town = row[STREET_DESCRIPTOR_TOWN_NAME]
	street.administrative_area = row[STREET_DESCRIPTOR_ADMINISTRATIVE_AREA]

	street.end_date = row[STREET_DESCRIPTOR_END_DATE]
	UpdateEntry(street)
}

func PrintHeaders() {
	fmt.Fprintln(fdStreets, strings.Join([]string{
		"entry-timestamp",
		"street",
		"name",
		"name-cy",
		"place",
		"street-custodian",
		"end-date"}, sep))

	fmt.Fprintln(fdLocalities, strings.Join([]string{
		"street",
		"street-custodian",
		"locality",
		"town",
		"administrative-area",
		"point",
		"place"}, sep))

}

func PrintStreet(street Street) {


	if street.name == "" {
		street.name = street.name_cy
		fixed(street.street, "warning", "name", street.name, "from Welsh name")
	}

	if street.name_cy == street.name {
		street.name_cy = ""
		fixed(street.street, "warning", "name", street.name, "same as Welsh name")
	}

	fmt.Fprintln(fdStreets, strings.Join([]string{
		Timestamp(street.entry_date),
		street.street,
		street.name,
		street.name_cy,
		street.place,
		street.street_custodian,
		street.end_date}, sep))

	fmt.Fprintln(fdLocalities, strings.Join([]string{
		street.street,
		street.street_custodian,
		street.locality,
		street.town,
		street.administrative_area,
		street.point,
		street.place}, sep))
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
		if row[0] == "11" {
			AddStreetRecord(row)
		} else if row[0] == "15" {
			AddStreetDescriptor(row)
		}
	}

	var keys []string
	for key := range entries {
		keys = append(keys, key)
	}
	sort.Strings(keys)

	for _, key := range keys {
		PrintStreet(entries[key])
	}
}
