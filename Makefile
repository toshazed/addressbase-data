#
#  process AddressBase
#
.PHONY: init bin all data stats clean prune
.SECONDARY:
C=,

BINS=\
	bin/streets\
	bin/addresses\
	bin/tsvcount

all:	data stats

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
#  stats
#
STATS_STREET=\
	stats/street/name.tsv \
	stats/street/name-cy.tsv \
	stats/street/locality.tsv \
	stats/street/town.tsv \
	stats/street/administrative-area.tsv \
	stats/street/street-custodian,street.tsv \
	stats/street/street-custodian,name.tsv \
	stats/street/street-custodian,name-cy.tsv \
	stats/street/street-custodian,locality.tsv \
	stats/street/street-custodian,town.tsv \
	stats/street/street-custodian,administrative-area.tsv \

STATS_STREET_CUSTODIAN=\
	stats/street/street-custodian/street.tsv \
	stats/street/street-custodian/name.tsv \
	stats/street/street-custodian/name-cy.tsv \
	stats/street/street-custodian/locality.tsv \
	stats/street/street-custodian/town.tsv \
	stats/street/street-custodian/administrative-area.tsv

STATS_ADDRESS=\
	stats/address/name.tsv \
	stats/address/name-cy.tsv \
	stats/address/street-custodian,address.tsv \
	stats/address/street-custodian,name.tsv \
	stats/address/street-custodian,name-cy.tsv

STATS_ADDRESS_CUSTODIAN=\
	stats/address/street-custodian/address.tsv \
	stats/address/street-custodian/name.tsv \
	stats/address/street-custodian/name-cy.tsv

STATS=\
	$(STATS_STREET)\
	$(STATS_ADDRESS)\
	$(STATS_STREET_CUSTODIAN)\
	$(STATS_ADDRESS_CUSTODIAN)

stats:	$(STATS)

stats/street/street-custodian/%.tsv: bin/tsvcount stats/street/street-custodian,%.tsv
	@mkdir -p stats/street/street-custodian
	bin/tsvcount 'street-custodian' < $(subst street-custodian/,street-custodian$C,$(@)) > $@

stats/street/%.tsv: bin/tsvcount $(GRID_STREETS)
	@mkdir -p stats/street
	bin/tsvcat.sh data/street | bin/tsvcount '$(subst .tsv,,$(subst stats/street/,,$(@)))' > $@

stats/address/street-custodian/%.tsv: bin/tsvcount stats/address/street-custodian,%.tsv
	@mkdir -p stats/address/street-custodian
	bin/tsvcount 'street-custodian' < $(subst street-custodian/,street-custodian$C,$(@)) > $@

stats/address/%.tsv: bin/tsvcount $(GRID_ADDRESS)
	@mkdir -p stats/address
	bin/tsvcat.sh data/address | bin/tsvcount '$(subst .tsv,,$(subst stats/address/,,$(@)))' > $@


#
#  Go
#
bin:	$(BINS)

bin/streets:	src/streets.go
	go build -o $@ src/streets.go

bin/addresses:	src/addresses.go
	go build -o $@ src/addresses.go

bin/tsvcount:	src/tsvcount.go
	go build -o $@ src/tsvcount.go

go-get:
	go get github.com/richardlehane/crock32


#
#  phony
#
init::	go-get

download:	etc/headers cache/download.html $(ADDRESSBASE_ZIPS)

clean::
	rm -rf $(BINS) $(STATS) log

prune: clean
	rm -rf cache data/street data/address data/address-postcode stats
