#
#  process AddressBase
#
.PHONY: init bin all data stats clean prune
.SECONDARY:
C=,

BINS=\
	bin/streets\
	bin/addresses\
	bin/delivery-addresses\
	bin/tsvcount

all:	data stats maps

data:	streets addresses

#
#  AddressBase comes as 10,964 grid files, enumerated here
#
include makefiles/grids.mk

ADDRESSBASE_ZIPS=$(GRIDS:%=cache/AddressBase/%.zip)

GRID_STREETS=$(GRIDS:%=data/street/%.tsv)
GRID_ADDRESSES=$(GRIDS:%=data/address/%.tsv)
GRID_DELIVERY_ADDRESSES=$(GRIDS:%=data/delivery-address/%.tsv)
STREET_CUSTODIAN_BBOXES=maps/street-custodian-bbox.tsv

streets:	bin/streets $(GRID_STREETS)
addresses:	bin/addresses $(GRID_ADDRESSES)
delivery-addresses:	bin/delivery-addresses $(GRID_DELIVERY_ADDRESSES)


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
	@mkdir -p data/street data/locality log/street
	unzip -p $(patsubst data/street/%.tsv,cache/AddressBase/%,$(@)).zip | \
		bin/streets 3> $@ \
			    4> $(patsubst data/street/%.tsv,log/street/%,$(@)).tsv \
			    5> $(patsubst data/street/%.tsv,data/locality/%,$(@)).tsv

data/address/%.tsv: bin/addresses cache/AddressBase/%.zip
	@mkdir -p data/address data/address-postcode log/address
	unzip -p $(patsubst data/address/%.tsv,cache/AddressBase/%,$(@)).zip | \
		bin/addresses 3> $@ \
			      4> $(patsubst data/address/%.tsv,log/address/%,$(@)).tsv \
			      5> $(patsubst data/address/%.tsv,data/address-postcode/%,$(@)).tsv

data/delivery-address/%.tsv: bin/delivery-addresses cache/AddressBase/%.zip
	@mkdir -p data/delivery-address
	unzip -p $(patsubst data/delivery-address/%.tsv,cache/AddressBase/%,$(@)).zip | \
		bin/delivery-addresses > $@

#
#  stats
#
STATS_STREET=\
	stats/street/name.tsv \
	stats/street/name-cy.tsv \
	stats/street/street-custodian,street.tsv \
	stats/street/street-custodian,name.tsv \
	stats/street/street-custodian,name-cy.tsv

STATS_STREET_CUSTODIAN=\
	stats/street/street-custodian/street.tsv \
	stats/street/street-custodian/name.tsv \
	stats/street/street-custodian/name-cy.tsv

STATS_ADDRESS=\
	stats/address/name.tsv \
	stats/address/name-cy.tsv \
	stats/address/street.tsv \
	stats/address/street-custodian,address.tsv \
	stats/address/street-custodian,street.tsv \
	stats/address/street-custodian,name.tsv \
	stats/address/street-custodian,name-cy.tsv

STATS_ADDRESS_CUSTODIAN=\
	stats/address/street-custodian/address.tsv \
	stats/address/street-custodian/street.tsv \
	stats/address/street-custodian/name.tsv \
	stats/address/street-custodian/name-cy.tsv

STATS_LOCALITY=\
	stats/locality/locality.tsv \
	stats/locality/town.tsv \
	stats/locality/administrative-area.tsv \
	stats/locality/street-custodian,locality.tsv \
	stats/locality/street-custodian,town.tsv \
	stats/locality/street-custodian,administrative-area.tsv

STATS_LOCALITY_CUSTODIAN=\
	stats/locality/street-custodian/locality.tsv \
	stats/locality/street-custodian/town.tsv \
	stats/locality/street-custodian/administrative-area.tsv

STATS=\
	$(STATS_ADDRESS_CUSTODIAN) \
	$(STATS_STREET_CUSTODIAN) \
	$(STATS_LOCALITY_CUSTODIAN) \
	$(STATS_STREET) \
	$(STATS_ADDRESS) \
	$(STATS_LOCALITY)

stats:	$(STATS)

stats/street/street-custodian/%.tsv: bin/tsvcount stats/street/street-custodian,%.tsv
	@mkdir -p stats/street/street-custodian
	bin/tsvcount 'street-custodian' < $(subst street-custodian/,street-custodian$C,$(@)) > $@

stats/address/street-custodian/%.tsv: bin/tsvcount stats/address/street-custodian,%.tsv
	@mkdir -p stats/address/street-custodian
	bin/tsvcount 'street-custodian' < $(subst street-custodian/,street-custodian$C,$(@)) > $@

stats/locality/street-custodian/%.tsv: bin/tsvcount stats/locality/street-custodian,%.tsv
	@mkdir -p stats/locality/street-custodian
	bin/tsvcount 'street-custodian' < $(subst street-custodian/,street-custodian$C,$(@)) > $@


stats/street/%.tsv: bin/tsvcount $(GRID_STREETS)
	@mkdir -p stats/street
	bin/tsvcat.sh data/street | bin/tsvcount '$(subst .tsv,,$(subst stats/street/,,$(@)))' > $@

stats/address/%.tsv: bin/tsvcount $(GRID_ADDRESS)
	@mkdir -p stats/address
	bin/tsvcat.sh data/address | bin/tsvcount '$(subst .tsv,,$(subst stats/address/,,$(@)))' > $@

stats/locality/%.tsv: bin/tsvcount $(GRID_STREETS)
	@mkdir -p stats/locality
	bin/tsvcat.sh data/locality | bin/tsvcount '$(subst .tsv,,$(subst stats/locality/,,$(@)))' > $@




#
#  generated maps
#
MAPS=\
	maps/street-custodian-bbox.tsv

maps/street-custodian-bbox.tsv:	bin/tsvcat.sh bin/street-custodian-bbox.py $(GRID_ADDRESSES)
	@mkdir -p maps
	bin/tsvcat.sh data/address | bin/street-custodian-bbox.py > $@

maps:	$(MAPS)

#
#  Go
#
bin:	$(BINS)

bin/streets:	src/streets.go
	go build -o $@ src/streets.go

bin/addresses:	src/addresses.go
	go build -o $@ src/addresses.go

bin/delivery-addresses:	src/delivery-addresses.go
	go build -o $@ src/delivery-addresses.go

bin/tsvcount:	src/tsvcount.go
	go build -o $@ src/tsvcount.go


#
#  phony
#
init::

download:	etc/headers cache/download.html $(ADDRESSBASE_ZIPS)

clean::
	rm -rf $(BINS) $(STATS) log

prune: clean
	rm -rf cache data/street data/address data/address-postcode data/delivery-address stats
