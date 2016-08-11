#
#  process AddressBase
#
.PHONY: init bin data clean prune
.SECONDARY:

BINS=\
	bin/streets\
	bin/addresses

data:	streets addresses


#
#  AddressBase comes as 10,964 grid files, enumerated here
#
include makefiles/grids.mk

ADDRESSBASE_ZIPS=$(GRIDS:%=cache/AddressBase/%.zip)

GRID_STREETS=$(GRIDS:%=data/street/%.tsv)
GRID_ADDRESSES=$(GRIDS:%=data/address/%.tsv)

streets:	bin/streets $(GRID_STREETS)
addresses:	bin/addresses $(GRID_ADDRESSES)


#
#  download AddressBase header records
#
HEADERS_URL='https://www.ordnancesurvey.co.uk/docs/product-schemas/addressbase-premium-header-files.zip'
etc/headers:
	@-mkdir -p cache
	curl -s $(HEADERS_URL) > cache/headers.zip
	mkdir -p etc/headers
	unzip -d etc/headers -o cache/headers.zip


#
#  download AddressBase ZIP files using the saved download.html file
#  - see README for instructions
#
cache/AddressBase/%.zip: bin/download.sh cache/download.html
	@mkdir -p cache/AddressBase
	bin/download.sh < cache/download.html $(@)


#
#  TSV files
#
data/street/%.tsv: bin/streets cache/AddressBase/%.zip
	@mkdir -p data/street log/street
	unzip -p $(patsubst data/street/%.tsv,cache/AddressBase/%,$(@)).zip | \
		bin/streets 3> $@ \
			    4> $(patsubst data/street/%.tsv,log/street/%,$(@)).tsv

data/address/%.tsv: bin/addresses cache/AddressBase/%.zip
	@mkdir -p data/address data/address-postcode log/address
	unzip -p $(patsubst data/address/%.tsv,cache/AddressBase/%,$(@)).zip | \
		bin/addresses 3> $@ \
			      4> $(patsubst data/address/%.tsv,log/address/%,$(@)).tsv \
			      5> $(patsubst data/address/%.tsv,data/address-postcode/%,$(@)).tsv


#
#  Go
#
bin:	$(BINS)

bin/streets:	src/streets.go
	go build -o $@ src/streets.go

bin/addresses:	src/addresses.go
	go build -o $@ src/addresses.go

go-get:
	go get github.com/richardlehane/crock32


#
#  phony
#
init::	go-get

download:	etc/headers cache/download.html $(ADDRESSBASE_ZIPS)

clean::
	rm -rf $(BINS) log

prune: clean
	rm -rf cache data/street data/address data/address-postcode
