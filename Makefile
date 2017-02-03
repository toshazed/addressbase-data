#
#  process AddressBase
#
.PHONY: init bin all data meta maps stats clean prune
.SECONDARY:
C=,

all:	data meta maps


#
#  AddressBase comes as 10,964 files, one per-OS grid
#
include makefiles/grids.mk

ADDRESSBASE_ZIPS=$(GRIDS:%=cache/AddressBase/%.zip)

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
#  extract a TSV for each grid ZIP file ..
#
cache/grid/street/%.tsv: bin/streets cache/AddressBase/%.zip
	@mkdir -p cache/grid/street log/street
	unzip -p $(patsubst cache/grid/street/%.tsv,cache/AddressBase/%,$(@)).zip | \
		bin/streets 3> $@ \
			    4> $(patsubst cache/grid/street/%.tsv,log/street/%,$(@)).tsv

cache/grid/address/%.tsv: bin/addresses cache/AddressBase/%.zip
	@mkdir -p cache/grid/address cache/grid/address-postcode log/address
	unzip -p $(patsubst cache/grid/address/%.tsv,cache/AddressBase/%,$(@)).zip | \
		bin/addresses 3> $@ \
			      4> $(patsubst cache/grid/address/%.tsv,log/address/%,$(@)).tsv


#
#  create a TSV file for each street-custodian
#
include makefiles/custodians.mk

GRID_STREETS=$(GRIDS:%=cache/grid/street/%.tsv)
GRID_ADDRESSES=$(GRIDS:%=cache/grid/address/%.tsv)

CACHE_STREETS=$(CUSTODIANS:%=cache/street/%.tsv)
CACHE_ADDRESSES=$(CUSTODIANS:%=cache/address/%.tsv)

$(CACHE_STREETS):	cache/street/.touched
$(CACHE_ADDRESSES):	cache/address/.touched

cache/street/.touched:	bin/tsvcat.sh bin/tsvsplit $(GRID_STREETS)
	mkdir -p cache/street
	bin/tsvcat.sh cache/grid/street | cut -d'	' -f2- | bin/tsvsplit cache/street/ .tsv street-custodian
	touch $@

cache/address/.touched:	bin/tsvcat.sh bin/tsvsplit $(GRID_ADDRESSES)
	mkdir -p cache/address
	bin/tsvcat.sh cache/grid/address | cut -d'	' -f2- | bin/tsvsplit cache/address/ .tsv street-custodian
	touch $@


#
#  map to register-shaped TSV data from per-custodian files
#
data:	streets addresses

DATA_STREETS=$(CUSTODIANS:%=data/street/%.tsv)
DATA_ADDRESSES=$(CUSTODIANS:%=data/address/%.tsv)

streets:	$(DATA_STREETS)
addresses:	$(DATA_ADDRESSES)

# map place names
data/street/%.tsv:	bin/street-place.py cache/street/%.tsv
	@mkdir -p data/street log/street-place
	bin/street-place.py \
			$(patsubst data/street/%,maps/place/%,$(@)) \
			3> $(patsubst data/street/%,log/street-place/%,$(@)) \
			< $(patsubst data/street/%,cache/street/%,$(@)) > $@

# TBD: collapsing this step into the grid reduce will save disk space
data/address/%.tsv:	cache/address/%.tsv
	@mkdir -p data/address
	cut -d'	' -f1-9 < $< > $@



#
#  maps, data used to map street locations to place-data
#
MAPS=\
	maps/street-custodian-bbox.tsv

maps:	$(MAPS)

#
#  bounding-box for each custodian
#
maps/street-custodian-bbox.tsv:	bin/tsvcat.sh bin/street-custodian-bbox.py $(GRID_ADDRESSES)
	@mkdir -p maps
	bin/tsvcat.sh data/address | bin/street-custodian-bbox.py > $@


#
#  AddressBase metadata
#
meta: delivery-addresses

GRID_DELIVERY_ADDRESSES=$(GRIDS:%=cache/grid/delivery-address/%.tsv)

delivery-addresses:	bin/delivery-addresses $(GRID_DELIVERY_ADDRESSES)

cache/grid/delivery-address/%.tsv: bin/delivery-addresses cache/AddressBase/%.zip
	@mkdir -p cache/grid/delivery-address
	unzip -p $(patsubst cache/grid/delivery-address/%.tsv,cache/AddressBase/%,$(@)).zip | \
		bin/delivery-addresses > $@



#
#  Go
#
BINS=\
	bin/addresses\
	bin/streets\
	bin/delivery-addresses\
	bin/tsvsplit\
	bin/tsvcount

bin:	$(BINS)

bin/%: src/%.go
	go build -o $@ $<


#
#  phony
#
init::

download:	etc/headers cache/download.html $(ADDRESSBASE_ZIPS)

clean::
	rm -rf $(BINS) $(STATS) log

prune: clean
	rm -rf cache data/street data/address stats
