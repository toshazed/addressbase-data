#
#  Counts and other statistics
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
