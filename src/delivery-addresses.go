package main

// Extract AddressBase delivery point records

import (
	"encoding/csv"
	"fmt"
	"io"
	"os"
	"strings"
)

const (
	DP_RECORD_IDENTIFIER = 0 + iota
	DP_CHANGE_TYPE
	DP_PRO_ORDER
	DP_UPRN
	DP_UDPRN
	DP_ORGANISATION_NAME
	DP_DEPARTMENT_NAME
	DP_SUB_BUILDING_NAME
	DP_BUILDING_NAME
	DP_BUILDING_NUMBER
	DP_DEPENDENT_THOROUGHFARE
	DP_THOROUGHFARE
	DP_DOUBLE_DEPENDENT_LOCALITY
	DP_DEPENDENT_LOCALITY
	DP_POST_TOWN
	DP_POSTCODE
	DP_POSTCODE_TYPE
	DP_DELIVERY_POINT_SUFFIX
	DP_WELSH_DEPENDENT_THOROUGHFARE
	DP_WELSH_THOROUGHFARE
	DP_WELSH_DOUBLE_DEPENDENT_LOCALITY
	DP_WELSH_DEPENDENT_LOCALITY
	DP_WELSH_POST_TOWN
	DP_PO_BOX_NUMBER
	DP_PROCESS_DATE
	DP_START_DATE
	DP_END_DATE
	DP_LAST_UPDATE_DATE
	DP_ENTRY_DATE
)

const sep = "\t"

func main() {
	reader := csv.NewReader(os.Stdin)

	fmt.Println(strings.Join([]string{
		"address",
		"udprn",
		"organisation_name",
		"department_name",
		"sub_building_name",
		"building_name",
		"building_number",
		"dependent_thoroughfare",
		"thoroughfare",
		"double_dependent_locality",
		"dependent_locality",
		"post_town",
		"postcode",
		"postcode_type",
		"delivery_point_suffix",
		"welsh_dependent_thoroughfare",
		"welsh_thoroughfare",
		"welsh_double_dependent_locality",
		"welsh_dependent_locality",
		"welsh_post_town",
		"po_box_number",
		"end-date"}, sep))

	for {
		row, err := reader.Read()
		if err == io.EOF {
			break
		}
		if row[0] == "28" {
			fmt.Println(strings.Join([]string{
				row[DP_UPRN],
				row[DP_UDPRN],
				row[DP_ORGANISATION_NAME],
				row[DP_DEPARTMENT_NAME],
				row[DP_SUB_BUILDING_NAME],
				row[DP_BUILDING_NAME],
				row[DP_BUILDING_NUMBER],
				row[DP_DEPENDENT_THOROUGHFARE],
				row[DP_THOROUGHFARE],
				row[DP_DOUBLE_DEPENDENT_LOCALITY],
				row[DP_DEPENDENT_LOCALITY],
				row[DP_POST_TOWN],
				row[DP_POSTCODE],
				row[DP_POSTCODE_TYPE],
				row[DP_DELIVERY_POINT_SUFFIX],
				row[DP_WELSH_DEPENDENT_THOROUGHFARE],
				row[DP_WELSH_THOROUGHFARE],
				row[DP_WELSH_DOUBLE_DEPENDENT_LOCALITY],
				row[DP_WELSH_DEPENDENT_LOCALITY],
				row[DP_WELSH_POST_TOWN],
				row[DP_PO_BOX_NUMBER],
				row[DP_END_DATE]}, sep))
		}
	}
}
